import 'dart:io';

class ApiConstants {
  ApiConstants._();

  // ✅ Cambia esta IP por la de tu PC en WiFi
  static const String _localNetworkIp = '192.168.1.57';

  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://$_localNetworkIp:8080/api'; // dispositivo físico
    } else if (Platform.isIOS) {
      return 'http://localhost:8080/api';
    } else {
      return 'http://localhost:8080/api';
    }
  }

  static const String authGoogle = '/auth/google';
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String recipes = '/recipes';
  static const String diseases = '/users/diseases';
  static const String recommended = '/recipes/recommended';
  static const String userProfile = '/users/me';
  static const String userDiseases = '/users/me/diseases';
  static const String chatbot = '/chatbot/message';
  static const String onboarding = '/users/onboarding';
  static const String userProfileById = '/users';
}