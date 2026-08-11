import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import './app_config.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool _initialized = false;
  SharedPreferences? _prefs;

  //Future<void> login() async {
  // per adesso simuliamo

  //_user = AppUser(
  // id: '123',
  //name: 'Marco Pignocco',
  //email: 'marco@email.it',
  //photoUrl: null,
  //);

  //notifyListeners();
  //}

  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();

    // 1. Inizializza l'istanza
    await GoogleSignIn.instance.initialize(
      serverClientId: AppConfig.serverClientId,
    );

    _initialized = true;

    await _getAccount();
  }

  Future<void> login() async {
    try {
      await initialize();

      // Se l'utente è già presente dopo initialize(), evitiamo di richiamare authenticate()
      if (_user != null) {
        await _killAccount();
        return;
      }

      // Chiamata esplicita all'autenticazione UI
      final GoogleSignInAccount account = await GoogleSignIn.instance
          .authenticate();

      await _setAccount(account);
    } catch (e, st) {
      debugPrint('TIPO: ${e.runtimeType}');
      debugPrint('ERRORE LOGIN: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> _setAccount(GoogleSignInAccount account) async {
    await _prefs!.setBool('logged_in', true);

    await _prefs!.setString('user_id', account.id);
    await _prefs!.setString('user_name', account.displayName ?? '');
    await _prefs!.setString('user_email', account.email);
    await _prefs!.setString('user_photo', account.photoUrl ?? '');

    _user = AppUser(
      id: account.id,
      name: account.displayName ?? '',
      email: account.email,
      photoUrl: account.photoUrl,
    );

    notifyListeners();
  }

  Future<void> _getAccount() async {
    final wasLogged = _prefs!.getBool('logged_in') ?? false;

    if (!wasLogged) {
      _user = null;
      notifyListeners();
      return;
    }

    _user = AppUser(
      id: _prefs!.getString('user_id') ?? '',
      name: _prefs!.getString('user_name') ?? '',
      email: _prefs!.getString('user_email') ?? '',
      photoUrl: _prefs!.getString('user_photo'),
    );

    notifyListeners();
  }

  Future<void> _killAccount() async {
    _user = null;

    await _prefs!.remove('logged_in');
    await _prefs!.remove('user_id');
    await _prefs!.remove('user_name');
    await _prefs!.remove('user_email');
    await _prefs!.remove('user_photo');

    notifyListeners();
  }

  Future<void> logout() async {
    await GoogleSignIn.instance.signOut();
    await _killAccount();
  }
}
