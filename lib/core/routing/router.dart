import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mvvm_riverpod/features/collaboration/ui/group_collaboration_screen.dart';
import '../../features/user_account/ui/login_confirmation.dart';
import '../../features/user_account/ui/welcome_screen.dart';
import '../../features/matchmaking/ui/matchmaking_shell_screen.dart';
import '../../features/matchmaking/ui/saved_trips_screen.dart';
import '../../features/matchmaking/ui/matchmaking_view_model.dart';
import '../../features/matchmaking/model/matchmaking_page.dart';
import '../../features/group_collaboration/ui/messages_screen.dart';
import '../../features/group_expense/ui/expense_dashboard_screen.dart';
import '../../features/group_expense/ui/create_budget_screen.dart';
import '../../features/group_expense/ui/add_expense_screen.dart';
import '../../features/group_expense/ui/edit_budget_screen.dart';
import '../../features/group_expense/ui/edit_expense_screen.dart';
import '../../features/group_expense/ui/expense_details_screen.dart';
import '../../features/group_expense/ui/outstanding_balance_screen.dart';
import '../../features/group_expense/ui/record_settlement_screen.dart';
import '../../features/group_expense/ui/settlement_history_screen.dart';
import '../../features/group_expense/ui/budget_analytics_screen.dart';
import '../../features/user_account/ui/user_account_shell.dart';
import '../../features/user_account/ui/app_launching_screen.dart';
import '../../features/user_account/ui/forgot_password_screen.dart';
import '../../features/user_account/ui/identity_verification_screen.dart';
import '../../features/admin/ui/identity_reviews_screen.dart';
import '../../features/user_account/ui/settings/blocked_users_screen.dart';
import '../../features/user_account/ui/settings/change_password_screen.dart';
import '../../features/user_account/ui/settings/settings_screen.dart';
import '../../features/travel_footprint/ui/travel_footprint_screen.dart';
import '../../features/user_account/ui/login_screen.dart';
import '../../features/user_account/ui/register_account_screen.dart';
import '../../features/user_account/ui/personal_information_setup_screen.dart';
import '../../features/user_account/ui/set_password_screen.dart';
import '../../features/user_account/ui/profile_onboarding_screen.dart';
import '../../features/user_account/ui/legal/privacy_policy_screen.dart';
import '../../features/user_account/ui/legal/terms_screen.dart';
import '../../features/safety/ui/add_emergency_contact_screen.dart';
import '../../features/safety/ui/emergency_contacts_screen.dart';
import '../../features/safety/ui/live_location_screen.dart';
import '../../features/safety/ui/sos_screen.dart';
import '../../features/safety/ui/sos_shortcut_screen.dart';
import '../../features/safety/ui/safety_check_in_settings_screen.dart';

import 'routes.dart';
import 'account_access_redirect.dart';
import '../../features/admin/repository/admin_repository.dart';
import '../../features/admin/ui/admin_screen.dart';
import '../../features/common/ui/widgets/verified_access_gate.dart';

enum SlideDirection { right, left, up, down }

extension GoRouterStateExtension on GoRouterState {
  NoTransitionPage<void> navigationPage(Widget child) {
    return NoTransitionPage<void>(key: pageKey, child: child);
  }

  SlideRouteTransition slidePage(
    Widget child, {
    SlideDirection direction = SlideDirection.left,
  }) {
    return SlideRouteTransition(
      key: pageKey,
      child: child,
      direction: direction,
    );
  }
}

class SlideRouteTransition extends CustomTransitionPage<void> {
  SlideRouteTransition({
    required super.key,
    required super.child,
    SlideDirection direction = SlideDirection.left,
  }) : super(
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final curve = CurvedAnimation(
             parent: animation,
             curve: Curves.easeInOut,
           );

           Offset begin;
           switch (direction) {
             case SlideDirection.right:
               begin = const Offset(-1.0, 0.0);
               break;
             case SlideDirection.left:
               begin = const Offset(1.0, 0.0);
               break;
             case SlideDirection.up:
               begin = const Offset(0.0, 1.0);
               break;
             case SlideDirection.down:
               begin = const Offset(0.0, -1.0);
               break;
           }
           final tween = Tween(begin: begin, end: Offset.zero);
           final offsetAnimation = tween.animate(curve);

           return SlideTransition(position: offsetAnimation, child: child);
         },
       );
}

final rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: Routes.splash,
  redirect: (context, state) async {
    final path = state.uri.path;
    const publicPaths = {
      Routes.splash,
      Routes.login,
      Routes.welcome,
      Routes.register,
      Routes.forgotPassword,
      Routes.resetPassword,
      Routes.otp,
      Routes.setPassword,
      Routes.termsOfService,
      Routes.privacyPolicy,
      Routes.accessError,
    };
    if (publicPaths.contains(path)) return null;
    try {
      final access = await AdminRepository().access();
      return accountAccessRedirect(access, path);
    } catch (_) {
      return Routes.accessError;
    }
  },
  routes: [
    GoRoute(
      path: Routes.admin,
      builder: (context, state) => const AdminScreen(),
    ),
    GoRoute(
      path: '${Routes.admin}/reports',
      builder: (context, state) => AdminScreen(
        key: ValueKey(state.uri.toString()),
        section: 1,
        status: state.uri.queryParameters['status'] ?? 'pending',
      ),
    ),
    GoRoute(
      path: '${Routes.admin}/users',
      builder: (context, state) => AdminScreen(
        key: ValueKey(state.uri.toString()),
        section: 2,
        status: state.uri.queryParameters['status'] ?? 'all',
      ),
    ),
    GoRoute(
      path: '${Routes.admin}/reports/:reportId',
      builder: (context, state) =>
          AdminReportScreen(reportId: state.pathParameters['reportId']!),
    ),
    GoRoute(
      path: '${Routes.admin}/activity',
      builder: (context, state) => const AdminScreen(section: 3),
    ),
    GoRoute(
      path: '${Routes.admin}/users/:userId',
      builder: (context, state) =>
          AdminProfileScreen(userId: state.pathParameters['userId']!),
    ),
    GoRoute(
      path: Routes.accountBanned,
      builder: (context, state) => const _AccessScreen(banned: true),
    ),
    GoRoute(
      path: Routes.accessError,
      builder: (context, state) => const _AccessScreen(banned: false),
    ),
    GoRoute(
      path: Routes.splash,
      pageBuilder: (context, state) => state.slidePage(
        const AppLaunchingScreen(),
        direction: SlideDirection.up,
      ),
    ),
    GoRoute(
      path: Routes.welcome,
      pageBuilder: (context, state) => state.slidePage(const WelcomeScreen()),
    ),
    GoRoute(
      path: Routes.register,
      pageBuilder: (context, state) =>
          state.slidePage(const RegisterAccountScreen()),
    ),
    GoRoute(
      path: Routes.login,
      pageBuilder: (context, state) => state.slidePage(const LoginScreen()),
    ),
    GoRoute(
      path: Routes.forgotPassword,
      pageBuilder: (context, state) =>
          state.slidePage(const ForgotPasswordScreen()),
    ),
    GoRoute(
      path: Routes.otp,
      pageBuilder: (context, state) {
        final map = state.extra as Map?;
        return state.slidePage(
          OtpScreen(email: map?['email'] as String? ?? ''),
        );
      },
    ),
    GoRoute(
      path: Routes.setPassword,
      pageBuilder: (context, state) =>
          state.slidePage(const SetPasswordScreen()),
    ),
    GoRoute(
      path: Routes.profileOnboarding,
      pageBuilder: (context, state) =>
          state.slidePage(const ProfileOnboardingScreen()),
    ),
    GoRoute(
      path: Routes.resetPassword,
      pageBuilder: (context, state) =>
          state.slidePage(const SetPasswordScreen(isRecovery: true)),
    ),
    GoRoute(
      path: Routes.profileSetup,
      pageBuilder: (context, state) =>
          state.slidePage(const PersonalInformationSetupScreen()),
    ),
    GoRoute(
      path: Routes.main,
      pageBuilder: (context, state) => state.navigationPage(
        ProviderScope(
          overrides: [
            matchmakingInitialPageProvider.overrideWithValue(
              MatchmakingPage.discover,
            ),
            matchmakingViewModelProvider.overrideWith(MatchmakingViewModel.new),
          ],
          child: const MatchmakingShellScreen(),
        ),
      ),
    ),
    GoRoute(
      path: Routes.myTrips,
      pageBuilder: (context, state) => state.navigationPage(
        ProviderScope(
          overrides: [
            matchmakingInitialPageProvider.overrideWithValue(
              MatchmakingPage.myTrips,
            ),
            matchmakingViewModelProvider.overrideWith(MatchmakingViewModel.new),
          ],
          child: const MatchmakingShellScreen(),
        ),
      ),
    ),
    GoRoute(
      path: Routes.messages,
      pageBuilder: (context, state) =>
          state.navigationPage(const VerifiedAccessGate(featureName: 'Messages', child: MessagesScreen())),
    ),
    GoRoute(
      path: '${Routes.trip}/:tripId/messages',
      pageBuilder: (context, state) => state.slidePage(
        VerifiedAccessGate(featureName: 'Messages', child: GroupCollaborationScreen(
          tripId: state.pathParameters['tripId']!,
          knownRemoved: state.uri.queryParameters['removed'] == 'true',
          initialView: TripWorkspaceView.messages,
        )),
      ),
    ),
    GoRoute(
      path: '${Routes.trip}/:tripId/timeline',
      pageBuilder: (context, state) => state.slidePage(
        VerifiedAccessGate(featureName: 'My Trips', child: GroupCollaborationScreen(
          tripId: state.pathParameters['tripId']!,
          initialView: TripWorkspaceView.timeline,
        )),
      ),
    ),
    GoRoute(
      path: '${Routes.messages}/:tripId',
      redirect: (context, state) =>
          Routes.tripMessages(state.pathParameters['tripId']!),
    ),
    GoRoute(
      path: '${Routes.trips}/:tripId/timeline',
      redirect: (context, state) =>
          Routes.tripTimeline(state.pathParameters['tripId']!),
    ),
    GoRoute(
      path: '${Routes.groupExpense}/:tripId',
      pageBuilder: (context, state) => state.navigationPage(
        VerifiedAccessGate(featureName: 'Expenses', child: ExpenseDashboardScreen(tripId: state.pathParameters['tripId']!)),
      ),
    ),
    GoRoute(
      path: '${Routes.groupExpense}/:tripId/${Routes.createBudget}',
      pageBuilder: (context, state) => state.slidePage(
        VerifiedAccessGate(featureName: 'Expenses', child: CreateBudgetScreen(tripId: state.pathParameters['tripId']!)),
      ),
    ),
    GoRoute(
      path: '${Routes.groupExpense}/:tripId/${Routes.editBudget}',
      pageBuilder: (context, state) => state.slidePage(
        VerifiedAccessGate(featureName: 'Expenses', child: EditBudgetScreen(tripId: state.pathParameters['tripId']!)),
      ),
    ),
    GoRoute(
      path: '${Routes.groupExpense}/:tripId/${Routes.addExpense}',
      pageBuilder: (context, state) => state.slidePage(
        VerifiedAccessGate(featureName: 'Expenses', child: AddExpenseScreen(tripId: state.pathParameters['tripId']!)),
      ),
    ),
    GoRoute(
      path:
          '${Routes.groupExpense}/:tripId/${Routes.expenseDetails}/:expenseId',
      pageBuilder: (context, state) => state.slidePage(
        VerifiedAccessGate(featureName: 'Expenses', child: ExpenseDetailsScreen(
          tripId: state.pathParameters['tripId']!,
          expenseId: state.pathParameters['expenseId']!,
          initialSuccessMessage: state.uri.queryParameters['message'],
        )),
      ),
    ),
    GoRoute(
      path:
          '${Routes.groupExpense}/:tripId/${Routes.expenseDetails}/:expenseId/${Routes.editExpense}',
      pageBuilder: (context, state) => state.slidePage(
        VerifiedAccessGate(featureName: 'Expenses', child: EditExpenseScreen(
          tripId: state.pathParameters['tripId']!,
          expenseId: state.pathParameters['expenseId']!,
        )),
      ),
    ),
    GoRoute(
      path: '${Routes.groupExpense}/:tripId/${Routes.outstandingBalance}',
      pageBuilder: (context, state) => state.slidePage(
        VerifiedAccessGate(featureName: 'Expenses', child: OutstandingBalanceScreen(tripId: state.pathParameters['tripId']!)),
      ),
    ),
    GoRoute(
      path: '${Routes.groupExpense}/:tripId/${Routes.recordSettlement}',
      pageBuilder: (context, state) => state.slidePage(
        VerifiedAccessGate(featureName: 'Expenses', child: RecordSettlementScreen(
          tripId: state.pathParameters['tripId']!,
          initialPayerId: state.uri.queryParameters['payerId'],
          initialPayeeId: state.uri.queryParameters['payeeId'],
        )),
      ),
    ),
    GoRoute(
      path: '${Routes.groupExpense}/:tripId/${Routes.settlementHistory}',
      pageBuilder: (context, state) => state.slidePage(
        VerifiedAccessGate(featureName: 'Expenses', child: SettlementHistoryScreen(tripId: state.pathParameters['tripId']!)),
      ),
    ),
    GoRoute(
      path: '${Routes.groupExpense}/:tripId/${Routes.budgetAnalytics}',
      pageBuilder: (context, state) => state.slidePage(
        VerifiedAccessGate(featureName: 'Expenses', child: BudgetAnalyticsScreen(tripId: state.pathParameters['tripId']!)),
      ),
    ),
    GoRoute(
      path: Routes.userAccount,
      pageBuilder: (context, state) =>
          state.navigationPage(const UserAccountScreen()),
    ),
    GoRoute(
      path: Routes.savedTrips,
      pageBuilder: (context, state) =>
          state.slidePage(const VerifiedAccessGate(featureName: 'Saved Trips', child: SavedTripsScreen())),
    ),
    GoRoute(
      path: Routes.travelFootprint,
      pageBuilder: (context, state) =>
          state.slidePage(const TravelFootprintScreen()),
    ),
    GoRoute(
      path: '${Routes.travelFootprint}/:countryId',
      pageBuilder: (context, state) => state.slidePage(
        CountryFootprintScreen(countryId: state.pathParameters['countryId']!),
      ),
    ),
    GoRoute(
      path: '${Routes.publicProfile}/:userId',
      pageBuilder: (context, state) => state.slidePage(
        VerifiedAccessGate(
          featureName: 'Traveller profiles',
          child: PublicUserProfileScreen(userId: state.pathParameters['userId']!),
        ),
      ),
    ),
    GoRoute(
      path: Routes.identityVerification,
      pageBuilder: (context, state) => state.slidePage(
        IdentityVerificationScreen(
          fromOnboarding: state.uri.queryParameters['onboarding'] == 'true',
        ),
      ),
    ),
    GoRoute(
      path: Routes.identityReviews,
      pageBuilder: (context, state) =>
          state.slidePage(const IdentityReviewsScreen()),
    ),
    GoRoute(
      path: Routes.settings,
      pageBuilder: (context, state) => state.slidePage(const SettingsScreen()),
    ),
    GoRoute(
      path: Routes.changePassword,
      pageBuilder: (context, state) =>
          state.slidePage(const ChangePasswordScreen()),
    ),
    GoRoute(
      path: Routes.safetyCheckInSettings,
      pageBuilder: (context, state) =>
          state.slidePage(const SafetyCheckInSettingsScreen()),
    ),
    GoRoute(
      path: Routes.blockedUsers,
      pageBuilder: (context, state) =>
          state.slidePage(const BlockedUsersScreen()),
    ),
    GoRoute(
      path: Routes.termsOfService,
      pageBuilder: (context, state) => state.slidePage(const TermsScreen()),
    ),
    GoRoute(
      path: Routes.privacyPolicy,
      pageBuilder: (context, state) =>
          state.slidePage(const PrivacyPolicyScreen()),
    ),
    GoRoute(
      path: Routes.emergencyContacts,
      pageBuilder: (context, state) =>
          state.slidePage(const EmergencyContactsScreen()),
    ),
    GoRoute(
      path: Routes.addEmergencyContact,
      pageBuilder: (context, state) =>
          state.slidePage(const AddEmergencyContactScreen()),
    ),
    GoRoute(
      path: Routes.liveLocation,
      pageBuilder: (context, state) =>
          state.slidePage(const LiveLocationScreen()),
    ),
    GoRoute(
      path: Routes.sos,
      pageBuilder: (context, state) => state.slidePage(const SosScreen()),
    ),
    GoRoute(
      path: Routes.sosShortcut,
      pageBuilder: (context, state) =>
          state.navigationPage(const SosShortcutScreen()),
    ),
    GoRoute(
      path: Routes.groupCollaboration,
      pageBuilder: (context, state) {
        final tripId = state.uri.queryParameters['tripId'] ?? '';
        final knownRemoved = state.uri.queryParameters['removed'] == 'true';
        return state.slidePage(
          VerifiedAccessGate(featureName: 'Messages', child: GroupCollaborationScreen(
            tripId: tripId,
            knownRemoved: knownRemoved,
            initialView: TripWorkspaceView.messages,
          )),
        );
      },
    ),
  ],
);

class _AccessScreen extends StatelessWidget {
  const _AccessScreen({required this.banned});
  final bool banned;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            banned
                ? 'Your account is restricted. If suspended, try again after the suspension ends.'
                : 'Unable to verify account access. Please try again.',
          ),
          TextButton(
            onPressed: () => context.go(Routes.main),
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await AdminRepository().signOut();
                if (context.mounted) context.go(Routes.login);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unable to sign out. Please try again.'),
                    ),
                  );
                }
              }
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    ),
  );
}
