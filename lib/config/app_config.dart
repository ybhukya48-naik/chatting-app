
class AppConfig {
  static const String agoraAppId = "2957736ea37443c090a86851e6b9390e";
  
  // Backend URLs
  static const String localBackendUrl = 'http://localhost:3000';
  static const String androidEmulatorUrl = 'http://10.0.2.2:3000';
  static const String productionBackendUrl = 'https://couple-chat-backend.onrender.com';
  
  // Replace this with your actual PC IP when testing on physical Android devices
  static const String localAndroidDeviceUrl = 'http://192.168.7.4:3000';
  
  // Flag to toggle between local and production
  static const bool isProduction = false;
}
