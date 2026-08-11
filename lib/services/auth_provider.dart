import 'package:flutter/material.dart';
import '../models/app_user.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    // debugPrint(
    //   '************************** initialize *********************************',
    // );

    // 1. Inizializza l'istanza
    await GoogleSignIn.instance.initialize(
      serverClientId:
          '920318417311-ptqnaoec8b7v1h170ojj8eredd6cilja.apps.googleusercontent.com',
    );

    _initialized = true;

    final wasLogged = _prefs!.getBool('logged_in') ?? false;
    _user = null;
    if (!wasLogged) {
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

  Future<void> login() async {
    try {
      await initialize();

      // Se l'utente è già presente dopo initialize(), evitiamo di richiamare authenticate()
      if (_user != null) {
        notifyListeners();
        return;
      }

      // Chiamata esplicita all'autenticazione UI
      final GoogleSignInAccount account = await GoogleSignIn.instance
          .authenticate();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('logged_in', true);
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

  Future<void> logout() async {
    await GoogleSignIn.instance.signOut();

    _user = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('logged_in');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_photo');

    notifyListeners();
  }
}
