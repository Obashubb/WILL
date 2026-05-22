import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/care_repository.dart';
import '../../services/notification_service.dart';
import '../../services/profile_service.dart';
import '../../services/samples_repository.dart';

class AuthController extends GetxController {
  final Rxn<AppUser> user = Rxn<AppUser>();
  final RxBool isSubmitting = false.obs;
  final RxnString lastError = RxnString();

  StreamSubscription<User?>? _sub;

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
    _sub = FirebaseAuth.instance.authStateChanges().listen(_onFirebaseChanged);
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  bool get isSignedIn => user.value != null;

  bool get isGuest => user.value?.isGuest ?? false;

  void _bootstrap() {
    final stored = ProfileService.readUser();
    if (stored != null) {
      user.value = stored;
      return;
    }
    final fb = FirebaseAuth.instance.currentUser;
    if (fb != null) {
      final reconstructed = _fromFirebase(fb);
      ProfileService.writeUser(reconstructed);
      user.value = reconstructed;
    }
  }

  void _onFirebaseChanged(User? fb) {
    if (fb == null) {
      final local = ProfileService.readUser();
      if (local == null || !local.isGuest) user.value = null;
      return;
    }
    final local = ProfileService.readUser();
    if (local == null || local.id != fb.uid) {
      final next = _fromFirebase(fb);
      ProfileService.writeUser(next);
      user.value = next;
    }
  }

  AppUser _fromFirebase(User fb) => AppUser(
        id: fb.uid,
        name: fb.displayName?.trim().isNotEmpty == true
            ? fb.displayName!.trim()
            : (fb.email?.split('@').first ?? 'Friend'),
        email: fb.email,
        isGuest: false,
        createdAt: fb.metadata.creationTime ?? DateTime.now(),
      );

  Future<bool> signIn(String email, String password) async {
    return _wrap(() async {
      final fb = await AuthService.signIn(email: email, password: password);
      final next = _fromFirebase(fb);
      await ProfileService.writeUser(next);
      user.value = next;
    });
  }

  Future<bool> signUp(String email, String password, {required String name}) async {
    return _wrap(() async {
      final fb = await AuthService.signUp(
        email: email,
        password: password,
        displayName: name,
      );
      final next = _fromFirebase(fb).copyWith(name: name);
      await ProfileService.writeUser(next);
      user.value = next;
    });
  }

  Future<void> continueAsGuest(String name) async {
    final id = 'guest_${DateTime.now().millisecondsSinceEpoch}';
    final next = AppUser(
      id: id,
      name: name.trim(),
      isGuest: true,
      createdAt: DateTime.now(),
    );
    await ProfileService.writeUser(next);
    user.value = next;
  }

  Future<void> signOut() async {
    if (FirebaseAuth.instance.currentUser != null) {
      await AuthService.signOut();
    }
    await Future.wait([
      ProfileService.clearAll(),
      SamplesRepository.clearAll(),
      CareRepository.clearAll(),
      NotificationService.cancelAll(),
    ]);
    user.value = null;
  }

  Future<bool> _wrap(Future<void> Function() action) async {
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
