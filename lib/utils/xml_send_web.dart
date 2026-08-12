import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../services/auth_provider.dart';
import 'package:crypto/crypto.dart';

String md5Hash(String value) {
  const miaKiave = 'sK!#73';
  return sha256.convert(utf8.encode("$value$miaKiave")).toString();
}

Future<String> inviaXmlAlServer({required String xml}) async {
  try {
    final authProvider = AuthProvider();
    await authProvider.initialize();

    if (authProvider.isLoggedIn == false) return 'effettuare login';

    // Info app
    final packageInfo = await PackageInfo.fromPlatform();

    // ID installazione persistente
    final prefs = await SharedPreferences.getInstance();
    String? installationId = prefs.getString('installation_id');

    if (installationId == null) {
      installationId = const Uuid().v4();
      await prefs.setString('installation_id', installationId);
    }

    final userK = authProvider.user?.id ?? '';
    final userE = authProvider.user?.email ?? '';

    final payload = {
      "utente": md5Hash(userK),
      "em": md5Hash(userE),
      "dataOra": DateTime.now().toIso8601String(),
      "nomeApp": packageInfo.appName,
      "versioneApp": packageInfo.version,
      "buildNumber": packageInfo.buildNumber,
      "installationId": installationId,
      "xml": xml,
    };

    final response = await http.post(
      Uri.parse('https://gip.altervista.org/api/authgoogle.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    print("****************************");
    print(response);

    if (response.statusCode == 200) {
      final res = jsonDecode(response.body);

      return res['messaggio'] ?? 'Invio completato';
    }

    return 'Errore HTTP ${response.statusCode}';
  } catch (e) {
    return 'Errore: $e';
  }
}
