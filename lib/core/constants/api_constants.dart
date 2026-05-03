class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://10.0.2.2:8080/api';

  static const String authGoogle   = '/auth/google';
  static const String register     = '/auth/register';
  static const String login        = '/auth/login';
  static const String recipes      = '/recipes';
  static const String diseases     = '/users/diseases';
  static const String recommended  = '/recipes/recommended';
  static const String userProfile  = '/users/me';
  static const String userDiseases = '/users/me/diseases';
  static const String chatbot      = '/chatbot/message';
  static const String onboarding    = '/users/onboarding';
  static const String userProfileById = '/users';
}
