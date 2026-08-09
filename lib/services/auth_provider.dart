import 'package:flutter/material.dart';
import '../models/app_user.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _user;

  AppUser? get user => _user;

  bool get isLoggedIn => _user != null;

  bool _initialized = false;

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

    await GoogleSignIn.instance.initialize();

    _initialized = true;
  }

  Future<void> login() async {
    await initialize();

    final GoogleSignInAccount? account = await GoogleSignIn.instance
        .authenticate();

    if (account == null) {
      return;
    }

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

    notifyListeners();
  }
}
