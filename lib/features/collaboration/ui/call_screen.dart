import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_mvvm_riverpod/core/permissions/app_permission_service.dart';
import 'package:flutter_mvvm_riverpod/features/collaboration/model/collaboration_models.dart';
import 'package:flutter_mvvm_riverpod/features/collaboration/repository/webrtc_call_signaling_repository.dart';

enum CallEndReason { completed, cancelled, missed }

class CallEndDetails {
  const CallEndDetails({
    required this.reason,
    required this.duration,
    required this.hadVideo,
  });

  final CallEndReason reason;
  final Duration duration;
  final bool hadVideo;
}

class CallScreen extends StatefulWidget {
  const CallScreen({
    required this.tripId,
    required this.call,
    required this.currentUserId,
    required this.displayName,
    this.onCallEnded,
    this.onVideoEnabled,
    this.onClose,
    super.key,
  });

  final String tripId;
  final TripCall call;
  final String currentUserId;
  final String displayName;
  final Future<void> Function(CallEndDetails details)? onCallEnded;
  final Future<void> Function()? onVideoEnabled;
  final VoidCallback? onClose;

  bool get isVideo => call.isVideo;
  bool get isInitiator => call.initiatedBy == currentUserId;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  static const _signaling = WebRtcCallSignalingRepository();
  static const _turnUrl = String.fromEnvironment('WEBRTC_TURN_URL');
  static const _turnUsername = String.fromEnvironment('WEBRTC_TURN_USERNAME');
  static const _turnCredential = String.fromEnvironment(
    'WEBRTC_TURN_CREDENTIAL',
  );

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final Map<String, _GroupPeer> _peers = {};
  final Map<String, Future<_GroupPeer>> _creatingPeers = {};
  final Map<String, TripCallParticipant> _participants = {};
  final Set<String> _processedSignalIds = {};
  Future<void> _signalQueue = Future<void>.value();

  MediaStream? _localStream;
  MediaStream? _cameraCaptureStream;
  RealtimeChannel? _realtimeChannel;
  Timer? _callTimer;
  Timer? _presenceTimer;
  Timer? _statsTimer;
  Timer? _aloneTimer;
  Duration _callDuration = Duration.zero;
  String _status = 'Preparing group call...';
  String? _error;
  bool _micEnabled = true;
  bool _cameraEnabled = false;
  bool _cameraChanging = false;
  bool _wasVideo = false;
  bool _everConnected = false;
  bool _localSpeaking = false;
  bool _pollingStats = false;
  bool _syncingSignals = false;
  bool _ending = false;
  bool _participantLeft = false;
  bool _minimized = false;
  Offset? _floatingOffset;
  bool _disposed = false;
  late final DateTime _joinedAt;
  late DateTime _lastSignalSyncAt;

  Map<String, dynamic> get _iceServers {
    final servers = <Map<String, dynamic>>[
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
        ],
      },
    ];
    if (_turnUrl.isNotEmpty) {
      servers.add({
        'urls': _turnUrl,
        if (_turnUsername.isNotEmpty) 'username': _turnUsername,
        if (_turnCredential.isNotEmpty) 'credential': _turnCredential,
      });
    }
    return {'iceServers': servers, 'sdpSemantics': 'unified-plan'};
  }

  @override
  void initState() {
    super.initState();
    _joinedAt = DateTime.now();
    _lastSignalSyncAt = _joinedAt.subtract(const Duration(seconds: 8));
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      if (_turnUrl.isEmpty) {
        debugPrint(
          '[group_call] turn_server_missing call_id=${widget.call.id} '
          'message=Calls may fail on restrictive carrier or NAT networks',
        );
      }
      await _localRenderer.initialize();
      final localStream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': widget.isVideo
            ? {
                'facingMode': 'user',
                'width': {'ideal': 1280},
                'height': {'ideal': 720},
              }
            : false,
      });
      _localStream = localStream;
      _localRenderer.srcObject = localStream;
      _cameraEnabled = localStream.getVideoTracks().isNotEmpty;
      _wasVideo = _cameraEnabled || widget.call.hadVideo;
      if (!kIsWeb) await Helper.setSpeakerphoneOn(true);

      _realtimeChannel = await _signaling.subscribe(
        callId: widget.call.id,
        onSignal: (signal) => unawaited(_queueSignal(signal)),
        onParticipant: (participant) =>
            unawaited(_handleParticipant(participant)),
        onCallEnded: () => unawaited(_closeEndedCall()),
      );
      await _signaling.joinParticipant(
        callId: widget.call.id,
        displayName: widget.displayName,
        micEnabled: _micEnabled,
        cameraEnabled: _cameraEnabled,
      );
      await _sendSignal(
        type: 'ready',
        payload: {'display_name': widget.displayName},
      );

      await _refreshParticipants();
      await _syncMissedSignals();

      _presenceTimer = Timer.periodic(const Duration(seconds: 12), (_) {
        unawaited(_heartbeatAndRefresh());
      });
      _statsTimer = Timer.periodic(const Duration(milliseconds: 750), (_) {
        unawaited(_pollAudioLevels());
      });
      _updateGroupStatus();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = '$error';
          _status = 'Group call could not connect';
        });
      }
    }
  }

  Future<void> _heartbeatAndRefresh() async {
    if (_disposed || _ending) return;
    try {
      await _signaling.updateParticipantMedia(
        callId: widget.call.id,
        micEnabled: _micEnabled,
        cameraEnabled: _cameraEnabled,
      );
      await _refreshParticipants();
      await _syncMissedSignals();
    } catch (_) {
      if (mounted) setState(() => _status = 'Reconnecting...');
    }
  }

  Future<void> _refreshParticipants() async {
    final active = await _signaling.loadParticipants(callId: widget.call.id);
    debugPrint(
      '[group_call] room_joined_members call_id=${widget.call.id} '
      'local_id=${widget.currentUserId} members='
      '${active.map((participant) => participant.userId).join(',')}',
    );
    final activeIds = active.map((participant) => participant.userId).toSet();
    for (final participant in active) {
      await _handleParticipant(participant);
    }
    final staleIds = _participants.keys
        .where(
          (userId) =>
              userId != widget.currentUserId && !activeIds.contains(userId),
        )
        .toList(growable: false);
    for (final userId in staleIds) {
      _participants.remove(userId);
      await _removePeer(userId);
    }
    _updateGroupStatus();
  }

  Future<void> _syncMissedSignals() async {
    if (_syncingSignals || _disposed) return;
    _syncingSignals = true;
    try {
      final signals = await _signaling.loadSignals(
        callId: widget.call.id,
        since: _lastSignalSyncAt.subtract(const Duration(seconds: 1)),
      );
      for (final signal in signals) {
        if (signal.createdAt.isAfter(_lastSignalSyncAt)) {
          _lastSignalSyncAt = signal.createdAt;
        }
        await _queueSignal(signal);
      }
    } finally {
      _syncingSignals = false;
    }
  }

  Future<void> _handleParticipant(TripCallParticipant participant) async {
    if (_disposed) return;
    _participants[participant.userId] = participant;
    if (participant.userId == widget.currentUserId) {
      if (mounted) setState(() {});
      return;
    }
    if (!participant.isActive) {
      await _removePeer(participant.userId);
      _updateGroupStatus();
      return;
    }

    final isNew =
        !_peers.containsKey(participant.userId) &&
        !_creatingPeers.containsKey(participant.userId);
    final peer = await _ensurePeer(participant.userId, participant.displayName);
    peer
      ..displayName = participant.displayName
      ..micEnabled = participant.micEnabled
      ..cameraEnabled = participant.cameraEnabled;
    _wasVideo = _wasVideo || participant.cameraEnabled;
    if (isNew && _shouldCreateOffer(participant.userId)) {
      await _createAndSendOffer(peer);
    }
    _updateGroupStatus();
  }

  bool _shouldCreateOffer(String remoteUserId) =>
      widget.currentUserId.compareTo(remoteUserId) < 0;

  Future<_GroupPeer> _ensurePeer(
    String remoteUserId,
    String displayName,
  ) async {
    final existing = _peers[remoteUserId];
    if (existing != null) return existing;
    final creating = _creatingPeers[remoteUserId];
    if (creating != null) return creating;

    final future = _createPeer(remoteUserId, displayName);
    _creatingPeers[remoteUserId] = future;
    try {
      return await future;
    } finally {
      _creatingPeers.remove(remoteUserId);
    }
  }

  Future<_GroupPeer> _createPeer(
    String remoteUserId,
    String displayName,
  ) async {
    final renderer = RTCVideoRenderer();
    await renderer.initialize();
    final connection = await createPeerConnection(_iceServers);
    final peer = _GroupPeer(
      userId: remoteUserId,
      displayName: displayName,
      connection: connection,
      renderer: renderer,
    );
    _peers[remoteUserId] = peer;

    connection.onIceCandidate = (candidate) {
      if (candidate.candidate == null || _disposed) return;
      unawaited(
        _sendSignal(
          type: 'candidate',
          targetId: remoteUserId,
          payload: {
            'candidate': candidate.candidate,
            'sdp_mid': candidate.sdpMid,
            'sdp_mline_index': candidate.sdpMLineIndex,
          },
        ),
      );
    };
    connection.onTrack = (event) {
      if (event.streams.isEmpty || _disposed) return;
      debugPrint(
        '[group_call] track_received call_id=${widget.call.id} '
        'remote_id=$remoteUserId kind=${event.track.kind} '
        'track_id=${event.track.id}',
      );
      peer.remoteStream = event.streams.first;
      peer.renderer.srcObject = event.streams.first;
      if (event.track.kind == 'video') {
        peer.cameraEnabled = true;
        _wasVideo = true;
      }
      if (mounted) setState(() {});
    };
    connection.onRemoveTrack = (_, track) {
      if (track.kind == 'video') peer.cameraEnabled = false;
      if (mounted) setState(() {});
    };
    connection.onConnectionState = (state) =>
        _handlePeerConnectionState(peer, state);

    final localStream = _localStream;
    if (localStream != null) {
      for (final track in localStream.getTracks()) {
        await connection.addTrack(track, localStream);
      }
    }
    if (mounted) setState(() {});
    return peer;
  }

  void _handlePeerConnectionState(
    _GroupPeer peer,
    RTCPeerConnectionState state,
  ) {
    if (_disposed) return;
    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        peer.connected = true;
        peer.disconnectTimer?.cancel();
        _everConnected = true;
        debugPrint(
          '[group_call] peer_connected call_id=${widget.call.id} '
          'local_id=${widget.currentUserId} remote_id=${peer.userId} '
          'peer_count=${_peers.length}',
        );
        _callTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) {
            setState(() => _callDuration += const Duration(seconds: 1));
          }
        });
      case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
        peer.disconnectTimer?.cancel();
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        peer.connected = false;
        peer.disconnectTimer?.cancel();
        peer.disconnectTimer = Timer(const Duration(seconds: 12), () {
          unawaited(_removePeer(peer.userId, keepParticipant: true));
        });
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        peer.connected = false;
        unawaited(_removePeer(peer.userId, keepParticipant: true));
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        peer.connected = false;
      case RTCPeerConnectionState.RTCPeerConnectionStateNew:
        break;
    }
    _updateGroupStatus();
  }

  Future<void> _handleSignal(TripCallSignal signal) async {
    if (_disposed ||
        signal.senderId == widget.currentUserId ||
        !_processedSignalIds.add(signal.id) ||
        (signal.targetId != null && signal.targetId != widget.currentUserId)) {
      return;
    }
    final participant = _participants[signal.senderId];
    final peer = await _ensurePeer(
      signal.senderId,
      (signal.payload['display_name'] as String?) ??
          participant?.displayName ??
          'Trip member',
    );

    switch (signal.type) {
      case 'ready':
        if (_shouldCreateOffer(signal.senderId)) {
          await _createAndSendOffer(peer);
        }
      case 'offer':
        await peer.connection.setRemoteDescription(
          RTCSessionDescription(
            signal.payload['sdp'] as String?,
            signal.payload['sdp_type'] as String?,
          ),
        );
        peer.remoteDescriptionSet = true;
        await _drainPendingCandidates(peer);
        final answer = await peer.connection.createAnswer();
        await peer.connection.setLocalDescription(answer);
        await _sendSignal(
          type: 'answer',
          targetId: signal.senderId,
          payload: {
            'sdp': answer.sdp,
            'sdp_type': answer.type,
            'display_name': widget.displayName,
          },
        );
      case 'answer':
        await peer.connection.setRemoteDescription(
          RTCSessionDescription(
            signal.payload['sdp'] as String?,
            signal.payload['sdp_type'] as String?,
          ),
        );
        peer.remoteDescriptionSet = true;
        await _drainPendingCandidates(peer);
        if (peer.needsNegotiation) {
          peer.needsNegotiation = false;
          await _createAndSendOffer(peer);
        }
      case 'candidate':
        final candidate = RTCIceCandidate(
          signal.payload['candidate'] as String?,
          signal.payload['sdp_mid'] as String?,
          signal.payload['sdp_mline_index'] as int?,
        );
        if (peer.remoteDescriptionSet) {
          await peer.connection.addCandidate(candidate);
        } else {
          peer.pendingCandidates.add(candidate);
        }
      case 'media_mode':
        peer.cameraEnabled = signal.payload['video_enabled'] == true;
        peer.micEnabled =
            signal.payload['mic_enabled'] as bool? ?? peer.micEnabled;
        _wasVideo = _wasVideo || peer.cameraEnabled;
      case 'renegotiate':
        if (_shouldCreateOffer(signal.senderId)) {
          await _createAndSendOffer(peer);
        }
      case 'hangup':
        await _removePeer(signal.senderId);
    }
    if (mounted) setState(() {});
  }

  Future<void> _queueSignal(TripCallSignal signal) {
    _signalQueue = _signalQueue.then((_) => _handleSignal(signal)).onError((
      error,
      stackTrace,
    ) {
      debugPrint(
        '[group_call] signaling_error call_id=${widget.call.id} '
        'sender_id=${signal.senderId} type=${signal.type} error=$error',
      );
    });
    return _signalQueue;
  }

  Future<void> _drainPendingCandidates(_GroupPeer peer) async {
    for (final candidate in peer.pendingCandidates) {
      await peer.connection.addCandidate(candidate);
    }
    peer.pendingCandidates.clear();
  }

  Future<void> _createAndSendOffer(_GroupPeer peer) async {
    if (peer.makingOffer || _disposed) return;
    final signalingState = await peer.connection.getSignalingState();
    if (signalingState != RTCSignalingState.RTCSignalingStateStable) {
      peer.needsNegotiation = true;
      debugPrint(
        '[group_call] negotiation_queued call_id=${widget.call.id} '
        'remote_id=${peer.userId} state=$signalingState',
      );
      return;
    }
    peer.makingOffer = true;
    try {
      // Keep both media sections negotiated even when this peer currently has
      // no camera track. A voice-only participant can then answer a later
      // renegotiation with video without interrupting the audio connection.
      final offer = await peer.connection.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      });
      await peer.connection.setLocalDescription(offer);
      await _sendSignal(
        type: 'offer',
        targetId: peer.userId,
        payload: {
          'sdp': offer.sdp,
          'sdp_type': offer.type,
          'display_name': widget.displayName,
        },
      );
      peer.needsNegotiation = false;
    } finally {
      peer.makingOffer = false;
    }
  }

  Future<void> _requestRenegotiation(_GroupPeer peer) async {
    if (_shouldCreateOffer(peer.userId)) {
      await _createAndSendOffer(peer);
    } else {
      await _sendSignal(
        type: 'renegotiate',
        targetId: peer.userId,
        payload: const {},
      );
    }
  }

  Future<void> _sendSignal({
    required String type,
    required Map<String, dynamic> payload,
    String? targetId,
  }) => _signaling.send(
    callId: widget.call.id,
    tripId: widget.tripId,
    senderId: widget.currentUserId,
    targetId: targetId,
    type: type,
    payload: payload,
  );

  Future<void> _toggleMic() async {
    final enabled = !_micEnabled;
    for (final track
        in _localStream?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = enabled;
    }
    setState(() => _micEnabled = enabled);
    await _publishMediaState();
  }

  Future<void> _toggleCamera() async {
    if (_cameraChanging || _ending) return;
    setState(() => _cameraChanging = true);
    try {
      if (_cameraEnabled) {
        await _disableCamera();
      } else {
        await _enableCamera();
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not change camera: $error');
    } finally {
      if (mounted) setState(() => _cameraChanging = false);
    }
  }

  Future<void> _enableCamera() async {
    await const AppPermissionService().requireCallPermissions(withVideo: true);
    final localStream = _localStream;
    if (localStream == null) return;
    final cameraStream = await navigator.mediaDevices.getUserMedia({
      'audio': false,
      'video': {
        'facingMode': 'user',
        'width': {'ideal': 1280},
        'height': {'ideal': 720},
      },
    });
    final videoTracks = cameraStream.getVideoTracks();
    if (videoTracks.isEmpty) {
      await cameraStream.dispose();
      throw StateError('No camera video was available.');
    }
    final videoTrack = videoTracks.first;
    await localStream.addTrack(videoTrack);
    for (final peer in _peers.values) {
      await peer.connection.addTrack(videoTrack, localStream);
    }
    _cameraCaptureStream = cameraStream;
    _localRenderer.srcObject = localStream;
    _cameraEnabled = true;
    _wasVideo = true;
    try {
      await widget.onVideoEnabled?.call();
    } catch (_) {
      // Media remains active while call metadata catches up through Realtime.
    }
    await _publishMediaState();
    for (final peer in _peers.values) {
      await _requestRenegotiation(peer);
    }
  }

  Future<void> _disableCamera() async {
    final localStream = _localStream;
    if (localStream == null) return;
    final videoTracks = List<MediaStreamTrack>.from(
      localStream.getVideoTracks(),
    );
    for (final peer in _peers.values) {
      final senders = await peer.connection.getSenders();
      for (final track in videoTracks) {
        for (final sender in senders) {
          if (sender.track?.id == track.id) {
            await peer.connection.removeTrack(sender);
          }
        }
      }
    }
    for (final track in videoTracks) {
      await localStream.removeTrack(track);
      await track.stop();
    }
    await _cameraCaptureStream?.dispose();
    _cameraCaptureStream = null;
    _localRenderer.srcObject = localStream;
    _cameraEnabled = false;
    await _publishMediaState();
    for (final peer in _peers.values) {
      await _requestRenegotiation(peer);
    }
  }

  Future<void> _publishMediaState() async {
    await _signaling.updateParticipantMedia(
      callId: widget.call.id,
      micEnabled: _micEnabled,
      cameraEnabled: _cameraEnabled,
    );
    await _sendSignal(
      type: 'media_mode',
      payload: {'video_enabled': _cameraEnabled, 'mic_enabled': _micEnabled},
    );
  }

  Future<void> _pollAudioLevels() async {
    if (_pollingStats || _disposed || _peers.isEmpty) return;
    _pollingStats = true;
    var localSpeaking = false;
    try {
      for (final peer in _peers.values.toList(growable: false)) {
        var remoteSpeaking = false;
        final reports = await peer.connection.getStats();
        for (final report in reports) {
          final values = report.values;
          final kind = (values['kind'] ?? values['mediaType'] ?? '').toString();
          final level = _asDouble(values['audioLevel']);
          if (kind == 'audio' &&
              report.type == 'inbound-rtp' &&
              level != null &&
              level > 0.025) {
            remoteSpeaking = true;
          }
          if (kind == 'audio' &&
              (report.type == 'media-source' ||
                  report.type == 'outbound-rtp') &&
              level != null &&
              level > 0.025) {
            localSpeaking = true;
          }
        }
        peer.isSpeaking = peer.micEnabled && remoteSpeaking;
      }
      _localSpeaking = _micEnabled && localSpeaking;
      if (mounted) setState(() {});
    } catch (_) {
      // Some RTC implementations omit audioLevel; call audio still continues.
    } finally {
      _pollingStats = false;
    }
  }

  void _updateGroupStatus() {
    if (_disposed) return;
    final remoteParticipants = _activeRemoteParticipants;
    final connectedCount = _peers.values.where((peer) => peer.connected).length;
    if (connectedCount > 0) {
      _status = 'Connected';
      _aloneTimer?.cancel();
      _aloneTimer = null;
    } else if (remoteParticipants.isNotEmpty) {
      _status = 'Connecting...';
      _aloneTimer?.cancel();
      _aloneTimer = null;
    } else {
      _status = widget.isInitiator
          ? 'Calling group...'
          : 'Waiting for others...';
      _aloneTimer ??= Timer(const Duration(seconds: 45), () {
        if (!_ending) {
          unawaited(
            _leaveCall(
              reason: _everConnected
                  ? CallEndReason.completed
                  : CallEndReason.missed,
            ),
          );
        }
      });
    }
    if (mounted) setState(() {});
  }

  List<TripCallParticipant> get _activeRemoteParticipants {
    final values =
        _participants.values
            .where(
              (participant) =>
                  participant.userId != widget.currentUserId &&
                  participant.isActive,
            )
            .toList(growable: false)
          ..sort((first, second) => first.joinedAt.compareTo(second.joinedAt));
    return values;
  }

  bool get _showVideoGrid =>
      _cameraEnabled ||
      _activeRemoteParticipants.any(
        (participant) =>
            participant.cameraEnabled ||
            (_peers[participant.userId]?.cameraEnabled ?? false),
      );

  Future<void> _leaveCall({CallEndReason? reason}) async {
    if (_ending) return;
    setState(() => _ending = true);
    final resolvedReason =
        reason ??
        (_everConnected
            ? CallEndReason.completed
            : widget.isInitiator
            ? CallEndReason.cancelled
            : CallEndReason.missed);
    try {
      await widget.onCallEnded?.call(
        CallEndDetails(
          reason: resolvedReason,
          duration: _callDuration,
          hadVideo: _wasVideo,
        ),
      );
      _participantLeft = true;
    } catch (_) {
      try {
        await _signaling.leaveParticipant(callId: widget.call.id);
        _participantLeft = true;
      } catch (_) {
        // Local media must still close when signaling is temporarily offline.
      }
    }
    await _disposeRtc();
    if (mounted) _closeCallUi();
  }

  Future<void> _closeEndedCall() async {
    if (_ending) return;
    setState(() => _ending = true);
    _participantLeft = true;
    await _disposeRtc();
    if (mounted) _closeCallUi();
  }

  void _closeCallUi() {
    final onClose = widget.onClose;
    if (onClose != null) {
      onClose();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _removePeer(
    String userId, {
    bool keepParticipant = false,
  }) async {
    final peer = _peers.remove(userId);
    if (!keepParticipant) _participants.remove(userId);
    if (peer != null) await peer.dispose();
    _updateGroupStatus();
  }

  Future<void> _disposeRtc() async {
    if (_disposed) return;
    _disposed = true;
    _callTimer?.cancel();
    _presenceTimer?.cancel();
    _statsTimer?.cancel();
    _aloneTimer?.cancel();
    if (!_participantLeft) {
      try {
        await _signaling.leaveParticipant(callId: widget.call.id);
      } catch (_) {
        // Best-effort presence cleanup during route/app shutdown.
      }
      _participantLeft = true;
    }
    final channel = _realtimeChannel;
    if (channel != null) await _signaling.removeChannel(channel);
    for (final peer in _peers.values.toList(growable: false)) {
      await peer.dispose();
    }
    _peers.clear();
    for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      await track.stop();
    }
    await _cameraCaptureStream?.dispose();
    await _localStream?.dispose();
    _localRenderer.srcObject = null;
    await _localRenderer.dispose();
  }

  @override
  void dispose() {
    unawaited(_disposeRtc());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_minimized && _showVideoGrid) return _buildFloatingVideo(context);
    final participantCount = _activeRemoteParticipants.length + 1;
    return Positioned.fill(
      child: PopScope(
        canPop: _ending,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) unawaited(_leaveCall());
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF0B0B0F),
          body: SafeArea(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 76, 12, 118),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: _showVideoGrid
                        ? KeyedSubtree(
                            key: const ValueKey('group-video'),
                            child: _buildVideoGrid(),
                          )
                        : KeyedSubtree(
                            key: const ValueKey('group-voice'),
                            child: _buildVoiceGrid(),
                          ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton(
                    onPressed: _ending ? null : _leaveCall,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black38,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    tooltip: 'Leave group call',
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 64,
                  right: 64,
                  child: Column(
                    children: [
                      const Text(
                        'Trip group call',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '$participantCount ${participantCount == 1 ? 'participant' : 'participants'} • ${_callDuration > Duration.zero ? _formatDuration(_callDuration) : _status}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                if (_showVideoGrid)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: _ending
                          ? null
                          : () => setState(() => _minimized = true),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black38,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.picture_in_picture_alt_rounded),
                      tooltip: 'Minimize video call',
                    ),
                  ),
                if (_error != null)
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 102,
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 22,
                  child: _buildCallControls(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingVideo(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    const windowWidth = 220.0;
    const windowHeight = 154.0;
    final fallback = Offset(
      math.max(12.0, screen.width - windowWidth - 16),
      math.max(12.0, screen.height - windowHeight - 104),
    );
    final offset = _floatingOffset ?? fallback;
    final maxX = math.max(12.0, screen.width - windowWidth - 12);
    final maxY = math.max(12.0, screen.height - windowHeight - 12);
    final position = Offset(
      offset.dx.clamp(12.0, maxX).toDouble(),
      offset.dy.clamp(12.0, maxY).toDouble(),
    );
    final participants = _participantViews;
    final focus = participants
        .where(
          (participant) =>
              !participant.isLocal &&
              participant.cameraEnabled &&
              participant.renderer?.srcObject != null,
        )
        .firstOrNull;
    final displayed =
        focus ??
        participants
            .where(
              (participant) =>
                  participant.cameraEnabled &&
                  participant.renderer?.srcObject != null,
            )
            .firstOrNull ??
        participants.first;

    return Positioned(
      left: position.dx,
      top: position.dy,
      width: windowWidth,
      height: windowHeight,
      child: GestureDetector(
        onTap: () => setState(() => _minimized = false),
        onPanUpdate: (details) {
          setState(() {
            _floatingOffset = Offset(
              (position.dx + details.delta.dx).clamp(12.0, maxX).toDouble(),
              (position.dy + details.delta.dy).clamp(12.0, maxY).toDouble(),
            );
          });
        },
        child: Material(
          color: const Color(0xFF17171D),
          elevation: 16,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _VideoParticipantTile(participant: displayed),
              Positioned(
                top: 4,
                right: 4,
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _minimized = false),
                      icon: const Icon(Icons.open_in_full_rounded, size: 18),
                      tooltip: 'Expand call',
                    ),
                    const SizedBox(width: 4),
                    IconButton.filled(
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _ending ? null : _leaveCall,
                      icon: const Icon(Icons.call_end_rounded, size: 18),
                      tooltip: 'Leave call',
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 10,
                bottom: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      _formatDuration(_callDuration),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceGrid() {
    final participants = _participantViews;
    return GridView.builder(
      itemCount: participants.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridColumnCount(participants.length),
        childAspectRatio: 0.92,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (_, index) {
        final participant = participants[index];
        return _VoiceParticipantTile(participant: participant);
      },
    );
  }

  Widget _buildVideoGrid() {
    final participants = _participantViews;
    return GridView.builder(
      itemCount: participants.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridColumnCount(participants.length),
        childAspectRatio: 0.78,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (_, index) {
        final participant = participants[index];
        return _VideoParticipantTile(participant: participant);
      },
    );
  }

  List<_ParticipantView> get _participantViews => [
    _ParticipantView(
      userId: widget.currentUserId,
      displayName: '${widget.displayName} (You)',
      micEnabled: _micEnabled,
      cameraEnabled: _cameraEnabled,
      speaking: _localSpeaking,
      connected: true,
      isLocal: true,
      renderer: _localRenderer,
    ),
    for (final participant in _activeRemoteParticipants)
      _ParticipantView(
        userId: participant.userId,
        displayName: participant.displayName,
        micEnabled: participant.micEnabled,
        cameraEnabled:
            participant.cameraEnabled ||
            (_peers[participant.userId]?.cameraEnabled ?? false),
        speaking: _peers[participant.userId]?.isSpeaking ?? false,
        connected: _peers[participant.userId]?.connected ?? false,
        renderer: _peers[participant.userId]?.renderer,
      ),
  ];

  int _gridColumnCount(int participantCount) {
    if (participantCount <= 1) return 1;
    if (participantCount <= 4) return 2;
    return 3;
  }

  Widget _buildCallControls() => Center(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xE6212128),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CallControlButton(
            icon: _micEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
            label: _micEnabled ? 'Mute' : 'Unmute',
            selected: !_micEnabled,
            onPressed: _toggleMic,
          ),
          const SizedBox(width: 14),
          _CallControlButton(
            icon: _cameraEnabled
                ? Icons.videocam_rounded
                : Icons.videocam_off_rounded,
            label: _cameraChanging
                ? 'Switching...'
                : _cameraEnabled
                ? 'Camera off'
                : 'Camera on',
            selected: !_cameraEnabled,
            onPressed: _cameraChanging ? null : _toggleCamera,
          ),
          const SizedBox(width: 14),
          _CallControlButton(
            icon: Icons.call_end_rounded,
            label: 'Leave',
            destructive: true,
            onPressed: _ending ? null : _leaveCall,
          ),
        ],
      ),
    ),
  );
}

class _GroupPeer {
  _GroupPeer({
    required this.userId,
    required this.displayName,
    required this.connection,
    required this.renderer,
  });

  final String userId;
  String displayName;
  final RTCPeerConnection connection;
  final RTCVideoRenderer renderer;
  final List<RTCIceCandidate> pendingCandidates = [];
  MediaStream? remoteStream;
  Timer? disconnectTimer;
  bool remoteDescriptionSet = false;
  bool makingOffer = false;
  bool needsNegotiation = false;
  bool connected = false;
  bool micEnabled = true;
  bool cameraEnabled = false;
  bool isSpeaking = false;

  Future<void> dispose() async {
    disconnectTimer?.cancel();
    renderer.srcObject = null;
    await remoteStream?.dispose();
    await connection.close();
    await connection.dispose();
    await renderer.dispose();
  }
}

class _ParticipantView {
  const _ParticipantView({
    required this.userId,
    required this.displayName,
    required this.micEnabled,
    required this.cameraEnabled,
    required this.speaking,
    required this.connected,
    this.isLocal = false,
    this.renderer,
  });

  final String userId;
  final String displayName;
  final bool micEnabled;
  final bool cameraEnabled;
  final bool speaking;
  final bool connected;
  final bool isLocal;
  final RTCVideoRenderer? renderer;
}

class _VoiceParticipantTile extends StatelessWidget {
  const _VoiceParticipantTile({required this.participant});

  final _ParticipantView participant;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF181820),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: participant.speaking ? const Color(0xFF34D399) : Colors.white12,
        width: participant.speaking ? 3 : 1,
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PulsingCallAvatar(
          label: _initials(participant.displayName),
          active: participant.speaking,
          compact: true,
        ),
        const SizedBox(height: 14),
        Text(
          participant.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Icon(
          participant.micEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
          size: 18,
          color: participant.micEnabled ? Colors.white70 : Colors.redAccent,
        ),
      ],
    ),
  );
}

class _VideoParticipantTile extends StatelessWidget {
  const _VideoParticipantTile({required this.participant});

  final _ParticipantView participant;

  @override
  Widget build(BuildContext context) {
    final renderer = participant.renderer;
    final hasVideo =
        participant.cameraEnabled &&
        renderer != null &&
        renderer.srcObject != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF181820),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: participant.speaking
              ? const Color(0xFF34D399)
              : Colors.white12,
          width: participant.speaking ? 3 : 1,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasVideo)
            RTCVideoView(
              renderer,
              mirror: participant.isLocal,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            )
          else
            Center(
              child: _PulsingCallAvatar(
                label: _initials(participant.displayName),
                active: participant.speaking,
                compact: true,
              ),
            ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      participant.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    participant.micEnabled
                        ? Icons.mic_rounded
                        : Icons.mic_off_rounded,
                    size: 16,
                    color: participant.micEnabled
                        ? Colors.white
                        : Colors.redAccent,
                  ),
                ],
              ),
            ),
          ),
          if (!participant.connected && !participant.isLocal)
            const Positioned(
              top: 10,
              right: 10,
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white70,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CallControlButton extends StatelessWidget {
  const _CallControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool selected;
  final bool destructive;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton.filled(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          fixedSize: const Size(54, 54),
          backgroundColor: destructive
              ? const Color(0xFFEF4444)
              : selected
              ? Colors.white
              : const Color(0xFF383842),
          foregroundColor: destructive || !selected
              ? Colors.white
              : Colors.black87,
        ),
        icon: Icon(icon),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ],
  );
}

class _PulsingCallAvatar extends StatefulWidget {
  const _PulsingCallAvatar({
    required this.label,
    required this.active,
    this.compact = false,
  });

  final String label;
  final bool active;
  final bool compact;

  @override
  State<_PulsingCallAvatar> createState() => _PulsingCallAvatarState();
}

class _PulsingCallAvatarState extends State<_PulsingCallAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) {
      final pulse = widget.active ? _controller.value : 0.0;
      final baseSize = widget.compact ? 82.0 : 132.0;
      return Container(
        width: baseSize + pulse * 12,
        height: baseSize + pulse * 12,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(
            0xFF34D399,
          ).withValues(alpha: widget.active ? 0.14 + pulse * 0.14 : 0),
        ),
        child: child,
      );
    },
    child: CircleAvatar(
      radius: widget.compact ? 34 : 58,
      backgroundColor: const Color(0xFF6D28D9),
      foregroundColor: Colors.white,
      child: Text(
        widget.label,
        style: TextStyle(
          fontSize: widget.compact ? 22 : 34,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

double? _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}

String _formatDuration(Duration value) {
  final minutes = value.inMinutes.toString().padLeft(2, '0');
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String _initials(String value) {
  final words = value
      .replaceAll('(You)', '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(2);
  final initials = words.map((word) => word[0].toUpperCase()).join();
  return initials.isEmpty ? 'G' : initials;
}
