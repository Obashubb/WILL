import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../services/auth_service.dart';

class AuthController extends GetxController {
  final Rxn<User> user = Rxn<User>();
  final RxBool isSubmitting = false.obs;
  final RxnString lastError = RxnString();

  StreamSubscription<User?>? _sub;

  @override
  void onInit() {
    super.onInit();
    user.value = AuthService.currentUser;
    _sub = AuthService.authState.listen((u) => user.value = u);
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  bool get isSignedIn => user.value != null;

  Future<bool> signIn(String email, String password) async {
    return _wrap(() => AuthService.signIn(email: email, password: password));
  }

  Future<bool> signUp(String email, String password, {String? name}) async {
    return _wrap(
      () => AuthService.signUp(
        email: email,
        password: password,
        displayName: name,
      ),
    );
  }

  Future<void> signOut() => AuthService.signOut();

  Future<bool> _wrap(Future<User> Function() action) async {
    isSubmitting.value = true;
    lastError.value = null;
    try {
      await action();
      return true;
    } on FirebaseAuthException catch (e) {
      lastError.value = _readable(e);
      return false;
    } catch (_) {
      lastError.value = 'Something went wrong. Please try again.';
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  String _readable(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks off.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}
