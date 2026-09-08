import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_mvvm_riverpod/core/environment/env.dart';
import 'package:flutter_mvvm_riverpod/core/routing/router.dart';
import 'package:flutter_mvvm_riverpod/core/routing/routes.dart';
import 'package:flutter_mvvm_riverpod/features/common/remote/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_mvvm_riverpod/features/safety/model/safety_check_in.dart';
import 'package:flutter_mvvm_riverpod/features/safety/repository/safety_check_in_repository.dart';
import 'package:flutter_mvvm_riverpod/features/safety/repository/safety_check_in_configuration_repository.dart';
import 'package:flutter_mvvm_riverpod/features/safety/ui/widgets/safety_check_in_prompt.dart';

import '../../firebase_options.dart';

const _checkInAction = 'safety_check_in_safe';
const _localCheckInNotificationId = 74001;
const _localCheckInChannelId = 'gobuddy_safety_check_in_alarm_v3';

@pragma('vm:entry-point')
Future<void> notificationTapBackground(NotificationResponse response) async {
  await PushNotificationService.handleNotificationResponse(response);
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushNotificationService {
  PushNotificationService._();

  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static StreamSubscription<String>? _tokenSubscription;
  static StreamSubscription<AuthState>? _authSubscription;
  static bool _initialized = false;

  static bool get _isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<void> initialize() async {
    if (_initialized || !_isSupported) return;
    _initialized = true;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final iosSettings = DarwinInitializationSettings(
      notificationCategories: [
        DarwinNotificationCategory(
          'safety_check_in',
          actions: [DarwinNotificationAction.plain(_checkInAction, "I'm safe")],
        ),
      ],
    );
    await _localNotifications.initialize(
      settings: InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    final launchDetails = await _localNotifications
        .getNotificationAppLaunchDetails();
    final launchResponse = launchDetails?.notificationResponse;
    if (launchDetails?.didNotificationLaunchApp == true &&
        launchResponse != null) {
      Future<void>.delayed(
        const Duration(milliseconds: 500),
        () => handleNotificationResponse(launchResponse),
      );
    }

    const channel = AndroidNotificationChannel(
      'gobuddy_updates',
      'GoBuddy updates',
      description: 'Join requests and collaboration updates',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
    const messageChannel = AndroidNotificationChannel(
      'gobuddy_messages',
      'Group messages',
      description: 'New messages from your GoBuddy trip groups',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(messageChannel);
    const safetyChannel = AndroidNotificationChannel(
      'gobuddy_safety_check_ins',
      'Safety check-ins',
      description: 'Time-sensitive prompts asking you to confirm you are safe',
      importance: Importance.max,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(safetyChannel);
    const callChannel = AndroidNotificationChannel(
      'gobuddy_incoming_calls',
      'Incoming group calls',
      description: 'Ringing alerts for GoBuddy voice and video calls',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(callChannel);

    // Ask once during app startup because notifications are also used by
    // non-safety features. The operating system will not display the prompt
    // again when permission has already been decided.
    await requestNotificationPermission();

    final savedConfiguration =
        await SharedPreferencesSafetyCheckInConfigurationRepository().load();
    await scheduleSafetyCheckIns(
      savedConfiguration,
      requestAlarmPermissions: false,
    );

    if (!Env.hasSupabase) return;

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_openRemoteMessage);
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      Future<void>.delayed(
        const Duration(milliseconds: 500),
        () => _openRemoteMessage(initialMessage),
      );
    }

    _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
      _registerToken,
    );
    _authSubscription = supabase.auth.onAuthStateChange.listen((event) {
      if (event.session != null) unawaited(_registerCurrentToken());
    });
    await _registerCurrentToken();
  }

  static Future<bool> requestNotificationPermission() async {
    if (!_isSupported) return false;

    if (Platform.isAndroid) {
      return await _localNotifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          true;
    }

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  static Future<bool> scheduleSafetyCheckIns(
    SafetyCheckInConfiguration configuration, {
    bool requestAlarmPermissions = true,
  }) async {
    if (!_isSupported) return false;
    if (!_initialized) await initialize();

    await _localNotifications.cancel(id: _localCheckInNotificationId);
    if (!configuration.enabled) return true;

    if (requestAlarmPermissions && !await requestNotificationPermission()) {
      return false;
    }

    var scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
    if (Platform.isAndroid) {
      final android = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (requestAlarmPermissions) {
        await android?.requestExactAlarmsPermission();
        await android?.requestFullScreenIntentPermission();
      }
      if (await android?.canScheduleExactNotifications() == true) {
        scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
      }
    }

    await _localNotifications.periodicallyShowWithDuration(
      id: _localCheckInNotificationId,
      title: 'Safety check-in',
      body: 'Are you safe? Tap to confirm your safety.',
      repeatDurationInterval: Duration(minutes: configuration.intervalMinutes),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _localCheckInChannelId,
          'Safety check-in alarms',
          channelDescription:
              'Recurring alarm-style reminders asking you to confirm you are safe',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          autoCancel: false,
          ongoing: true,
          playSound: true,
          enableVibration: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          // Android's alarm-clock behaviour: keep replaying the channel sound
          // until the notification is explicitly acknowledged.
          additionalFlags: Int32List.fromList(const [4]),
          visibility: NotificationVisibility.public,
          actions: [
            AndroidNotificationAction(
              _checkInAction,
              "I'm safe",
              showsUserInterface: false,
              // Let Android dismiss only the currently displayed alarm. Do
              // not call the plugin's cancel API here because that also
              // removes the stored periodic schedule.
              cancelNotification: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          categoryIdentifier: 'safety_check_in',
          presentAlert: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: scheduleMode,
      payload: jsonEncode({
        'type': 'safety_check_in',
        'local': true,
        'notification_id': _localCheckInNotificationId,
      }),
    );
    return true;
  }

  static Future<void> _registerCurrentToken() async {
    if (supabase.auth.currentUser == null) return;
    if (Platform.isIOS &&
        await FirebaseMessaging.instance.getAPNSToken() == null) {
      Future<void>.delayed(const Duration(seconds: 2), _registerCurrentToken);
      return;
    }
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _registerToken(token);
  }

  static Future<void> _registerToken(String token) async {
    if (supabase.auth.currentUser == null) return;
    await supabase.rpc(
      'register_push_device',
      params: {
        'p_token': token,
        'p_platform': Platform.isIOS ? 'ios' : 'android',
      },
    );
  }

  static Future<void> unregisterCurrentDevice() async {
    if (!_isSupported || supabase.auth.currentUser == null) return;
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await supabase.rpc('unregister_push_device', params: {'p_token': token});
    }
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (message.data['type'] == 'safety_check_in') {
      final notificationId = await _showCheckInNotification(message);
      _openCheckIn(
        message.data['check_in_id'] as String?,
        message.data['trip_id'] as String?,
        notificationId: notificationId,
      );
      return;
    }
    if (message.data['type'] == 'incoming_call') {
      await _showIncomingCallNotification(message);
      return;
    }
    final notification = message.notification;
    if (notification == null) return;
    final isGroupMessage = message.data['type'] == 'group_message';
    await _localNotifications.show(
      id: message.messageId.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          isGroupMessage ? 'gobuddy_messages' : 'gobuddy_updates',
          isGroupMessage ? 'Group messages' : 'GoBuddy updates',
          channelDescription: isGroupMessage
              ? 'New messages from your GoBuddy trip groups'
              : 'Join requests and collaboration updates',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data['type'] == 'identity_verification'
          ? jsonEncode({'type': 'identity_verification'})
          : message.data['trip_id'] as String?,
    );
  }

  static Future<void> _showIncomingCallNotification(
    RemoteMessage message,
  ) async {
    await _localNotifications.show(
      id: message.messageId.hashCode,
      title: message.notification?.title ?? 'Incoming GoBuddy group call',
      body: message.notification?.body ?? 'A trip member is calling.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'gobuddy_incoming_calls',
          'Incoming group calls',
          channelDescription: 'Ringing alerts for voice and video calls',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.call,
          fullScreenIntent: true,
          playSound: true,
          enableVibration: true,
          audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
          visibility: NotificationVisibility.public,
          timeoutAfter: 30000,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      payload: jsonEncode({
        'type': 'incoming_call',
        'trip_id': message.data['trip_id'],
        'call_id': message.data['call_id'],
        'call_type': message.data['call_type'],
      }),
    );
  }

  static Future<int> _showCheckInNotification(RemoteMessage message) async {
    final notificationId = message.messageId.hashCode;
    await _localNotifications.show(
      id: notificationId,
      title: message.notification?.title ?? 'Safety check-in',
      body:
          message.notification?.body ??
          'Are you safe? Please respond within 15 minutes.',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'gobuddy_safety_check_ins',
          'Safety check-ins',
          channelDescription:
              'Time-sensitive prompts asking you to confirm you are safe',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          autoCancel: false,
          ongoing: true,
          playSound: true,
          enableVibration: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          additionalFlags: Int32List.fromList(const [4]),
          actions: [
            AndroidNotificationAction(
              _checkInAction,
              "I'm safe",
              showsUserInterface: false,
              cancelNotification: false,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          categoryIdentifier: 'safety_check_in',
          presentAlert: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      payload: jsonEncode({
        'type': 'safety_check_in',
        'check_in_id': message.data['check_in_id'],
        'trip_id': message.data['trip_id'],
        'notification_id': notificationId,
      }),
    );
    return notificationId;
  }

  static Future<void> handleNotificationResponse(
    NotificationResponse response,
  ) async {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    Map<String, dynamic>? data;
    try {
      data = Map<String, dynamic>.from(jsonDecode(payload) as Map);
    } catch (_) {
      _openTrip(payload);
      return;
    }
    if (data['type'] == 'identity_verification') {
      router.push(Routes.identityVerification);
      return;
    }
    if (data['type'] == 'incoming_call') {
      _openTrip(data['trip_id'] as String?);
      return;
    }
    if (data['type'] != 'safety_check_in') return;
    final checkInId = data['check_in_id'] as String?;
    final isLocal = data['local'] == true;
    final notificationId = data['notification_id'] as int? ?? response.id;
    if (response.actionId == _checkInAction && isLocal) {
      // Android's action receiver has already dismissed the visible alarm.
      // The periodic schedule remains registered for every future interval.
      return;
    }
    if (response.actionId == _checkInAction && checkInId != null) {
      try {
        await SupabaseSafetyCheckInRepository(
          supabase,
        ).respond(checkInId, SafetyCheckInStatus.safe);
        await _silenceCheckInAlarm(notificationId);
        return;
      } catch (_) {
        // Open the prompt so the user can retry if the direct action failed.
      }
    }
    _openCheckIn(
      checkInId,
      data['trip_id'] as String?,
      localOnly: isLocal,
      notificationId: notificationId,
    );
  }

  static void _openRemoteMessage(RemoteMessage message) {
    if (message.data['type'] == 'identity_verification') {
      router.push(Routes.identityVerification);
      return;
    }
    if (message.data['type'] == 'safety_check_in') {
      _openCheckIn(
        message.data['check_in_id'] as String?,
        message.data['trip_id'] as String?,
      );
      return;
    }
    if (message.data['type'] == 'incoming_call') {
      _openTrip(message.data['trip_id'] as String?);
      return;
    }
    _openTrip(message.data['trip_id'] as String?);
  }

  static void _openCheckIn(
    String? checkInId,
    String? tripId, {
    bool localOnly = false,
    int? notificationId,
  }) {
    unawaited(
      _openCheckInAfterStartup(
        checkInId,
        tripId,
        localOnly: localOnly,
        notificationId: notificationId,
      ),
    );
  }

  static Future<void> _openCheckInAfterStartup(
    String? checkInId,
    String? tripId, {
    required bool localOnly,
    required int? notificationId,
  }) async {
    // A cold notification launch initially builds the splash route. Showing a
    // dialog on that route makes it disappear when the splash timer navigates
    // to the real destination. Wait until startup navigation has settled.
    while (router.routeInformationProvider.value.uri.path == Routes.splash) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    await showSafetyCheckInPrompt(
      context,
      checkInId: checkInId,
      tripId: tripId,
      createRecord: !localOnly,
      onResponded: () => _silenceCheckInAlarm(
        notificationId,
        rescheduleLocal: localOnly,
      ),
    );
  }

  static Future<void> _silenceCheckInAlarm(
    int? notificationId, {
    bool rescheduleLocal = false,
  }) async {
    if (notificationId != null) {
      await _localNotifications.cancel(id: notificationId);
    }
    // Cancelling the displayed periodic notification may also remove its next
    // occurrence. Start a fresh interval only after the user has responded.
    if (rescheduleLocal) {
      final configuration =
          await SharedPreferencesSafetyCheckInConfigurationRepository().load();
      if (configuration.enabled) {
        await scheduleSafetyCheckIns(
          configuration,
          requestAlarmPermissions: false,
        );
      }
    }
  }

  static void _openTrip(String? tripId) {
    if (tripId == null || tripId.isEmpty) return;
    router.go(Routes.tripMessages(tripId));
  }

  static Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    await _authSubscription?.cancel();
  }
}
