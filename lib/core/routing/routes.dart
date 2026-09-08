class Routes {
  Routes._();

  static const splash = '/';
  static const welcome = '/welcome';
  static const register = '/register';
  static const login = '/login';
  static const admin = '/admin';
  static const accountBanned = '/account-banned';
  static const accessError = '/access-error';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const otp = '/otp';
  static const setPassword = '/set-password';
  static const profileSetup = '/profile-setup';
  static const profileOnboarding = '/profile-onboarding';
  static const main = '/main';
  static const myTrips = '/my-trips';
  static const expenseTripPicker = '/my-trips?pickExpense=true';
  static const messages = '/messages';
  static const trip = '/trip';
  static const trips = '/trips';
  static const groupExpense = '/expenses';
  static const createBudget = 'budget/create';
  static const editBudget = 'budget/edit';
  static const addExpense = 'expenses/new';
  static const expenseDetails = 'expenses';
  static const editExpense = 'edit';
  static const outstandingBalance = 'balances';
  static const recordSettlement = 'settlements/new';
  static const settlementHistory = 'settlements';
  static const budgetAnalytics = 'analytics';
  static const userAccount = '/user_account';
  static const savedTrips = '/user_account/saved-trips';
  static const travelFootprint = '/user_account/travel-footprint';
  static const publicProfile = '/profile';
  static const groupCollaboration = '/group-collaboration';
  static const identityVerification = '/identity-verification';
  static const identityReviews = '/admin/identity-reviews';
  static const settings = '/settings';
  static const changePassword = '/settings/change-password';
  static const safetyCheckInSettings = '/settings/safety-check-in';
  static const blockedUsers = '/settings/blocked-users';
  static const termsOfService = '/terms-of-service';
  static const privacyPolicy = '/privacy-policy';
  static const emergencyContacts = '/safety/emergency-contacts';
  static const addEmergencyContact = '/safety/emergency-contacts/add';
  static const liveLocation = '/safety/live-location';
  static const sos = '/safety/sos';
  static const sosShortcut = '/safety/sos/confirm';

  static String tripTimeline(String tripId) =>
      '$trip/${Uri.encodeComponent(tripId)}/timeline';

  static String tripMessages(String tripId) =>
      '$trip/${Uri.encodeComponent(tripId)}/messages';

  static String travelCountry(String countryId) =>
      '$travelFootprint/${Uri.encodeComponent(countryId)}';
}
