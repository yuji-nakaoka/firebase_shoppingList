import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_firebase_list_app/repositries/auth_repositry.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final authControllerProvider = StateNotifierProvider<AuthController, User?>(
    (ref) => AuthController(ref.read)..appStarted(),);

class AuthController extends StateNotifier<User?> {
  Reader _read;

  StreamSubscription<User?>? _authStateChangesSubscription;

  AuthController(this._read) : super(null) {
    _authStateChangesSubscription?.cancel();
    _authStateChangesSubscription = _read(authRepositryProvider)
        .authStateChanges
        .listen((User) => state = User);
  }

  @override
  void dispose() {
    _authStateChangesSubscription?.cancel();
    super.dispose();
  }

  void appStarted() async {
    final user = _read(authRepositryProvider).getCurrentUser();
    if (user == null) {
      await _read(authRepositryProvider).signInAnonymously();
    }
  }

  void signOut() async {
   await _read(authRepositryProvider).signOut();
  }
}
