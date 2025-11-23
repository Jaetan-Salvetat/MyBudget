class AppConstants {
   
  static const String tableAccounts = 'accounts';
  static const String tableCategories = 'categories';
  static const String tableExpenses = 'expenses';
  static const String tableRevenues = 'revenues';
  static const String tablePrivacySettings = 'privacy_settings';

   
  static const String fieldId = 'id';
  static const String fieldName = 'name';
  static const String fieldUserId = 'user_id';
  static const String fieldBank = 'bank';
  static const String fieldIcon = 'icon';
  static const String fieldAmount = 'amount';
  static const String fieldCategory = 'category';
  static const String fieldDate = 'date';
  static const String fieldFrequency = 'frequency';
  static const String fieldAccountId = 'accountId';
  static const String fieldIsRegular = 'isRegular';
  static const String fieldIsPredefined = 'is_predefined';
  static const String fieldPrivacyPolicyAccepted = 'privacy_policy_accepted';
  static const String fieldMarketingConsent = 'marketing_consent';
  static const String fieldConsentDate = 'consent_date';
  static const String fieldEmail = 'email';
  static const String fieldPassword = 'password';
  static const String fieldIsAuthenticated = 'isAuthenticated';

   
  static const String errorUserNotAuthenticated = 'User not authenticated';
  static const String errorInvalidCredentials = 'Invalid credentials';
  static const String errorRegistrationFailed = 'Registration failed';

   
  static const String routeSplash = '/splash';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeDashboard = '/dashboard';
  static const String routeSettings = '/settings';
  static const String routeAccount = '/account';
  static const String routeExpense = '/expense';
  static const String routeRevenue = '/revenue';
  static const String routeCategory = '/category';
  static const String routePrivacyPolicy = '/privacy_policy';
}
