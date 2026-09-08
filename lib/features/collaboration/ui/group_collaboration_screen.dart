import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_mvvm_riverpod/core/routing/routes.dart';
import 'package:flutter_mvvm_riverpod/core/environment/env.dart';
import 'package:flutter_mvvm_riverpod/core/permissions/app_permission_service.dart';
import 'package:flutter_mvvm_riverpod/features/collaboration/model/collaboration_models.dart';
import 'package:flutter_mvvm_riverpod/features/collaboration/repository/collaboration_repository.dart';
import 'package:flutter_mvvm_riverpod/features/collaboration/ui/call_screen.dart';
import 'package:flutter_mvvm_riverpod/features/collaboration/ui/ringtone_player.dart';
import 'package:flutter_mvvm_riverpod/features/collaboration/ui/view_model/group_collaboration_view_model.dart';
import 'package:flutter_mvvm_riverpod/features/collaboration/ui/widgets/activity_proposal_dialog.dart';
import 'package:flutter_mvvm_riverpod/features/collaboration/ui/widgets/voice_recorder.dart';
import 'package:flutter_mvvm_riverpod/features/collaboration/ui/widgets/voice_message_player.dart';
import 'package:flutter_mvvm_riverpod/features/collaboration/ui/widgets/voice_recording_preview.dart';
import 'package:flutter_mvvm_riverpod/features/matchmaking/ui/matchmaking_view_model.dart';
import 'package:flutter_mvvm_riverpod/features/safety/repository/user_safety_repository.dart';
import 'package:flutter_mvvm_riverpod/features/safety/ui/widgets/block_user_action.dart';
import 'package:flutter_mvvm_riverpod/features/safety/ui/widgets/report_user_action.dart';
import 'package:flutter_mvvm_riverpod/features/safety/ui/trip_live_locations_screen.dart';

enum TripWorkspaceView { timeline, messages }

class GroupCollaborationScreen extends ConsumerStatefulWidget {
  const GroupCollaborationScreen({
    required this.tripId,
    this.knownRemoved = false,
    this.initialView = TripWorkspaceView.timeline,
    super.key,
  });
  final String tripId;
  final bool knownRemoved;
  final TripWorkspaceView initialView;

  @override
  ConsumerState<GroupCollaborationScreen> createState() =>
      _GroupCollaborationScreenState();
}

class _GroupCollaborationScreenState
    extends ConsumerState<GroupCollaborationScreen> {
  final Set<String> _handledIncomingCallIds = {};
  final RingtonePlayer _ringtone = RingtonePlayer();
  bool _incomingCallDialogVisible = false;
  String? _incomingCallId;
  BuildContext? _incomingDialogContext;
  Timer? _ringTimeout;

  @override
  void dispose() {
    _ringTimeout?.cancel();
    unawaited(_ringtone.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tripId.isEmpty || !Env.hasSupabase) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip workspace')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'The real group workspace needs a trip ID and Supabase configuration.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    if (widget.knownRemoved) {
      return _RemovedGroupScreen(tripId: widget.tripId);
    }
    final workspace = ref.watch(
      groupCollaborationViewModelProvider(widget.tripId),
    );
    return workspace.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => error is CollaborationAccessRemovedException
          ? _RemovedGroupScreen(tripId: widget.tripId)
          : Scaffold(
              appBar: AppBar(title: const Text('Trip workspace')),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('$error'),
                ),
              ),
            ),
      data: (state) {
        final viewModel = ref.read(
          groupCollaborationViewModelProvider(state.tripId).notifier,
        );
        _reconcileIncomingCall(state);
        _scheduleIncomingCall(state, viewModel);
        return switch (widget.initialView) {
          TripWorkspaceView.timeline => _TripTimelineScreen(state: state),
          TripWorkspaceView.messages => _Workspace(state: state),
        };
      },
    );
  }

  void _scheduleIncomingCall(
    GroupCollaborationState state,
    GroupCollaborationViewModel viewModel,
  ) {
    if (_incomingCallDialogVisible) return;
    final cutoff = DateTime.now().subtract(const Duration(seconds: 30));
    final incomingCalls =
        state.calls
            .where(
              (call) =>
                  call.status == 'ringing' &&
                  call.initiatedBy != state.currentUserId &&
                  call.createdAt.isAfter(cutoff) &&
                  !_handledIncomingCallIds.contains(call.id),
            )
            .toList()
          ..sort(
            (first, second) => second.createdAt.compareTo(first.createdAt),
          );
    final call = incomingCalls.firstOrNull;
    if (call == null) return;

    debugPrint(
      '[group_call] incoming_call_popup call_id=${call.id} '
      'trip_id=${state.tripId} recipient_id=${state.currentUserId} '
      'status=${call.status}',
    );
    _handledIncomingCallIds.add(call.id);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _incomingCallDialogVisible) return;
      _incomingCallDialogVisible = true;
      _incomingCallId = call.id;
      final isVideo = call.callType == 'video';
      final remaining =
          const Duration(seconds: 30) -
          DateTime.now().difference(call.createdAt);
      _ringTimeout = Timer(
        remaining.isNegative ? Duration.zero : remaining,
        _dismissIncomingCall,
      );
      var ringtoneNeedsInteraction = false;
      if (call.status == 'ringing') {
        try {
          ringtoneNeedsInteraction = !await _ringtone.startRinging();
        } catch (error) {
          ringtoneNeedsInteraction = true;
          debugPrint(
            '[group_call] ringtone_start_failed call_id=${call.id} error=$error',
          );
        }
      }
      if (!mounted) {
        _ringTimeout?.cancel();
        _ringTimeout = null;
        _incomingCallId = null;
        _incomingCallDialogVisible = false;
        await _ringtone.stopRinging();
        return;
      }
      bool? accepted;
      try {
        accepted = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              _incomingDialogContext = dialogContext;
              return Stack(
                children: [
                  Center(
                    child: AlertDialog(
                      icon: CircleAvatar(
                        radius: 30,
                        backgroundColor: Theme.of(
                          dialogContext,
                        ).colorScheme.primaryContainer,
                        child: Icon(
                          isVideo ? Icons.videocam : Icons.call,
                          size: 30,
                          color: Theme.of(
                            dialogContext,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(
                        'Incoming group ${isVideo ? 'video' : 'voice'} call',
                      ),
                      content: Text(
                        '${call.initiatedByName} started a call with ${state.tripTitle}.',
                        textAlign: TextAlign.center,
                      ),
                      actions: [
                        TextButton.icon(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          icon: const Icon(Icons.call_end),
                          label: const Text('Decline'),
                        ),
                        FilledButton.icon(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          icon: const Icon(Icons.call),
                          label: const Text('Accept'),
                        ),
                      ],
                    ),
                  ),
                  if (ringtoneNeedsInteraction)
                    Positioned(
                      top: 12,
                      left: 16,
                      right: 16,
                      child: SafeArea(
                        child: Material(
                          color: Theme.of(
                            dialogContext,
                          ).colorScheme.errorContainer,
                          elevation: 8,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              final started = await _ringtone.startRinging();
                              if (started && dialogContext.mounted) {
                                setDialogState(
                                  () => ringtoneNeedsInteraction = false,
                                );
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.volume_up_rounded),
                                  SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      'Ringing... Tap to unmute ringtone',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      } finally {
        _ringTimeout?.cancel();
        _ringTimeout = null;
        _incomingDialogContext = null;
        _incomingCallId = null;
        _incomingCallDialogVisible = false;
        await _ringtone.stopRinging();
      }
      debugPrint(
        '[group_call] incoming_call_response call_id=${call.id} '
        'recipient_id=${state.currentUserId} accepted=${accepted == true}',
      );
      if (accepted != true || !mounted) return;
      await _openInAppCall(
        context,
        state,
        call.callType,
        () => viewModel.joinCall(call),
        viewModel,
      );
    });
  }

  void _reconcileIncomingCall(GroupCollaborationState state) {
    final callId = _incomingCallId;
    if (!_incomingCallDialogVisible || callId == null) return;
    final call = state.calls.where((item) => item.id == callId).firstOrNull;
    if (call == null || call.status == 'ended') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _dismissIncomingCall();
      });
    } else if (call.status == 'active') {
      // The first accepted participant changes the shared call to active.
      // Other invitees keep the option to join, but should no longer ring.
      unawaited(_ringtone.stopRinging());
    }
  }

  void _dismissIncomingCall() {
    unawaited(_ringtone.stopRinging());
    final dialogContext = _incomingDialogContext;
    if (dialogContext != null && dialogContext.mounted) {
      final navigator = Navigator.of(dialogContext);
      if (navigator.canPop()) navigator.pop(false);
    }
  }
}

class _RemovedGroupScreen extends ConsumerWidget {
  const _RemovedGroupScreen({required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Trip workspace')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.group_remove_outlined, size: 56),
            const SizedBox(height: 16),
            const Text(
              'You are no longer a member of this trip group.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'You can remove this group from Messages. The trip may appear '
              'in Discovery again if it is still accepting travellers.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                final matchmaking = ref.read(
                  matchmakingViewModelProvider.notifier,
                );
                matchmaking.dismissGroup(tripId);
                ref.invalidate(groupCollaborationViewModelProvider(tripId));
                context.go(Routes.messages);
                // Permanently clean up a stale matchmaking membership only
                // after collaboration access has already been revoked.
                ref
                    .read(collaborationRepositoryProvider)
                    .dismissRemovedGroup(tripId)
                    .then((_) => matchmaking.refresh())
                    .catchError((_) {
                      // The local dismissal remains immediate. A later retry
                      // can reconcile if the device was temporarily offline.
                    });
              },
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Remove from Messages'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Workspace extends ConsumerStatefulWidget {
  const _Workspace({required this.state});
  final GroupCollaborationState state;

  @override
  ConsumerState<_Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends ConsumerState<_Workspace> {
  final Set<String> _seenNotificationIds = {};

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final unreadNotifications = state.unreadNotifications
        .where((item) => !_seenNotificationIds.contains(item.id))
        .toList(growable: false);
    final viewModel = ref.read(
      groupCollaborationViewModelProvider(state.tripId).notifier,
    );
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go(Routes.tripTimeline(state.tripId)),
          tooltip: 'Back to timeline',
          icon: const Icon(Icons.arrow_back),
        ),
        title: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => GroupInfoScreen(state: state),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.tripTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${_tripDateMetadata(state)} • Tap for group info',
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _openLiveLocations(context, state),
            icon: const Icon(Icons.location_on_outlined),
            tooltip: 'Trip members live locations',
          ),
          IconButton(
            onPressed: () {
              final activeCall = _activeCall(state);
              _openInAppCall(
                context,
                state,
                activeCall?.callType ?? 'voice',
                activeCall == null
                    ? () => viewModel.startCall('voice')
                    : () => viewModel.joinCall(activeCall),
                viewModel,
              );
            },
            icon: const Icon(Icons.call_outlined),
            tooltip: _activeCall(state) == null
                ? 'Start voice call'
                : 'Join active call',
          ),
          IconButton(
            onPressed: () {
              final activeCall = _activeCall(state);
              _openInAppCall(
                context,
                state,
                activeCall?.callType ?? 'video',
                activeCall == null
                    ? () => viewModel.startCall('video')
                    : () => viewModel.joinCall(activeCall),
                viewModel,
              );
            },
            icon: const Icon(Icons.videocam_outlined),
            tooltip: _activeCall(state) == null
                ? 'Start video call'
                : 'Join active call',
          ),
          IconButton(
            onPressed: () async {
              final newlySeenIds = state.unreadNotifications
                  .map((item) => item.id)
                  .toSet();
              setState(() {
                _seenNotificationIds.addAll(newlySeenIds);
              });
              _showNotifications(context, state.notifications);
              try {
                await viewModel.markCollaborationNotificationsRead();
              } catch (error) {
                if (!context.mounted) return;
                setState(() => _seenNotificationIds.removeAll(newlySeenIds));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Could not mark updates read: $error'),
                  ),
                );
              }
            },
            icon: Badge(
              isLabelVisible: unreadNotifications.isNotEmpty,
              label: Text('${unreadNotifications.length}'),
              child: const Icon(Icons.notifications_outlined),
            ),
            tooltip: 'Collaboration updates',
          ),
        ],
      ),
      body: _ChatTab(state: state),
    );
  }
}

class GroupInfoScreen extends ConsumerWidget {
  const GroupInfoScreen({required this.state, super.key});

  final GroupCollaborationState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(
      groupCollaborationViewModelProvider(state.tripId).notifier,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Group info')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 44,
            child: Icon(
              Icons.groups,
              size: 44,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              state.tripTitle,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(
              '${_tripDateMetadata(state)} • ${state.members.length} members',
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _GroupInfoAction(
                icon: Icons.call_outlined,
                label: 'Voice',
                onTap: () => _openInAppCall(
                  context,
                  state,
                  _activeCall(state)?.callType ?? 'voice',
                  _activeCall(state) == null
                      ? () => viewModel.startCall('voice')
                      : () => viewModel.joinCall(_activeCall(state)!),
                  viewModel,
                ),
              ),
              _GroupInfoAction(
                icon: Icons.videocam_outlined,
                label: 'Video',
                onTap: () => _openInAppCall(
                  context,
                  state,
                  _activeCall(state)?.callType ?? 'video',
                  _activeCall(state) == null
                      ? () => viewModel.startCall('video')
                      : () => viewModel.joinCall(_activeCall(state)!),
                  viewModel,
                ),
              ),
              _GroupInfoAction(
                icon: Icons.person_add_alt_1_outlined,
                label: 'Members',
                onTap: () => _openGroupSection(
                  context,
                  'Members',
                  _MembersInfoTab(state: state),
                ),
              ),
              _GroupInfoAction(
                icon: Icons.notifications_outlined,
                label: 'Updates',
                onTap: () => _showNotifications(context, state.notifications),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          _GroupInfoTile(
            icon: Icons.calendar_month_outlined,
            title: 'Timeline & activities',
            subtitle: 'Proposals, polls, RSVPs and activity comments',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _TripTimelineScreen(state: state),
              ),
            ),
          ),
          _GroupInfoTile(
            icon: Icons.sos_rounded,
            iconColor: Theme.of(context).colorScheme.error,
            title: 'Emergency SOS',
            subtitle: 'Open emergency help, location and contact alerts',
            onTap: () => context.push(Routes.sos),
          ),
          _GroupInfoTile(
            icon: Icons.location_on_outlined,
            title: 'Live locations',
            subtitle: 'See where sharing trip members are now',
            onTap: () => _openLiveLocations(context, state),
          ),
          _GroupInfoTile(
            icon: Icons.folder_outlined,
            title: 'Files & media',
            subtitle: '${state.files.length} shared file(s)',
            onTap: () => _openGroupSection(
              context,
              'Files & media',
              _FilesTab(state: state),
            ),
          ),
          _GroupInfoTile(
            icon: Icons.history_outlined,
            title: 'Calls',
            subtitle: '${state.calls.length} call(s) in history',
            onTap: () =>
                _openGroupSection(context, 'Calls', _CallsTab(state: state)),
          ),
          const Divider(),
          const Text(
            'Group members',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...state.members
              .take(6)
              .map(
                (member) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _MemberAvatar(
                    member: member,
                    currentUserId: state.currentUserId,
                    onTap: () => _showMemberSafetyActions(
                      context: context,
                      ref: ref,
                      member: member,
                    ),
                  ),
                  title: Text(member.displayName ?? 'Trip member'),
                  subtitle: Text(
                    member.userId == state.creatorId
                        ? 'Leader'
                        : member.isAdmin
                        ? 'Admin'
                        : 'Member',
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _GroupInfoAction extends StatelessWidget {
  const _GroupInfoAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      IconButton.filledTonal(onPressed: onTap, icon: Icon(icon)),
      const SizedBox(height: 4),
      Text(label),
    ],
  );
}

class _GroupInfoTile extends StatelessWidget {
  const _GroupInfoTile({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: iconColor),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}

void _openGroupSection(BuildContext context, String title, Widget child) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: child,
      ),
    ),
  );
}

void _openLiveLocations(BuildContext context, GroupCollaborationState state) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => TripLiveLocationsScreen(
        tripId: state.tripId,
        members: state.members,
        currentUserId: state.currentUserId,
      ),
    ),
  );
}

class _MembersInfoTab extends ConsumerWidget {
  const _MembersInfoTab({required this.state});

  final GroupCollaborationState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(
      groupCollaborationViewModelProvider(state.tripId).notifier,
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Group members',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...state.members.map(
          (member) => ListTile(
            onTap: member.userId == state.currentUserId
                ? () => context.push(Routes.userAccount)
                : () => _showMemberSafetyActions(
                    context: context,
                    ref: ref,
                    member: member,
                  ),
            leading: _MemberAvatar(
              member: member,
              currentUserId: state.currentUserId,
              onTap: () => _showMemberSafetyActions(
                context: context,
                ref: ref,
                member: member,
              ),
            ),
            subtitle: Text(
              member.userId == state.creatorId
                  ? 'Leader'
                  : member.isMuted
                  ? 'Muted'
                  : member.isAdmin
                  ? 'Admin'
                  : 'Member',
            ),
            trailing:
                member.userId == state.currentUserId || !state.canManageMembers
                ? null
                : Wrap(
                    spacing: 4,
                    children: [
                      TextButton(
                        onPressed: () => _confirmMemberAction(
                          context: context,
                          title: member.isMuted
                              ? 'Unmute member?'
                              : 'Mute member?',
                          message:
                              'This member cannot send chat messages for 30 minutes.',
                          confirmLabel: member.isMuted ? 'Unmute' : 'Mute',
                          onConfirm: () => member.isMuted
                              ? viewModel.unmuteMember(member.userId)
                              : viewModel.muteMember(
                                  member.userId,
                                  const Duration(minutes: 30),
                                ),
                        ),
                        child: Text(member.isMuted ? 'Unmute' : 'Mute'),
                      ),
                      TextButton(
                        onPressed: () => _confirmMemberAction(
                          context: context,
                          title: 'Remove member?',
                          message:
                              'They will lose access to this trip workspace.',
                          confirmLabel: 'Remove',
                          isDestructive: true,
                          onConfirm: () =>
                              viewModel.removeMember(member.userId),
                        ),
                        child: const Text('Remove'),
                      ),
                      if (state.isCreator && !member.isAdmin)
                        TextButton(
                          onPressed: () => _confirmMemberAction(
                            context: context,
                            title: 'Make admin?',
                            message: 'Admins can mute or remove group members.',
                            confirmLabel: 'Make admin',
                            onConfirm: () => viewModel.makeAdmin(member.userId),
                          ),
                          child: const Text('Make admin'),
                        ),
                      if (state.isCreator && member.isAdmin)
                        TextButton(
                          onPressed: () => _confirmMemberAction(
                            context: context,
                            title: 'Remove admin?',
                            message:
                                'This member will remain in the group but lose admin permissions.',
                            confirmLabel: 'Remove admin',
                            onConfirm: () =>
                                viewModel.removeAdmin(member.userId),
                          ),
                          child: const Text('Remove admin'),
                        ),
                    ],
                  ),
            title: Row(
              children: [
                Expanded(child: Text(member.displayName ?? 'Trip member')),
                if (member.userId == state.creatorId)
                  const _RoleBadge(label: 'Leader')
                else if (member.isAdmin)
                  const _RoleBadge(label: 'Admin'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({
    required this.member,
    required this.currentUserId,
    required this.onTap,
  });

  final CollaborationMember member;
  final String currentUserId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayName = member.displayName?.trim();
    final photoUrl = member.profilePhotoUrl?.trim();
    final avatar = CircleAvatar(
      foregroundImage: photoUrl == null || photoUrl.isEmpty
          ? null
          : NetworkImage(photoUrl),
      child: Text(
        displayName == null || displayName.isEmpty
            ? 'M'
            : displayName[0].toUpperCase(),
      ),
    );
    if (member.userId == currentUserId) {
      return Tooltip(message: 'Open your profile', child: avatar);
    }

    return Tooltip(
      message: 'User options',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: avatar,
      ),
    );
  }
}

Future<void> _showMemberSafetyActions({
  required BuildContext context,
  required WidgetRef ref,
  required CollaborationMember member,
}) async {
  final isBlocked = await ref
      .read(userSafetyRepositoryProvider)
      .isUserBlocked(member.userId);
  if (!context.mounted) return;
  final action = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('View profile'),
            onTap: () => Navigator.pop(sheetContext, 'profile'),
          ),
          ListTile(
            leading: Icon(
              isBlocked ? Icons.check_circle_outline : Icons.block,
              color: isBlocked ? null : Colors.red,
            ),
            title: Text(isBlocked ? 'Unblock user' : 'Block user'),
            onTap: () => Navigator.pop(sheetContext, 'block'),
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Report user'),
            onTap: () => Navigator.pop(sheetContext, 'report'),
          ),
        ],
      ),
    ),
  );
  if (action == null || !context.mounted) return;

  final displayName = member.displayName ?? 'Trip member';
  if (action == 'profile') {
    await context.push(
      '${Routes.publicProfile}/${Uri.encodeComponent(member.userId)}',
    );
  } else if (action == 'block') {
    await BlockUserAction.show(
      context: context,
      ref: ref,
      targetUserId: member.userId,
      targetDisplayName: displayName,
      isBlocked: isBlocked,
    );
  } else if (action == 'report') {
    await ReportUserAction.show(
      context: context,
      ref: ref,
      targetUserId: member.userId,
      targetDisplayName: displayName,
    );
  }
}

class _ChatTab extends ConsumerStatefulWidget {
  const _ChatTab({required this.state});
  final GroupCollaborationState state;

  @override
  ConsumerState<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<_ChatTab> {
  final _messageController = TextEditingController();
  final _messagesController = ScrollController();
  final _voiceRecorder = VoiceRecorder();
  Timer? _recordingTimer;
  bool _isTyping = false;
  bool _readMarked = false;
  bool _isRecordingVoice = false;
  bool _isSendingVoice = false;
  Duration _recordingDuration = Duration.zero;
  Uint8List? _voicePreviewBytes;
  String _voicePreviewExtension = 'webm';

  @override
  void initState() {
    super.initState();
    _scheduleScrollToBottom(animated: false);
  }

  @override
  void didUpdateWidget(covariant _ChatTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldLatest = _latestMessageId(oldWidget.state.messages);
    final newLatest = _latestMessageId(widget.state.messages);
    if (oldLatest != newLatest ||
        oldWidget.state.messages.length != widget.state.messages.length) {
      _readMarked = false;
      _scheduleScrollToBottom(animated: true);
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _voiceRecorder.dispose();
    _messagesController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.read(
      groupCollaborationViewModelProvider(widget.state.tripId).notifier,
    );
    if (!_readMarked && widget.state.messages.isNotEmpty) {
      _readMarked = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => viewModel.markMessagesRead(),
      );
    }
    final messages = [...widget.state.messages]
      ..sort((first, second) {
        final byTime = first.sentAt.compareTo(second.sentAt);
        return byTime != 0 ? byTime : first.id.compareTo(second.id);
      });
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _messagesController,
            reverse: false,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(16),
            children: [
              ...messages.map(
                (message) => _MessageBubble(
                  message: message,
                  isMine: message.senderId == widget.state.currentUserId,
                ),
              ),
              if (widget.state.typingMemberNames.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${widget.state.typingMemberNames.join(', ')} ${widget.state.typingMemberNames.length == 1 ? 'is' : 'are'} typing…',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _buildComposer(viewModel),
          ),
        ),
      ],
    );
  }

  Widget _buildComposer(GroupCollaborationViewModel viewModel) {
    if (_isRecordingVoice) return _buildRecordingBar();
    final previewBytes = _voicePreviewBytes;
    if (previewBytes != null) {
      return _buildVoicePreviewBar(viewModel, previewBytes);
    }
    return Row(
      children: [
        IconButton(
          onPressed: () =>
              _runWorkspaceAction(context, viewModel.pickAndShareFile),
          icon: const Icon(Icons.attach_file),
          tooltip: 'Share file',
        ),
        IconButton(
          onPressed: widget.state.isMuted
              ? null
              : () => _runWorkspaceAction(context, viewModel.takeAndSharePhoto),
          icon: const Icon(Icons.camera_alt_outlined),
          tooltip: 'Take photo',
        ),
        Expanded(
          child: TextField(
            controller: _messageController,
            onChanged: (value) {
              final typing = value.trim().isNotEmpty;
              if (typing != _isTyping) {
                _isTyping = typing;
                viewModel.setTyping(typing);
              }
            },
            enabled: !widget.state.isMuted,
            decoration: const InputDecoration(
              hintText: 'Message group',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        IconButton(
          onPressed: widget.state.isMuted ? null : () => _sendText(viewModel),
          icon: const Icon(Icons.send),
          tooltip: 'Send message',
        ),
        IconButton(
          onPressed: widget.state.isMuted ? null : () => _startVoiceRecording(),
          icon: const Icon(Icons.mic),
          tooltip: 'Record voice message',
        ),
      ],
    );
  }

  Widget _buildRecordingBar() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _cancelVoiceRecording,
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Discard recording',
          ),
          const _BlinkingRecordingDot(),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Recording  ${_formatVoiceDuration(_recordingDuration)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.onErrorContainer,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          IconButton.filled(
            onPressed: _stopVoiceRecording,
            style: IconButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            ),
            icon: const Icon(Icons.stop_rounded),
            tooltip: 'Stop recording',
          ),
        ],
      ),
    );
  }

  Widget _buildVoicePreviewBar(
    GroupCollaborationViewModel viewModel,
    Uint8List previewBytes,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _isSendingVoice ? null : _discardVoicePreview,
            color: colors.error,
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete voice message',
          ),
          VoiceRecordingPreviewButton(
            bytes: previewBytes,
            fileExtension: _voicePreviewExtension,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Voice message preview',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatVoiceDuration(_recordingDuration),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: _isSendingVoice
                ? null
                : () => _sendVoicePreview(viewModel, previewBytes),
            icon: _isSendingVoice
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            tooltip: 'Send voice message',
          ),
        ],
      ),
    );
  }

  void _scheduleScrollToBottom({required bool animated}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_messagesController.hasClients) return;
      final target = _messagesController.position.maxScrollExtent;
      if (animated) {
        _messagesController.animateTo(
          target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      } else {
        _messagesController.jumpTo(target);
      }
    });
  }

  String? _latestMessageId(List<TripMessage> messages) {
    if (messages.isEmpty) return null;
    var latest = messages.first;
    for (final message in messages.skip(1)) {
      if (message.sentAt.isAfter(latest.sentAt) ||
          (message.sentAt == latest.sentAt &&
              message.id.compareTo(latest.id) > 0)) {
        latest = message;
      }
    }
    return latest.id;
  }

  Future<void> _sendText(GroupCollaborationViewModel viewModel) async {
    try {
      await viewModel.sendMessage(_messageController.text);
      _messageController.clear();
      _isTyping = false;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Could not send message: $error')),
        );
    }
  }

  Future<void> _startVoiceRecording() async {
    try {
      await _voiceRecorder.start();
      if (!mounted) return;
      _recordingTimer?.cancel();
      setState(() {
        _recordingDuration = Duration.zero;
        _isRecordingVoice = true;
      });
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => _recordingDuration += const Duration(seconds: 1));
        }
      });
    } catch (error) {
      _showVoiceError(error);
    }
  }

  Future<void> _stopVoiceRecording() async {
    _recordingTimer?.cancel();
    try {
      final bytes = await _voiceRecorder.stop();
      if (bytes == null || bytes.isEmpty) {
        throw StateError('No sound was recorded. Please try again.');
      }
      if (!mounted) return;
      setState(() {
        _isRecordingVoice = false;
        _voicePreviewBytes = bytes;
        _voicePreviewExtension = _voiceRecorder.fileExtension;
      });
    } catch (error) {
      if (mounted) setState(() => _isRecordingVoice = false);
      _showVoiceError(error);
    }
  }

  Future<void> _cancelVoiceRecording() async {
    _recordingTimer?.cancel();
    try {
      await _voiceRecorder.stop();
    } catch (_) {
      // The recording is being discarded, so cleanup can continue.
    }
    _resetVoiceComposer();
  }

  void _discardVoicePreview() => _resetVoiceComposer();

  Future<void> _sendVoicePreview(
    GroupCollaborationViewModel viewModel,
    Uint8List bytes,
  ) async {
    setState(() => _isSendingVoice = true);
    try {
      await viewModel.shareVoiceMessage(
        bytes,
        fileExtension: _voicePreviewExtension,
      );
      _resetVoiceComposer();
    } catch (error) {
      if (mounted) setState(() => _isSendingVoice = false);
      _showVoiceError(error, action: 'send');
    }
  }

  void _resetVoiceComposer() {
    if (!mounted) return;
    setState(() {
      _recordingTimer?.cancel();
      _isRecordingVoice = false;
      _isSendingVoice = false;
      _voicePreviewBytes = null;
      _recordingDuration = Duration.zero;
    });
  }

  void _showVoiceError(Object error, {String action = 'record'}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not $action voice message: $error')),
    );
  }
}

class _BlinkingRecordingDot extends StatefulWidget {
  const _BlinkingRecordingDot();

  @override
  State<_BlinkingRecordingDot> createState() => _BlinkingRecordingDotState();
}

class _BlinkingRecordingDotState extends State<_BlinkingRecordingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(begin: 0.25, end: 1).animate(_controller),
    child: Container(
      width: 11,
      height: 11,
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
    ),
  );
}

String _formatVoiceDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final TripMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final photoUrl = _messageAttachmentUrl(message.body, '[photo]');
    final voiceUrl = _messageAttachmentUrl(message.body, '[voice]');
    final sharedActivity = _sharedActivityParts(message.body);
    final callHistory = _callHistoryParts(message.body);
    final systemMessage = message.body.startsWith('[system]')
        ? message.body.substring('[system]'.length)
        : null;
    if (callHistory != null) {
      return _CallHistoryMessage(parts: callHistory, sentAt: message.sentAt);
    }
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMine
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMine ? 16 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: isMine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isMine)
                Text(
                  message.senderName ?? 'Trip member',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              if (photoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    photoUrl,
                    height: 220,
                    width: 280,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Photo could not be loaded.'),
                    ),
                  ),
                )
              else if (voiceUrl != null)
                VoiceMessagePlayer(
                  url: voiceUrl,
                  isMine: isMine,
                  isRead: message.readByCount > 0,
                )
              else if (sharedActivity != null)
                _SharedActivityPreview(parts: sharedActivity)
              else if (systemMessage != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline, size: 17),
                    const SizedBox(width: 7),
                    Flexible(child: Text(systemMessage)),
                  ],
                )
              else
                Text(message.body),
              const SizedBox(height: 4),
              Text(
                isMine
                    ? '${_shortTime(message.sentAt)} · Seen by ${message.readByCount}'
                    : _shortTime(message.sentAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<String>? _callHistoryParts(String body) {
  if (!body.startsWith('[call_history]|')) return null;
  final parts = body.substring('[call_history]|'.length).split('|');
  if (parts.length != 3 ||
      !const {'completed', 'cancelled', 'missed'}.contains(parts[0]) ||
      !const {'voice', 'video'}.contains(parts[1])) {
    return null;
  }
  return parts;
}

class _CallHistoryMessage extends StatelessWidget {
  const _CallHistoryMessage({required this.parts, required this.sentAt});

  final List<String> parts;
  final DateTime sentAt;

  @override
  Widget build(BuildContext context) {
    final status = parts[0];
    final isVideo = parts[1] == 'video';
    final duration = Duration(seconds: int.tryParse(parts[2]) ?? 0);
    final label = switch (status) {
      'completed' =>
        '${isVideo ? 'Video' : 'Voice'} call • ${_formatCallHistoryDuration(duration)}',
      'missed' => 'Missed ${isVideo ? 'video' : 'voice'} call',
      _ => '${isVideo ? 'Video' : 'Voice'} call cancelled',
    };
    final iconColor = status == 'missed'
        ? Theme.of(context).colorScheme.error
        : status == 'completed'
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isVideo ? Icons.videocam_rounded : Icons.call_rounded,
              size: 18,
              color: iconColor,
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Text(
              _shortTime(sentAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatCallHistoryDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  if (hours > 0) return '${hours}h ${minutes}m ${seconds}s';
  if (minutes > 0) return '${minutes}m ${seconds}s';
  return '${seconds}s';
}

String? _messageAttachmentUrl(String body, String prefix) {
  if (!body.startsWith(prefix)) return null;
  final url = body.substring(prefix.length).trim();
  return Uri.tryParse(url)?.hasScheme == true ? url : null;
}

List<String>? _sharedActivityParts(String body) {
  if (!body.startsWith('[activity_share]')) return null;
  final parts = body.substring('[activity_share]'.length).split('|');
  return parts.length >= 4 ? parts : null;
}

class _SharedActivityPreview extends StatelessWidget {
  const _SharedActivityPreview({required this.parts});
  final List<String> parts;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(parts[2])?.toLocal();
    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_month_outlined, size: 17),
              SizedBox(width: 6),
              Text(
                'Shared activity',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            parts[1],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          if (date != null) Text('${_monthDay(date)} at ${_clockTime(date)}'),
          if (parts[3].isNotEmpty) Text(parts[3]),
        ],
      ),
    );
  }
}

class _TripTimelineScreen extends ConsumerStatefulWidget {
  const _TripTimelineScreen({required this.state});

  final GroupCollaborationState state;

  @override
  ConsumerState<_TripTimelineScreen> createState() =>
      _TripTimelineScreenState();
}

class _TripTimelineScreenState extends ConsumerState<_TripTimelineScreen> {
  DateTime? _selectedDate;
  DateTime? _pendingDay;
  final List<DateTime> _locallyDeletedDays = [];
  bool _deletingDay = false;

  List<DateTime> _days(GroupCollaborationState state) {
    final values = <DateTime>[];
    void addUnique(DateTime value) {
      final day = DateTime(value.year, value.month, value.day);
      if (!values.any((existing) => _sameDay(existing, day))) values.add(day);
    }

    for (final day in state.timelineDays) {
      addUnique(day);
    }
    // Only persisted trip_timeline_days records are deletable day tabs. The
    // previous date-range/activity fallback produced visible tabs with no
    // matching database key, causing delete_trip_timeline_day to raise P0001.
    if (_pendingDay != null) addUnique(_pendingDay!);
    values.removeWhere(
      (day) => _locallyDeletedDays.any((deleted) => _sameDay(day, deleted)),
    );
    values.sort();
    return values;
  }

  GroupCollaborationViewModel get _viewModel => ref.read(
    groupCollaborationViewModelProvider(widget.state.tripId).notifier,
  );

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(
      groupCollaborationViewModelProvider(widget.state.tripId),
    );
    final state = switch (workspace) {
      AsyncData<GroupCollaborationState>(:final value) => value,
      _ => widget.state,
    };
    final days = _days(state);
    final requestedDate = _selectedDate;
    final requestedIndex = requestedDate == null
        ? -1
        : days.indexWhere((day) => _sameDay(day, requestedDate));
    final selectedIndex = days.isEmpty
        ? -1
        : requestedIndex < 0
        ? 0
        : requestedIndex;
    final selectedDate = selectedIndex < 0 ? null : days[selectedIndex];
    final activities = [...state.activities]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final selectedActivities = selectedDate == null
        ? <TripActivity>[]
        : activities
              .where((activity) => _sameDay(activity.startTime, selectedDate))
              .toList();
    final durationDays = days.length;
    final pendingProposals = state.pendingActivityProposals;
    const purple = Color(0xFF7C3AED);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.tripTitle,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${_tripDateMetadata(state)} • $durationDays ${durationDays == 1 ? 'day' : 'days'}',
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          if (state.canManageMembers)
            IconButton(
              onPressed: () => _showPendingProposals(state),
              tooltip: 'Pending proposals',
              icon: Badge(
                isLabelVisible: pendingProposals.isNotEmpty,
                label: Text('${pendingProposals.length}'),
                child: const Icon(Icons.fact_check_outlined),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => context.push(Routes.sos),
              icon: const Icon(Icons.sos_rounded),
              label: const Text('SOS'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 68,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: days.length + (state.canManageMembers ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == days.length) {
                  return InkWell(
                    onTap: () => _pickAndAddDay(days),
                    child: const SizedBox(
                      width: 88,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline),
                          SizedBox(height: 3),
                          Text(
                            'Add Day',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final selected = index == selectedIndex;
                return InkWell(
                  onTap: () => setState(() => _selectedDate = days[index]),
                  onLongPress: _deletingDay || !state.canManageMembers
                      ? null
                      : () =>
                            _confirmDeleteDay(days: days, selectedIndex: index),
                  child: Container(
                    width: 92,
                    padding: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: selected ? purple : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Day ${index + 1}',
                              style: TextStyle(
                                color: selected ? purple : null,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (state.canManageMembers)
                              SizedBox(
                                width: 30,
                                height: 30,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  tooltip: 'Delete Day ${index + 1}',
                                  onPressed: _deletingDay
                                      ? null
                                      : () => _confirmDeleteDay(
                                          days: days,
                                          selectedIndex: index,
                                        ),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 17,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          _monthDay(days[index]),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          if (state.canManageMembers)
            ListTile(
              dense: true,
              leading: const Icon(Icons.fact_check_outlined),
              title: const Text('Pending Proposals'),
              subtitle: Text(
                pendingProposals.isEmpty
                    ? 'No activities waiting for review'
                    : '${pendingProposals.length} waiting for review',
              ),
              trailing: pendingProposals.isEmpty
                  ? const Icon(Icons.chevron_right)
                  : Badge(label: Text('${pendingProposals.length}')),
              onTap: () => _showPendingProposals(state),
            )
          else if (pendingProposals.isNotEmpty)
            ListTile(
              dense: true,
              leading: const Icon(Icons.schedule_send_outlined),
              title: Text(
                '${pendingProposals.length} ${pendingProposals.length == 1 ? 'proposal' : 'proposals'} pending admin review',
              ),
            ),
          Expanded(
            child: selectedDate == null
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No itinerary days yet. Use Add Day to create one.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : selectedActivities.isEmpty && state.polls.isEmpty
                ? const Center(child: Text('No activities for this day yet.'))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 164),
                    children: [
                      ...selectedActivities.indexed.map(
                        (entry) => _TimelineActivityItem(
                          state: state,
                          activity: entry.$2,
                          isLast: entry.$1 == selectedActivities.length - 1,
                        ),
                      ),
                      if (selectedActivities.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text('No activities for this day yet.'),
                          ),
                        ),
                      if (state.polls.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(top: 8, bottom: 8),
                          child: Text(
                            'Activity Polls',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ...state.polls.map(
                          (poll) => _TimelinePollCard(state: state, poll: poll),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'timeline-chat-${state.tripId}',
            onPressed: () => context.push(Routes.tripMessages(state.tripId)),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: const Text('Group Chat'),
          ),
          if (selectedDate != null) ...[
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              heroTag: 'timeline-activity-${state.tripId}',
              backgroundColor: const Color(0xFF281950),
              foregroundColor: Colors.white,
              onPressed: () => _showAddActivity(state, selectedDate),
              icon: const Icon(Icons.add),
              label: Text(
                state.canManageMembers ? 'Add Activity' : 'Propose Activity',
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 2,
        onDestinationSelected: (index) {
          final route = switch (index) {
            0 || 1 => Routes.main,
            2 => Routes.myTrips,
            3 => Routes.tripMessages(state.tripId),
            _ => Routes.userAccount,
          };
          context.go(route);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            label: 'Trips',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Future<void> _showAddActivity(GroupCollaborationState state, DateTime day) =>
      showDialog<void>(
        context: context,
        builder: (_) => ActivityProposalDialog(
          proposalMode: !state.canManageMembers,
          allowPoll: state.canManageMembers,
          onPropose: (title, location, time) async {
            final startTime = DateTime(
              day.year,
              day.month,
              day.day,
              time.hour,
              time.minute,
            );
            if (state.canManageMembers) {
              await _viewModel.addActivity(
                title: title,
                location: location,
                startTime: startTime,
              );
              return true;
            }
            return _viewModel.proposeActivity(
              title: title,
              location: location,
              startTime: startTime,
            );
          },
          onCreatePoll: (question, options) => _viewModel.createActivityPoll(
            question: question,
            options: options,
          ),
        ),
      );

  Future<void> _showPendingProposals(
    GroupCollaborationState state,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.72,
        child: Column(
          children: [
            const ListTile(
              leading: Icon(Icons.fact_check_outlined),
              title: Text(
                'Pending Proposals',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('Review activities submitted by members.'),
            ),
            const Divider(height: 1),
            Expanded(
              child: state.pendingActivityProposals.isEmpty
                  ? const Center(
                      child: Text('No proposals are waiting for review.'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.pendingActivityProposals.length,
                      itemBuilder: (_, index) {
                        final proposal = state.pendingActivityProposals[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  proposal.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${_fullDate(proposal.startTime)} at ${_clockTime(proposal.startTime)}',
                                ),
                                if (proposal.location?.isNotEmpty == true)
                                  Text(proposal.location!),
                                Text(
                                  'Proposed by ${proposal.proposedByName ?? 'Trip member'}',
                                  style: Theme.of(
                                    sheetContext,
                                  ).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () => _reviewProposal(
                                        sheetContext,
                                        proposal,
                                        accept: false,
                                      ),
                                      child: const Text('Reject'),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton.icon(
                                      onPressed: () => _reviewProposal(
                                        sheetContext,
                                        proposal,
                                        accept: true,
                                      ),
                                      icon: const Icon(Icons.check),
                                      label: const Text('Accept'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _reviewProposal(
    BuildContext sheetContext,
    TripActivityProposal proposal, {
    required bool accept,
  }) async {
    try {
      final reviewed = await _viewModel.reviewActivityProposal(
        proposal,
        accept: accept,
      );
      if (!reviewed) {
        if (sheetContext.mounted) {
          ScaffoldMessenger.of(sheetContext).showSnackBar(
            const SnackBar(
              content: Text(
                'Proposal review is temporarily unavailable. '
                'Please apply the latest database update.',
              ),
            ),
          );
        }
        return;
      }
      if (sheetContext.mounted) Navigator.pop(sheetContext);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accept ? 'Activity added to the timeline.' : 'Proposal rejected.',
            ),
          ),
        );
      }
    } catch (error) {
      if (sheetContext.mounted) {
        ScaffoldMessenger.of(
          sheetContext,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _pickAndAddDay(List<DateTime> existingDays) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(today.year + 10, 12, 31);
    var initialDate = today;
    while (existingDays.any((day) => _sameDay(day, initialDate)) &&
        initialDate.isBefore(lastDate)) {
      initialDate = initialDate.add(const Duration(days: 1));
    }
    if (existingDays.any((day) => _sameDay(day, initialDate))) {
      _showDayError('No additional itinerary dates are available.');
      return;
    }

    final selected = await showDatePicker(
      context: context,
      helpText: 'Select itinerary date',
      cancelText: 'Cancel',
      confirmText: 'Add day',
      initialDate: initialDate,
      firstDate: today,
      lastDate: lastDate,
      selectableDayPredicate: (date) =>
          !existingDays.any((day) => _sameDay(day, date)),
    );
    if (selected == null || !mounted) return;

    final selectedDay = DateTime(selected.year, selected.month, selected.day);
    if (selectedDay.isBefore(today)) {
      _showDayError('Past dates cannot be added to the trip schedule.');
      return;
    }
    if (existingDays.any((day) => _sameDay(day, selectedDay))) {
      _showDayError('${_monthDay(selectedDay)} is already in the itinerary.');
      return;
    }

    try {
      await _viewModel.addTimelineDay(selectedDay);
      if (!mounted) return;
      setState(() {
        _locallyDeletedDays.removeWhere(
          (deleted) => _sameDay(deleted, selectedDay),
        );
        _pendingDay = selectedDay;
        _selectedDate = selectedDay;
      });
    } catch (error) {
      if (mounted) _showDayError('$error');
    }
  }

  Future<void> _confirmDeleteDay({
    required List<DateTime> days,
    required int selectedIndex,
  }) async {
    final day = days[selectedIndex];
    final dayNumber = selectedIndex + 1;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Day?'),
        content: Text(
          'Are you sure you want to delete Day $dayNumber '
          '(${_monthDay(day)})? All activities scheduled for this day will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingDay = true);
    try {
      final deletedActivities = await _viewModel.deleteTimelineDay(day);
      if (!mounted) return;
      final remainingDays = days
          .where((candidate) => !_sameDay(candidate, day))
          .toList(growable: false);
      final adjacentDay = remainingDays.isEmpty
          ? null
          : selectedIndex > 0
          ? remainingDays[selectedIndex - 1]
          : remainingDays.first;
      setState(() {
        if (!_locallyDeletedDays.any((deleted) => _sameDay(deleted, day))) {
          _locallyDeletedDays.add(day);
        }
        if (_pendingDay != null && _sameDay(_pendingDay!, day)) {
          _pendingDay = null;
        }
        _selectedDate = adjacentDay;
        _deletingDay = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            deletedActivities == 0
                ? 'Day $dayNumber was deleted.'
                : 'Day $dayNumber and $deletedActivities '
                      '${deletedActivities == 1 ? 'activity' : 'activities'} were deleted.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _deletingDay = false);
      _showDayError('Could not delete the day: $error');
    }
  }

  void _showDayError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _TimelinePollCard extends ConsumerWidget {
  const _TimelinePollCard({required this.state, required this.poll});

  final GroupCollaborationState state;
  final ActivityPoll poll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(
      groupCollaborationViewModelProvider(state.tripId).notifier,
    );
    final totalVotes = poll.options.fold<int>(
      0,
      (total, option) => total + option.voterIds.length,
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.how_to_vote_outlined, size: 19),
                SizedBox(width: 7),
                Text(
                  'Group vote',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              poll.question,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ...poll.options.map((option) {
              final selected = option.voterIds.contains(state.currentUserId);
              final percentage = totalVotes == 0
                  ? 0.0
                  : option.voterIds.length / totalVotes;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _runWorkspaceAction(
                    context,
                    () => viewModel.castVote(poll.id, option.id),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              selected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              size: 19,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(option.label)),
                            Text('${option.voterIds.length}'),
                          ],
                        ),
                        const SizedBox(height: 7),
                        LinearProgressIndicator(
                          value: percentage,
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            Text(
              '$totalVotes ${totalVotes == 1 ? 'vote' : 'votes'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineActivityItem extends ConsumerWidget {
  const _TimelineActivityItem({
    required this.state,
    required this.activity,
    required this.isLast,
  });

  final GroupCollaborationState state;
  final TripActivity activity;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(
      groupCollaborationViewModelProvider(state.tripId).notifier,
    );
    const accent = Color(0xFF7C3AED);
    final creator = state.members
        .where((member) => member.userId == state.creatorId)
        .firstOrNull;
    final organizer = creator?.displayName ?? 'Trip organiser';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                const SizedBox(height: 18),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      color: const Color(0xFFD8CFF0),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: activity.isPinned
                    ? const BorderSide(color: Color(0xFF7C3AED), width: 1.5)
                    : BorderSide(color: Theme.of(context).dividerColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Spacer(),
                        _TimelinePill(
                          label: _clockTime(activity.startTime),
                          foreground: const Color(0xFF7C3AED),
                          background: const Color(0xFFF4EFFF),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            activity.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (activity.location?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16),
                          const SizedBox(width: 4),
                          Expanded(child: Text(activity.location!)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'Enjoy ${activity.title} as part of the group itinerary.',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 13,
                          child: Text(
                            _initials(organizer),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Organised by $organizer')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (state.canManageMembers)
                          _TimelineAction(
                            icon: Icons.edit_outlined,
                            label: 'Edit',
                            onTap: () => _showEditActivityDialog(
                              context,
                              activity,
                              viewModel,
                            ),
                          ),
                        _TimelineAction(
                          icon: Icons.share_outlined,
                          label: 'Share',
                          onTap: () => _showActivityShareSheet(
                            context,
                            state,
                            activity,
                            viewModel,
                          ),
                        ),
                        if (state.canManageMembers)
                          _TimelineAction(
                            icon: activity.isPinned
                                ? Icons.push_pin
                                : Icons.push_pin_outlined,
                            label: 'Pin',
                            onTap: () => _runWorkspaceAction(
                              context,
                              () => viewModel.togglePin(activity),
                            ),
                          ),
                        if (state.canManageMembers)
                          _TimelineAction(
                            icon: Icons.delete_outline,
                            label: 'Remove',
                            foreground: Colors.red,
                            onTap: () => _confirmDeleteActivity(
                              context,
                              activity,
                              viewModel,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmDeleteActivity(
  BuildContext context,
  TripActivity activity,
  GroupCollaborationViewModel viewModel,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Remove Activity?'),
      content: Text('Are you sure you want to delete ${activity.title}?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await _runWorkspaceAction(
      context,
      () => viewModel.deleteActivity(activity),
    );
  }
}

Future<void> _showActivityShareSheet(
  BuildContext context,
  GroupCollaborationState state,
  TripActivity activity,
  GroupCollaborationViewModel viewModel,
) async {
  final link =
      'https://gobuddy.app/trips/${state.tripId}/activities/${activity.id}';
  final summary =
      '${activity.title}\n'
      '${_monthDay(activity.startTime)} at ${_clockTime(activity.startTime)}\n'
      '${activity.location ?? 'Location to be confirmed'}\n$link';
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Wrap(
        children: [
          const ListTile(
            title: Text(
              'Share activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text('Share to Group Chat'),
            subtitle: const Text('Post an activity preview for trip members.'),
            onTap: () async {
              Navigator.pop(sheetContext);
              await _runWorkspaceAction(
                context,
                () => viewModel.shareActivityToChat(activity),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.ios_share_outlined),
            title: const Text('Share via External Apps'),
            subtitle: const Text('WhatsApp, email, SMS and more.'),
            onTap: () async {
              Navigator.pop(sheetContext);
              await Share.share(summary, subject: activity.title);
            },
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Copy Link'),
            subtitle: const Text('Copy a view-only activity link.'),
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: link));
              if (!sheetContext.mounted) return;
              Navigator.pop(sheetContext);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Activity link copied.')),
                );
              }
            },
          ),
        ],
      ),
    ),
  );
}

class _TimelinePill extends StatelessWidget {
  const _TimelinePill({
    required this.label,
    required this.foreground,
    required this.background,
  });
  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: foreground,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _TimelineAction extends StatelessWidget {
  const _TimelineAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.foreground,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? foreground;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
          foregroundColor: foreground,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    ),
  );
}

bool _sameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

String _monthDay(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

String _tripDateMetadata(GroupCollaborationState state) {
  final start = state.tripStartDate;
  final end = state.tripEndDate;
  if (start == null && end == null) return 'Trip schedule';
  if (start == null) return _fullDate(end!);
  if (end == null || _sameDay(start, end)) return _fullDate(start);
  return '${_monthDay(start)} – ${_fullDate(end)}';
}

String _fullDate(DateTime date) => '${_monthDay(date)}, ${date.year}';

String _clockTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${date.hour < 12 ? 'AM' : 'PM'}';
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}

class _TimelineTab extends ConsumerWidget {
  const _TimelineTab({required this.state});
  final GroupCollaborationState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(
      groupCollaborationViewModelProvider(state.tripId).notifier,
    );
    final activities = [...state.activities]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final days = <DateTime>[...state.timelineDays];
    for (final activity in activities) {
      final day = DateTime(
        activity.startTime.year,
        activity.startTime.month,
        activity.startTime.day,
      );
      if (!days.contains(day)) days.add(day);
    }
    days.sort();
    if (days.isEmpty) {
      final now = DateTime.now();
      days.add(DateTime(now.year, now.month, now.day));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Timeline', style: Theme.of(context).textTheme.headlineSmall),
        Text('${state.activities.length} planned activities'),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trip days',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Add another day to your itinerary.'),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _runWorkspaceAction(
                    context,
                    () => viewModel.addTimelineDay(
                      days.last.add(const Duration(days: 1)),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Day'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final day = days[index];
              return Container(
                width: 88,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: index == 0
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      'Day ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(_weekday(day)),
                    Text(_calendarDate(day)),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => ActivityProposalDialog(
                onPropose: (title, location, time) => viewModel.proposeActivity(
                  title: title,
                  location: location,
                  startTime: DateTime(
                    days.last.year,
                    days.last.month,
                    days.last.day,
                    time.hour,
                    time.minute,
                  ),
                ),
                onCreatePoll: (question, options) => viewModel
                    .createActivityPoll(question: question, options: options),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add Activity'),
          ),
        ),
        const SizedBox(height: 16),
        if (activities.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 48, bottom: 48),
            child: Center(
              child: Text('No activities yet. Tap Add to create one.'),
            ),
          ),
        ...activities.map(
          (activity) => Card(
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: activity.isPinned
                  ? BorderSide(color: Theme.of(context).colorScheme.primary)
                  : BorderSide.none,
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: Icon(
                    Icons.circle,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    activity.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${_weekday(activity.startTime)}, ${_calendarDate(activity.startTime)} at ${_shortTime(activity.startTime)}${activity.location?.trim().isNotEmpty == true ? '\n${activity.location}' : ''}\n${state.comments.where((comment) => comment.activityId == activity.id).length} comment(s) · ${_rsvpSummary(state, activity.id)}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    tooltip: 'RSVP',
                    onSelected: (action) {
                      switch (action) {
                        case 'going':
                        case 'maybe':
                        case 'not_going':
                          _runWorkspaceAction(
                            context,
                            () => viewModel.setActivityRsvp(
                              activityId: activity.id,
                              status: action,
                            ),
                          );
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'going',
                        child: Text('RSVP: Going'),
                      ),
                      const PopupMenuItem(
                        value: 'maybe',
                        child: Text('RSVP: Maybe'),
                      ),
                      const PopupMenuItem(
                        value: 'not_going',
                        child: Text('RSVP: Not going'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () =>
                            _showComments(context, state, activity, viewModel),
                        icon: const Icon(Icons.comment_outlined, size: 16),
                        label: const Text('Comment'),
                      ),
                      if (state.canManageMembers)
                        OutlinedButton.icon(
                          onPressed: () => _showEditActivityDialog(
                            context,
                            activity,
                            viewModel,
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit'),
                        ),
                      OutlinedButton.icon(
                        onPressed: () => _runWorkspaceAction(
                          context,
                          () => viewModel.togglePin(activity),
                        ),
                        icon: Icon(
                          activity.isPinned
                              ? Icons.push_pin
                              : Icons.push_pin_outlined,
                          size: 16,
                        ),
                        label: Text(activity.isPinned ? 'Pinned' : 'Pin'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Text(
          'Activity Polls',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        ...state.polls.map(
          (poll) => Card(
            child: Column(
              children: poll.options
                  .map(
                    (option) => ListTile(
                      title: Text(option.label),
                      subtitle: Text('${option.voterIds.length} votes'),
                      trailing: FilledButton(
                        onPressed: () => viewModel.castVote(poll.id, option.id),
                        child: const Text('Vote'),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

void _showNotifications(
  BuildContext context,
  List<CollaborationNotification> notifications,
) {
  showModalBottomSheet<void>(
    context: context,
    builder: (_) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Live collaboration updates',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (notifications.isEmpty)
            const ListTile(title: Text('No updates yet.')),
          ...notifications.map(
            (item) => ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: Text(item.summary),
              subtitle: Text(item.createdAt.toString()),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showComments(
  BuildContext context,
  GroupCollaborationState state,
  TripActivity activity,
  GroupCollaborationViewModel viewModel,
) async {
  final controller = TextEditingController();
  final comments = state.comments
      .where((comment) => comment.activityId == activity.id)
      .toList();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.viewInsetsOf(sheetContext).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comments: ${activity.title}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (comments.isEmpty) const Text('No comments yet.'),
          ...comments.map(
            (comment) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline),
              title: Text(comment.body),
              subtitle: Text(comment.createdAt.toString()),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(hintText: 'Add a comment'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () async {
                  await viewModel.addActivityComment(
                    activityId: activity.id,
                    body: controller.text,
                  );
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
              ),
            ],
          ),
        ],
      ),
    ),
  );
  controller.dispose();
}

Future<void> _showEditActivityDialog(
  BuildContext context,
  TripActivity activity,
  GroupCollaborationViewModel viewModel,
) async {
  final titleController = TextEditingController(text: activity.title);
  final locationController = TextEditingController(
    text: activity.location ?? '',
  );
  var submitting = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: const Text('Edit activity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Activity title'),
            ),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            const SizedBox(height: 12),
            Text('Time: ${_shortDate(activity.startTime)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: submitting ? null : () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: submitting
                ? null
                : () async {
                    setDialogState(() => submitting = true);
                    try {
                      await viewModel.editActivity(
                        activity: activity,
                        title: titleController.text.trim(),
                        startTime: activity.startTime,
                        location: locationController.text.trim().isEmpty
                            ? null
                            : locationController.text.trim(),
                      );
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    } catch (error) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(
                          dialogContext,
                        ).showSnackBar(SnackBar(content: Text('$error')));
                      }
                    } finally {
                      if (dialogContext.mounted) {
                        setDialogState(() => submitting = false);
                      }
                    }
                  },
            child: Text(submitting ? 'Saving...' : 'Save changes'),
          ),
        ],
      ),
    ),
  );
  titleController.dispose();
  locationController.dispose();
}

class _FilesTab extends ConsumerWidget {
  const _FilesTab({required this.state});
  final GroupCollaborationState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(
      groupCollaborationViewModelProvider(state.tripId).notifier,
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: viewModel.pickAndShareFile,
          icon: const Icon(Icons.upload_file),
          label: const Text('Share files'),
        ),
        ...state.files.map(
          (file) => ListTile(
            title: Text(file.name),
            subtitle: Text(
              '${file.uploadedBy == state.currentUserId ? 'You' : (file.uploadedByName ?? 'Trip member')} · ${_shortDate(file.createdAt)} · ${_fileSize(file.sizeBytes)}',
            ),
            trailing: Wrap(
              children: [
                IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () => launchUrl(
                    Uri.parse(file.url),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                if (file.uploadedBy == state.currentUserId ||
                    state.canManageMembers)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete file',
                    onPressed: () => _confirmMemberAction(
                      context: context,
                      title: 'Delete file?',
                      message:
                          '${file.name} will no longer be available to the group.',
                      confirmLabel: 'Delete',
                      isDestructive: true,
                      onConfirm: () => viewModel.deleteFile(file),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CallsTab extends ConsumerWidget {
  const _CallsTab({required this.state});

  final GroupCollaborationState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(
      groupCollaborationViewModelProvider(state.tripId).notifier,
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Call history',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text('Join active in-app voice and video calls.'),
        const SizedBox(height: 12),
        if (state.calls.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.call_outlined),
              title: Text('No calls yet'),
              subtitle: Text('Start a voice or video call from the top bar.'),
            ),
          ),
        ...state.calls.map(
          (call) => Card(
            child: ListTile(
              leading: Icon(call.isVideo ? Icons.videocam : Icons.call),
              title: Text('${call.isVideo ? 'Video' : 'Voice'} call'),
              subtitle: Text(
                '${call.initiatedBy == state.currentUserId ? 'You' : (call.initiatedByName ?? 'Trip member')} · ${_shortDate(call.createdAt)} · ${call.status}',
              ),
              trailing: Wrap(
                children: [
                  FilledButton(
                    onPressed: call.status == 'ended'
                        ? null
                        : () => _openInAppCall(
                            context,
                            state,
                            call.callType,
                            () => viewModel.joinCall(call),
                            viewModel,
                          ),
                    child: Text(call.status == 'ended' ? 'Ended' : 'Join'),
                  ),
                  if (call.initiatedBy == state.currentUserId ||
                      state.canManageMembers)
                    IconButton(
                      tooltip: 'End call',
                      onPressed: call.status == 'ended'
                          ? null
                          : () => _confirmMemberAction(
                              context: context,
                              title: 'End call?',
                              message:
                                  'This marks the call as ended in group history.',
                              confirmLabel: 'End call',
                              isDestructive: true,
                              onConfirm: () => viewModel.endCall(call),
                            ),
                      icon: const Icon(Icons.call_end),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: const TextStyle(fontSize: 12)),
  );
}

Future<void> _confirmMemberAction({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  required Future<void> Function() onConfirm,
  bool isDestructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: isDestructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.error,
                )
              : null,
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await _runWorkspaceAction(context, onConfirm);
  }
}

Future<void> _runWorkspaceAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}

Future<void> _openInAppCall(
  BuildContext context,
  GroupCollaborationState state,
  String callType,
  Future<TripCall?> Function() action,
  GroupCollaborationViewModel viewModel,
) async {
  try {
    await const AppPermissionService().requireCallPermissions(
      withVideo: callType == 'video',
    );
    final call = await action();
    if (call == null || !context.mounted) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    final closed = Completer<void>();
    late final OverlayEntry callEntry;
    var removed = false;
    void closeCallOverlay() {
      if (removed) return;
      removed = true;
      callEntry.remove();
      callEntry.dispose();
      if (!closed.isCompleted) closed.complete();
    }

    callEntry = OverlayEntry(
      builder: (_) => CallScreen(
        tripId: state.tripId,
        call: call,
        currentUserId: state.currentUserId,
        displayName: _currentMemberName(state),
        onClose: closeCallOverlay,
        onVideoEnabled: () => viewModel.markCallVideoUsed(call),
        onCallEnded: (details) => viewModel.leaveCall(
          call,
          reason: details.reason.name,
          hadVideo: details.hadVideo,
          duration: details.duration,
        ),
      ),
    );
    overlay.insert(callEntry);
    await closed.future;
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}

TripCall? _activeCall(GroupCollaborationState state) {
  final activeCalls =
      state.calls.where((call) => call.status != 'ended').toList()
        ..sort((first, second) => second.createdAt.compareTo(first.createdAt));
  return activeCalls.firstOrNull;
}

String _currentMemberName(GroupCollaborationState state) =>
    state.members
        .where((member) => member.userId == state.currentUserId)
        .map((member) => member.displayName?.trim())
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .firstOrNull ??
    'GoBuddy member';

String _shortDate(DateTime value) =>
    '${value.day}/${value.month}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _calendarDate(DateTime value) => '${value.day}/${value.month}';

String _weekday(DateTime value) => const [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
][value.weekday - 1];

String _shortTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _rsvpSummary(GroupCollaborationState state, String activityId) {
  final rsvps = state.rsvps.where((rsvp) => rsvp.activityId == activityId);
  final going = rsvps.where((rsvp) => rsvp.status == 'going').length;
  final maybe = rsvps.where((rsvp) => rsvp.status == 'maybe').length;
  final notGoing = rsvps.where((rsvp) => rsvp.status == 'not_going').length;
  return '$going going · $maybe maybe · $notGoing not going';
}

String _fileSize(int? bytes) {
  if (bytes == null) return 'size unavailable';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
