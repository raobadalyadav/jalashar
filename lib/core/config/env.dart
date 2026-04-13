import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get razorpayKeyId => dotenv.env['RAZORPAY_KEY_ID'] ?? '';
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  static String get sentryDsn => dotenv.env['SENTRY_DSN'] ?? '';
  static String get environment => dotenv.env['ENV'] ?? 'dev';
  static bool get isProd => environment == 'prod';
}
