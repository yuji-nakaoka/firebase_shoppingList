import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_firebase_list_app/repositries/customException.dart';
import 'package:flutter_firebase_list_app/repositries/general_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

abstract class BaseAuthRepositry {
  Stream<User?> get authStateChanges;
  Future<void> signInAnonymously();
  User? getCurrentUser();
  Future<void> signOut();
}

final authRepositryProvider =
    Provider<AuthRepositry>((ref) => AuthRepositry(ref.read));

class AuthRepositry implements BaseAuthRepositry {
  final Reader _read;

  const AuthRepositry(this._read);

  @override
  Stream<User?> get authStateChanges =>
      _read(firebaseAuthProvider).authStateChanges();

  @override
  Future<void> signInAnonymously() async {
    try {
      await _read(firebaseAuthProvider).signInAnonymously();
    } on FirebaseAuthException catch (e) {
      throw CustomException(message: e.message);
    }
  }

  @override
  User? getCurrentUser() {
    try {
      return _read(firebaseAuthProvider).currentUser;
    } on FirebaseAuthException catch (e) {
      throw CustomException(message: e.message);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _read(firebaseAuthProvider).signOut();
      await signInAnonymously();
    } on FirebaseAuthException catch (e) {
      throw CustomException(message: e.message);
    }
  }
}
