import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  // accuratezza gps
  static const String gpsAccuracyKey = 'gps_accuracy_threshold';
  static double gpsAccuracyThreshold = 5.0;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    gpsAccuracyThreshold = prefs.getDouble(gpsAccuracyKey) ?? 5.0;
  }

  static Future<void> setGpsAccuracyThreshold(double value) async {
    gpsAccuracyThreshold = value;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble(gpsAccuracyKey, value);
  }

  // ultima pagina visualizata
  static const String _lastRouteKey = 'last_route';

  static Future<void> saveRoute(String route) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastRouteKey, route);
  }

  static Future<String> getInitialRoute() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_lastRouteKey) ??
        '/impostazioni'; // pagina di default
  }
}
