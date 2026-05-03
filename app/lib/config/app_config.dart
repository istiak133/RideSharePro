// ============================================
// RideShare AI Pro — App Configuration
// ============================================

class AppConfig {
  // API Base URL (change to production URL when deploying)
  static const String apiBaseUrl = 'http://10.0.2.2:3000/api'; // Android emulator → localhost
  static const String iosApiBaseUrl = 'http://localhost:3000/api';
  
  // Supabase (for Realtime chat)
  static const String supabaseUrl = 'https://lmkgljmfjimfnecwpcva.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxta2dsam1mamltZm5lY3dwY3ZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDYyMzU1MjksImV4cCI6MjA2MTgxMTUyOX0.hUWmaFs4ysVXmgiqbXA57J_GEOjNlP35b1FMCvOp8jk';
  
  // App Info
  static const String appName = 'RideShare AI Pro';
  static const String appVersion = '1.0.0';
  
  // Map defaults (Dhaka center)
  static const double defaultLat = 23.8103;
  static const double defaultLng = 90.4125;
  static const double defaultZoom = 14.0;
  
  // bKash Sandbox
  static const String bkashBaseUrl = 'https://tokenized.sandbox.bka.sh/v1.2.0-beta';
}
