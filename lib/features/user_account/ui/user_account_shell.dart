import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/routing/routes.dart';
import '../../common/ui/widgets/app_module_navigation.dart';
import '../../matchmaking/ui/matchmaking_shell_screen.dart';
import '../../matchmaking/ui/matchmaking_view_model.dart';
import '../../travel_footprint/repository/travel_footprint_repository.dart';
import '../model/user_account_model.dart';
import '../repository/user_account_repository.dart';
import 'edit_profile_view.dart';
import 'view_model/user_account_view_model.dart';

// ==========================================================================
// 🎨 Core Style Tokens (Sourced directly from the base fork design specs)
// ==========================================================================
const _ink = Color(0xFF281950);
const _violet = Color(0xFF7C3AED);
const _border = Color(0xFFD5CFEF);
const _muted = Color(0xFF686082);
const _bgSubtle = Color(0xFFF7F5FB);
const _surface = Colors.white;

const _heading = TextStyle(
  fontFamily: 'Georgia',
  color: _ink,
  fontSize: 24,
  fontWeight: FontWeight.w600,
  letterSpacing: -.6,
);

const _label = TextStyle(
  color: _muted,
  fontSize: 11,
  fontWeight: FontWeight.w700,
  letterSpacing: .5,
);

BoxDecoration _cardDecoration({double radius = 16, bool feed = false}) =>
    BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _border),
      boxShadow: [
        BoxShadow(
          color: (feed ? _ink : Colors.black).withValues(
            alpha: feed ? .12 : .08,
          ),
          blurRadius: feed ? 40 : 25,
          offset: feed ? const Offset(0, 8) : const Offset(0, 2),
        ),
      ],
    );

// ==========================================================================
// 🛡️ Main Module Screen Container
// ==========================================================================
class UserAccountScreen extends ConsumerStatefulWidget {
  const UserAccountScreen({super.key});

  @override
  ConsumerState<UserAccountScreen> createState() => _UserAccountScreenState();
}

class _UserAccountScreenState extends ConsumerState<UserAccountScreen>
    with WidgetsBindingObserver {
  Timer? _verificationTimer;
  bool _isForeground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _verificationTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_isForeground &&
          ref.read(userAccountViewModelProvider).user?.verificationStatus ==
              IdentityVerificationStatus.pending) {
        ref
            .read(userAccountViewModelProvider.notifier)
            .refreshVerificationStatus();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // The account sub-pages are held in a long-lived provider. Reset only
        // after the first frame because Riverpod forbids provider mutations
        // while the widget tree is being built.
        final viewModel = ref.read(userAccountViewModelProvider.notifier);
        viewModel.goTo(UserAccountPage.profile);
        viewModel.refresh();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.resumed) {
      ref
          .read(userAccountViewModelProvider.notifier)
          .refreshVerificationStatus();
    }
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(userAccountViewModelProvider, (previous, next) {
      if (next.error == null || next.error == previous?.error) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(next.error!)));
    });
    final state = ref.watch(userAccountViewModelProvider);
    final viewModel = ref.read(userAccountViewModelProvider.notifier);
    final matchmakingState = ref.watch(matchmakingViewModelProvider);
    final matchmakingViewModel = ref.read(
      matchmakingViewModelProvider.notifier,
    );

    final Widget body;
    if (state.isLoading && state.user == null) {
      body = const Center(child: CircularProgressIndicator(color: _violet));
    } else if (state.user == null) {
      body = _AccountErrorView(
        message: state.error ?? 'Your profile is not available.',
        onRetry: viewModel.refresh,
      );
    } else {
      body = switch (state.page) {
        UserAccountPage.profile => _AccountDashboardView(
          user: state.user!,
          onNavigate: viewModel.goTo,
          onRefresh: viewModel.refresh,
          onVerify: () => context.push(Routes.identityVerification),
          unreadNotificationCount: matchmakingState.unreadNotificationCount,
          onEditPhoto: (source) => viewModel.addGalleryImage(source: source),
          onDeletePhotos: viewModel.deleteGalleryImages,
          onEditBackgroundPhoto: (source) =>
              viewModel.selectBackgroundImage(source: source),
          onDeleteBackgroundPhoto: viewModel.deleteBackgroundImage,
          onNotifications: () async {
            await showDialog<void>(
              context: context,
              builder: (context) => MatchmakingNotificationsDialog(
                notifications: matchmakingState.notifications,
              ),
            );
            await matchmakingViewModel.markNotificationsRead();
          },
        ),
        UserAccountPage.editProfile => EditProfileView(
          user: state.user!,
          isSaving: state.isLoading,
          onBack: () => viewModel.goTo(UserAccountPage.profile),
          onSave: viewModel.updateProfile,
          onSelectImage: (source) =>
              viewModel.selectProfileImage(source: source),
          onDeleteImage: viewModel.deleteProfileImage,
        ),
        UserAccountPage.security => _AccountStaticFrame(
          title: 'Security',
          subtitle: 'ACCESS MANAGEMENT',
          description:
              'Manage active authorization keys, session duration thresholds, and multi-factor validation credentials.',
          onBack: () => viewModel.goTo(UserAccountPage.profile),
        ),
      };
    }

    final isAccountDashboard = state.page == UserAccountPage.profile;
    return PopScope(
      canPop: isAccountDashboard,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) viewModel.goTo(UserAccountPage.profile);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F5FB),
        body: SafeArea(child: body),
        bottomNavigationBar: isAccountDashboard
            ? const AppModuleNavigation(selectedIndex: 4)
            : null,
      ),
    );
  }
}

// ==========================================================================
// 👤 Sub-View: Main Profile Dashboard
// ==========================================================================
class _AccountErrorView extends StatelessWidget {
  const _AccountErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_off_outlined, color: _muted, size: 42),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, height: 1.5),
          ),
          const SizedBox(height: 18),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

class _AccountDashboardView extends StatelessWidget {
  final UserAccount user;
  final ValueChanged<UserAccountPage> onNavigate;
  final Future<void> Function() onRefresh;
  final VoidCallback onVerify;
  final int unreadNotificationCount;
  final Future<void> Function() onNotifications;
  final Future<String?> Function(ImageSource source) onEditPhoto;
  final Future<bool> Function(List<String> photos) onDeletePhotos;
  final Future<String?> Function(ImageSource source) onEditBackgroundPhoto;
  final Future<bool> Function() onDeleteBackgroundPhoto;

  const _AccountDashboardView({
    required this.user,
    required this.onNavigate,
    required this.onRefresh,
    required this.onVerify,
    required this.unreadNotificationCount,
    required this.onNotifications,
    required this.onEditPhoto,
    required this.onDeletePhotos,
    required this.onEditBackgroundPhoto,
    required this.onDeleteBackgroundPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _ProfileHeader(
            user: user,
            onBack: () =>
                context.canPop() ? context.pop() : context.go(Routes.main),
            unreadNotificationCount: unreadNotificationCount,
            onNotifications: onNotifications,
            onSettings: () => context.push(Routes.settings),
            onEditBackgroundPhoto: onEditBackgroundPhoto,
            onDeleteBackgroundPhoto: onDeleteBackgroundPhoto,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _ProfileStatsCard(
              onEdit: () => onNavigate(UserAccountPage.editProfile),
              verificationStatus: user.verificationStatus,
              onVerify: onVerify,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _ProfileAboutCard(
              bio: user.bio,
              isReadOnly: true,
              onEdit: () {},
            ),
          ),
          if (user.isVerified) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _AccountMenuTile(
                icon: Icons.favorite_outline,
                title: 'Saved Trips',
                onTap: () => context.push(Routes.savedTrips),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _AccountMenuTile(
                icon: Icons.health_and_safety_outlined,
                title: 'Emergency contacts',
                onTap: () => context.push(Routes.emergencyContacts),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _ProfilePhotosCard(
              photos: user.galleryPhotos,
              onEdit: onEditPhoto,
              onDelete: onDeletePhotos,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatefulWidget {
  final UserAccount user;
  final VoidCallback onBack;
  final VoidCallback onSettings;
  final int unreadNotificationCount;
  final Future<void> Function() onNotifications;
  final Future<String?> Function(ImageSource source) onEditBackgroundPhoto;
  final Future<bool> Function() onDeleteBackgroundPhoto;
  final bool isReadOnly;

  const _ProfileHeader({
    required this.user,
    required this.onBack,
    required this.onSettings,
    required this.unreadNotificationCount,
    required this.onNotifications,
    required this.onEditBackgroundPhoto,
    required this.onDeleteBackgroundPhoto,
    this.isReadOnly = false,
  });

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class PublicUserProfileScreen extends StatefulWidget {
  const PublicUserProfileScreen({required this.userId, super.key});

  final String userId;

  @override
  State<PublicUserProfileScreen> createState() =>
      _PublicUserProfileScreenState();
}

class _PublicUserProfileScreenState extends State<PublicUserProfileScreen> {
  late Future<UserAccount> _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _profile = const UserAccountRepository().fetchPublicAccount(widget.userId);
  }

  Future<void> _retry() async {
    setState(_load);
    await _profile;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bgSubtle,
    body: SafeArea(
      child: FutureBuilder<UserAccount>(
        future: _profile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _violet),
            );
          }
          if (!snapshot.hasData) {
            final error = snapshot.error;
            return _AccountErrorView(
              message: error is UserAccountLoadException
                  ? error.message
                  : 'Unable to load this profile. Please try again.',
              onRetry: _retry,
            );
          }

          final user = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _retry,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                _ProfileHeader(
                  user: user,
                  onBack: () => context.pop(),
                  isReadOnly: true,
                  unreadNotificationCount: 0,
                  onNotifications: () async {},
                  onSettings: () {},
                  onEditBackgroundPhoto: (_) async => null,
                  onDeleteBackgroundPhoto: () async => false,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _ProfilePhotosCard(
                    photos: user.galleryPhotos,
                    isReadOnly: true,
                    onEdit: (_) async => null,
                    onDelete: (_) async => false,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _ProfileAboutCard(
                    bio: user.bio,
                    isReadOnly: true,
                    onEdit: () {},
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  bool _isBackgroundExpanded = false;
  ScrollPosition? _scrollPosition;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (identical(position, _scrollPosition)) return;
    _scrollPosition?.removeListener(_handleScroll);
    _scrollPosition = position;
    _scrollPosition?.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (_isBackgroundExpanded && (_scrollPosition?.pixels ?? 0) > 0) {
      setState(() => _isBackgroundExpanded = false);
    }
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_handleScroll);
    super.dispose();
  }

  Future<void> _onBackgroundTap() async {
    if (!_isBackgroundExpanded) {
      setState(() => _isBackgroundExpanded = true);
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _BackgroundPhotoViewer(
          photo: widget.user.backgroundPhoto,
          onEdit: widget.isReadOnly ? null : widget.onEditBackgroundPhoto,
          onDelete: widget.isReadOnly ? null : widget.onDeleteBackgroundPhoto,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final expandedSize = screenSize.shortestSide;
    final backgroundHeight = _isBackgroundExpanded ? expandedSize : 285.0;
    final avatarTop = backgroundHeight - 80;
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: backgroundHeight + 125,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              height: backgroundHeight,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Semantics(
                    button: true,
                    label: _isBackgroundExpanded
                        ? 'Open background photo full screen'
                        : 'Expand background photo',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _onBackgroundTap,
                      child: Image(
                        image: _accountImageProvider(
                          widget.user.backgroundPhoto,
                          fallback: _coverPhotoUrl,
                        ),
                        fit: _isBackgroundExpanded
                            ? BoxFit.contain
                            : BoxFit.cover,
                        width: double.infinity,
                        height: backgroundHeight,
                      ),
                    ),
                  ),
                  const IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x99281950)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    left: 16,
                    child: _FrostedIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: widget.onBack,
                    ),
                  ),
                  if (!widget.isReadOnly) ...[
                    Positioned(
                      top: 14,
                      right: 62,
                      child: _FrostedIconButton(
                        icon: Icons.notifications_none_rounded,
                        badgeCount: widget.unreadNotificationCount,
                        onTap: widget.onNotifications,
                      ),
                    ),
                    Positioned(
                      top: 14,
                      right: 16,
                      child: _FrostedIconButton(
                        icon: Icons.settings_outlined,
                        onTap: widget.onSettings,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              top: avatarTop,
              left: 0,
              right: 0,
              child: Center(
                child: Semantics(
                  button: true,
                  label: 'View profile photo',
                  child: GestureDetector(
                    onTap: () => _showProfilePhotoPreview(
                      context,
                      widget.user.profilePhoto,
                    ),
                    child: Container(
                      width: 112,
                      height: 112,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0x59FFFFFF),
                          width: 3,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: _violet,
                            blurRadius: 0,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image(
                          image: _accountImageProvider(
                            widget.user.profilePhoto,
                            fallback: 'assets/images/defaultProfileImage.jpg',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: backgroundHeight + 45,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _profileDisplayName(widget.user),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 30,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.5,
                          ),
                        ),
                      ),
                      if (widget.user.isVerified) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.verified_rounded,
                          color: _violet,
                          size: 23,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _profileSummary(widget.user),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStatsCard extends ConsumerWidget {
  final VoidCallback onEdit;
  final IdentityVerificationStatus verificationStatus;
  final VoidCallback onVerify;

  const _ProfileStatsCard({
    required this.onEdit,
    required this.verificationStatus,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    padding: const EdgeInsets.all(18),
    decoration: _cardDecoration(),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => context.push(Routes.travelFootprint),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: _ProfileStat(
                    number: ref
                        .watch(travelFootprintProvider)
                        .maybeWhen(
                          data: (value) => '${value.cityCount}',
                          orElse: () => '—',
                        ),
                    label: 'CITIES VISITED',
                    showChevron: true,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: onEdit,
            style: FilledButton.styleFrom(
              backgroundColor: _violet,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            child: const Text(
              'Edit Profile',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        if (verificationStatus != IdentityVerificationStatus.verified) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: onVerify,
              icon: const Icon(Icons.verified_user_outlined),
              label: Text(
                verificationStatus == IdentityVerificationStatus.pending
                    ? 'Verification Pending'
                    : 'Verify Identity',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _violet,
                side: const BorderSide(color: _violet),
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _ProfileStat extends StatelessWidget {
  final String number;
  final String label;
  final bool showChevron;
  const _ProfileStat({
    required this.number,
    required this.label,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        number,
        style: const TextStyle(
          fontFamily: 'Georgia',
          fontSize: 22,
          color: _ink,
          fontWeight: FontWeight.w600,
        ),
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: _label),
          if (showChevron)
            const Icon(Icons.chevron_right_rounded, size: 17, color: _violet),
        ],
      ),
    ],
  );
}

class _AccountMenuTile extends StatelessWidget {
  const _AccountMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Icon(icon, color: _violet),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _muted),
          ],
        ),
      ),
    ),
  );
}

class _ProfilePhotosCard extends StatelessWidget {
  const _ProfilePhotosCard({
    required this.photos,
    required this.onEdit,
    required this.onDelete,
    this.isReadOnly = false,
  });

  final List<String> photos;
  final Future<String?> Function(ImageSource source) onEdit;
  final Future<bool> Function(List<String> photos) onDelete;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    final visiblePhotos = photos.take(3).toList(growable: false);
    final hiddenPhotoCount = photos.length > 3 ? photos.length - 2 : 0;

    return _ProfileCard(
      title: 'Photos',
      edit: !isReadOnly,
      onEdit: () => _showPhotoActions(context),
      child: photos.isEmpty
          ? const Text(
              'No travel photos added yet.',
              style: TextStyle(color: _muted, height: 1.6),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 10.0;
                final tileSize = constraints.maxWidth.isFinite
                    ? ((constraints.maxWidth - spacing * 2) / 3)
                          .clamp(0.0, 104.0)
                          .toDouble()
                    : 104.0;

                return Row(
                  children: [
                    for (
                      var index = 0;
                      index < visiblePhotos.length;
                      index++
                    ) ...[
                      if (index > 0) const SizedBox(width: spacing),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Semantics(
                          button: true,
                          label: index == 2 && hiddenPhotoCount > 0
                              ? 'View all ${photos.length} photos'
                              : 'Open photo ${index + 1} full screen',
                          child: GestureDetector(
                            onTap: index == 2 && hiddenPhotoCount > 0
                                ? () => _openGallery(context)
                                : () => _openPhotoViewer(context, index),
                            child: SizedBox.square(
                              dimension: tileSize,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image(
                                    image: _accountImageProvider(
                                      visiblePhotos[index],
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                  if (index == 2 && hiddenPhotoCount > 0) ...[
                                    ColoredBox(
                                      color: Colors.black.withValues(
                                        alpha: .52,
                                      ),
                                    ),
                                    Center(
                                      child: Text(
                                        '+$hiddenPhotoCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
    );
  }

  void _openGallery(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _UserPhotoGalleryScreen(photos: photos),
      ),
    );
  }

  void _openPhotoViewer(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            _FullScreenPhotoViewer(photos: photos, initialIndex: initialIndex),
      ),
    );
  }

  Future<void> _showPhotoActions(BuildContext context) async {
    final action = await showModalBottomSheet<_PhotoAction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Manage photos',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.add_photo_alternate_outlined),
                title: const Text('Add photo'),
                onTap: () => Navigator.pop(sheetContext, _PhotoAction.addPhoto),
              ),
              ListTile(
                enabled: photos.isNotEmpty,
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete photos'),
                onTap: photos.isEmpty
                    ? null
                    : () => Navigator.pop(
                        sheetContext,
                        _PhotoAction.deletePhotos,
                      ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!context.mounted) return;
    switch (action) {
      case _PhotoAction.addPhoto:
        await _choosePhotoSource(context);
        return;
      case _PhotoAction.deletePhotos:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _UserPhotoGalleryScreen(
              photos: photos,
              selectionMode: true,
              onDelete: onDelete,
            ),
          ),
        );
        return;
      case null:
        return;
    }
  }

  Future<void> _choosePhotoSource(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Add a travel photo',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a photo'),
                subtitle: const Text('Use your device camera'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                subtitle: const Text('Upload an existing photo'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source != null) await onEdit(source);
  }
}

enum _PhotoAction { addPhoto, deletePhotos }

class _UserPhotoGalleryScreen extends StatefulWidget {
  const _UserPhotoGalleryScreen({
    required this.photos,
    this.selectionMode = false,
    this.onDelete,
  }) : assert(!selectionMode || onDelete != null);

  final List<String> photos;
  final bool selectionMode;
  final Future<bool> Function(List<String> photos)? onDelete;

  @override
  State<_UserPhotoGalleryScreen> createState() =>
      _UserPhotoGalleryScreenState();
}

class _UserPhotoGalleryScreenState extends State<_UserPhotoGalleryScreen> {
  final Set<int> _selectedIndexes = {};
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _ink,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.selectionMode && _selectedIndexes.isNotEmpty
              ? '${_selectedIndexes.length} selected'
              : widget.selectionMode
              ? 'Select photos'
              : 'Photos',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedIndexes.contains(index);
          return Semantics(
            button: true,
            image: true,
            selected: widget.selectionMode ? isSelected : null,
            label: widget.selectionMode
                ? 'Photo ${index + 1} of ${photos.length}'
                : 'Open gallery photo ${index + 1} of ${photos.length} full screen',
            child: GestureDetector(
              onTap: () => widget.selectionMode
                  ? _toggleSelection(index)
                  : Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _FullScreenPhotoViewer(
                          photos: photos,
                          initialIndex: index,
                        ),
                      ),
                    ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image(
                      image: _accountImageProvider(photos[index]),
                      fit: BoxFit.cover,
                    ),
                    if (widget.selectionMode) ...[
                      if (isSelected)
                        ColoredBox(color: _violet.withValues(alpha: .22)),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? _violet : Colors.white,
                            border: Border.all(
                              color: isSelected ? Colors.white : _muted,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: widget.selectionMode
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: SizedBox(
                height: 50,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  onPressed: _selectedIndexes.isEmpty || _isDeleting
                      ? null
                      : _deleteSelected,
                  icon: _isDeleting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.delete_outline),
                  label: Text(
                    _isDeleting
                        ? 'Deleting...'
                        : _selectedIndexes.isEmpty
                        ? 'Delete'
                        : 'Delete (${_selectedIndexes.length})',
                  ),
                ),
              ),
            )
          : null,
    );
  }

  void _toggleSelection(int index) {
    if (_isDeleting) return;
    setState(() {
      if (!_selectedIndexes.add(index)) _selectedIndexes.remove(index);
    });
  }

  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete selected photos?'),
        content: Text(
          'This will permanently delete ${_selectedIndexes.length} '
          '${_selectedIndexes.length == 1 ? 'photo' : 'photos'}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final selectedPhotos = _selectedIndexes
        .map((index) => widget.photos[index])
        .toList(growable: false);
    setState(() => _isDeleting = true);
    final deleted = await widget.onDelete!(selectedPhotos);
    if (!mounted) return;
    if (deleted) {
      Navigator.pop(context);
    } else {
      setState(() => _isDeleting = false);
    }
  }
}

class _FullScreenPhotoViewer extends StatefulWidget {
  const _FullScreenPhotoViewer({
    required this.photos,
    required this.initialIndex,
  });

  final List<String> photos;
  final int initialIndex;

  @override
  State<_FullScreenPhotoViewer> createState() => _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<_FullScreenPhotoViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      title: Text('${_currentIndex + 1} of ${widget.photos.length}'),
    ),
    body: PageView.builder(
      controller: _pageController,
      itemCount: widget.photos.length,
      onPageChanged: (index) => setState(() => _currentIndex = index),
      itemBuilder: (context, index) => Semantics(
        image: true,
        label: 'Full-size photo ${index + 1} of ${widget.photos.length}',
        child: Center(
          child: Image(
            image: _accountImageProvider(widget.photos[index]),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.contain,
          ),
        ),
      ),
    ),
  );
}

class _ProfileAboutCard extends StatelessWidget {
  const _ProfileAboutCard({
    required this.bio,
    required this.onEdit,
    this.isReadOnly = false,
  });

  final String bio;
  final VoidCallback onEdit;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) => _ProfileCard(
    title: 'About Me',
    edit: !isReadOnly,
    onEdit: onEdit,
    child: Text(
      bio.isEmpty ? 'Not set' : bio,
      style: const TextStyle(color: _muted, height: 1.7),
    ),
  );
}

class _ProfileCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool edit;
  final VoidCallback? onEdit;

  const _ProfileCard({
    required this.title,
    required this.child,
    this.edit = true,
    this.onEdit,
  }) : assert(!edit || onEdit != null);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: _cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: _ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (edit)
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, color: _violet),
                tooltip: 'Edit $title',
              ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _FrostedIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final int badgeCount;

  const _FrostedIconButton({
    required this.icon,
    this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .15),
    shape: const StadiumBorder(),
    child: InkWell(
      onTap: onTap,
      customBorder: const StadiumBorder(),
      child: SizedBox(
        width: 38,
        height: 38,
        child: Badge(
          isLabelVisible: badgeCount > 0,
          label: Text(badgeCount > 99 ? '99+' : '$badgeCount'),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    ),
  );
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0x337C3AED),
      borderRadius: BorderRadius.circular(99),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified_rounded, size: 13, color: Colors.white),
        SizedBox(width: 3),
        Text(
          'Verified',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

const _coverPhotoUrl =
    'https://images.unsplash.com/photo-1498307833015-e7b400441eb8?auto=format&fit=crop&w=1200&q=85';

// ==========================================================================
// 📝 Sub-View: Edit Account Information Input Form
// ==========================================================================
class _AccountEditView extends StatefulWidget {
  final UserAccount user;
  final bool isSaving;
  final VoidCallback onBack;
  final ValueChanged<UserAccountProfileUpdate> onSave;
  final Future<String?> Function() onSelectImage;
  final VoidCallback onVerify;

  const _AccountEditView({
    required this.user,
    required this.isSaving,
    required this.onBack,
    required this.onSave,
    required this.onSelectImage,
    required this.onVerify,
  });

  @override
  State<_AccountEditView> createState() => _AccountEditViewState();
}

class _AccountEditViewState extends State<_AccountEditView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _nationalityController;
  late final TextEditingController _bioController;
  String? _gender;
  String? _backgroundPhoto;
  String? _profilePhoto;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _nationalityController = TextEditingController(
      text: widget.user.nationality,
    );
    _bioController = TextEditingController(text: widget.user.bio);
    _gender = widget.user.gender;
    _backgroundPhoto = widget.user.backgroundPhoto;
    _profilePhoto = widget.user.profilePhoto;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nationalityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AccountLayoutWrapper(
      title: 'Edit Profile',
      onBack: widget.onBack,
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: _PhotoPicker(
                    label: 'BACKGROUND PHOTO',
                    imagePath: _backgroundPhoto,
                    icon: Icons.landscape_outlined,
                    onTap: widget.isSaving
                        ? null
                        : () => _selectPhoto(isBackground: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PhotoPicker(
                    label: 'PROFILE PHOTO',
                    imagePath: _profilePhoto,
                    icon: Icons.person_outline_rounded,
                    circular: true,
                    onTap: widget.isSaving
                        ? null
                        : () => _selectPhoto(isBackground: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _EditField(
              label: 'USERNAME',
              controller: _usernameController,
              enabled: !widget.isSaving,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Username is required'
                  : null,
            ),
            const SizedBox(height: 18),
            _VerifiedIdentityField(
              label: 'FULL NAME',
              value: widget.user.fullName,
              isVerified: widget.user.isVerified,
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: _editInputDecoration('GENDER'),
              items: const ['Female', 'Male', 'Non-binary', 'Prefer not to say']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: widget.isSaving
                  ? null
                  : (value) => setState(() => _gender = value),
            ),
            const SizedBox(height: 18),
            _VerifiedIdentityField(
              label: 'DATE OF BIRTH',
              value: widget.user.dateOfBirth == null
                  ? null
                  : _formatDate(widget.user.dateOfBirth!),
              isVerified: widget.user.isVerified,
            ),
            const SizedBox(height: 18),
            _EditField(
              label: 'NATIONALITY',
              controller: _nationalityController,
              enabled: !widget.isSaving,
            ),
            const SizedBox(height: 18),
            _EditField(
              label: 'BIO',
              controller: _bioController,
              enabled: !widget.isSaving,
              maxLines: 4,
            ),
            if (!widget.user.isVerified) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: widget.isSaving ? null : widget.onVerify,
                icon: const Icon(Icons.verified_user_outlined),
                label: const Text('Verify Identity'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _violet,
                  minimumSize: const Size.fromHeight(52),
                  side: const BorderSide(color: _border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: widget.isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: _violet,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: widget.isSaving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _selectPhoto({required bool isBackground}) async {
    final path = await widget.onSelectImage();
    if (path == null || !mounted) return;
    setState(() {
      if (isBackground) {
        _backgroundPhoto = path;
      } else {
        _profilePhoto = path;
      }
    });
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSave(
      UserAccountProfileUpdate(
        backgroundPhoto: _backgroundPhoto,
        profilePhoto: _profilePhoto,
        username: _usernameController.text.trim(),
        gender: _gender,
        nationality: _nationalityController.text.trim(),
        bio: _bioController.text.trim(),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.label,
    required this.imagePath,
    required this.icon,
    required this.onTap,
    this.circular = false,
  });

  final String label;
  final String? imagePath;
  final IconData icon;
  final VoidCallback? onTap;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _label),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 112,
            decoration: BoxDecoration(
              color: _bgSubtle,
              shape: circular ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: circular ? null : BorderRadius.circular(16),
              border: Border.all(color: _border),
              image: imagePath == null
                  ? null
                  : DecorationImage(
                      image: _accountImageProvider(imagePath),
                      fit: BoxFit.cover,
                    ),
            ),
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _violet, size: 22),
            ),
          ),
        ),
      ],
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.label,
    required this.controller,
    required this.enabled,
    this.validator,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final String? Function(String?)? validator;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          validator: validator,
          maxLines: maxLines,
          decoration: _editInputDecoration(),
        ),
      ],
    );
  }
}

class _VerifiedIdentityField extends StatelessWidget {
  const _VerifiedIdentityField({
    required this.label,
    required this.value,
    required this.isVerified,
  });

  final String label;
  final String? value;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _label),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            color: _bgSubtle,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  isVerified
                      ? value ?? 'Verified information unavailable'
                      : 'Verify identity to add this information',
                  style: TextStyle(
                    color: isVerified ? _ink : _muted,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isVerified ? Icons.verified_rounded : Icons.lock_outline,
                color: isVerified ? _violet : _muted,
                size: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

InputDecoration _editInputDecoration([String? label]) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: _surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _border),
    ),
  );
}

ImageProvider<Object> _accountImageProvider(
  String? path, {
  String fallback = 'assets/images/defaultProfileImage.jpg',
}) {
  final resolved = path == null || path.isEmpty ? fallback : path;
  if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
    return NetworkImage(resolved);
  }
  if (resolved.startsWith('assets/')) return AssetImage(resolved);
  return FileImage(File(resolved));
}

Future<void> _showProfilePhotoPreview(
  BuildContext context,
  String? profilePhoto,
) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: ColoredBox(
              color: Colors.black,
              child: AspectRatio(
                aspectRatio: 1,
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Image(
                    image: _accountImageProvider(profilePhoto),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: IconButton.filled(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    ),
  );
}

class _BackgroundPhotoViewer extends StatefulWidget {
  const _BackgroundPhotoViewer({
    required this.photo,
    required this.onEdit,
    required this.onDelete,
  });

  final String? photo;
  final Future<String?> Function(ImageSource source)? onEdit;
  final Future<bool> Function()? onDelete;

  @override
  State<_BackgroundPhotoViewer> createState() => _BackgroundPhotoViewerState();
}

class _BackgroundPhotoViewerState extends State<_BackgroundPhotoViewer> {
  bool _isWorking = false;

  Future<void> _edit() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Update background photo',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    setState(() => _isWorking = true);
    final updated = await widget.onEdit?.call(source);
    if (!mounted) return;
    setState(() => _isWorking = false);
    if (updated != null) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete background photo?'),
        content: const Text(
          'Your background photo will be removed from your profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isWorking = true);
    final deleted = await widget.onDelete?.call() ?? false;
    if (!mounted) return;
    setState(() => _isWorking = false);
    if (deleted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Image(
              image: _accountImageProvider(
                widget.photo,
                fallback: _coverPhotoUrl,
              ),
              fit: BoxFit.contain,
            ),
          ),
          if (widget.onEdit != null && widget.onDelete != null)
            Positioned(
              top: 12,
              left: 12,
              child: Row(
                children: [
                  _FrostedIconButton(
                    icon: Icons.edit_outlined,
                    onTap: _isWorking ? () {} : _edit,
                  ),
                  const SizedBox(width: 8),
                  _FrostedIconButton(
                    icon: Icons.delete_outline,
                    onTap: _isWorking ? () {} : _delete,
                  ),
                ],
              ),
            ),
          Positioned(
            top: 12,
            right: 12,
            child: _FrostedIconButton(
              icon: Icons.close_rounded,
              onTap: _isWorking ? () {} : () => Navigator.of(context).pop(),
            ),
          ),
          if (_isWorking)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    ),
  );
}

String _profileDisplayName(UserAccount user) {
  final fullName = user.fullName?.trim();
  if (fullName != null && fullName.isNotEmpty) return fullName;
  final username = user.username.trim();
  return username.isEmpty ? 'Profile incomplete' : username;
}

String _profileSummary(UserAccount user) {
  final nationality = user.nationality?.trim();
  final nationalityLabel = nationality == null || nationality.isEmpty
      ? 'Nationality not added'
      : _nationalityWithFlag(nationality);
  final age = _ageFromDateOfBirth(user.dateOfBirth);
  final gender = user.gender?.trim();

  return [
    nationalityLabel,
    age == null ? 'Age not added' : '$age',
    gender == null || gender.isEmpty ? 'Gender not added' : gender,
  ].join('  |  ');
}

String _nationalityWithFlag(String nationality) {
  return switch (nationality.toLowerCase()) {
    'malaysia' ||
    'malaysian' => '${String.fromCharCodes([0x1F1F2, 0x1F1FE])} Malaysia',
    _ => nationality,
  };
}

int? _ageFromDateOfBirth(DateTime? dateOfBirth) {
  if (dateOfBirth == null) return null;
  final today = DateTime.now();
  var age = today.year - dateOfBirth.year;
  final birthdayHasPassed =
      today.month > dateOfBirth.month ||
      (today.month == dateOfBirth.month && today.day >= dateOfBirth.day);
  if (!birthdayHasPassed) age--;
  return age < 0 ? null : age;
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

// ==========================================================================
// ⚙️ Sub-View: Static Placeholder Sub-page Frame
// ==========================================================================
class _AccountStaticFrame extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final VoidCallback onBack;

  const _AccountStaticFrame({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return _AccountLayoutWrapper(
      title: title,
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: _label),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(color: _muted, height: 1.6, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// 🛠️ Local Internal Primitive Micro-Components
// ==========================================================================
class _AccountLayoutWrapper extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final Widget child;

  const _AccountLayoutWrapper({
    required this.title,
    required this.onBack,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _ink,
              size: 20,
            ),
            onPressed: onBack,
          ),
          const SizedBox(height: 16),
          Text(title, style: _heading),
          const SizedBox(height: 24),
          Expanded(child: child),
        ],
      ),
    );
  }
}
