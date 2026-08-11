import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get serverClientId => dotenv.env['SERVER_CLIENT_ID'] ?? '';

  static String get apiUrl => dotenv.env['API_URL'] ?? '';
}
