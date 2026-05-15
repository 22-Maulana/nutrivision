class ApiConstants {
  static const String baseUrl = 'https://be-nutrivision.maulanaap.my.id';
  static const String apiBaseUrl = '$baseUrl/api';

  // Auth Endpoints
  static const String login = '$apiBaseUrl/login';
  static const String register = '$apiBaseUrl/register';
  static const String verifyOtp = '$apiBaseUrl/verify-otp';
  
  // Feature Endpoints
  static const String scan = '$apiBaseUrl/scan';
  static const String chatbot = '$apiBaseUrl/chatbot';
}