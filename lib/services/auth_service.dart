import 'package:firebase_auth/firebase_auth.dart';

// TODO(firestore-rules): deploy `firestore.rules` (at project root) before
// any production data lands in Firestore. Until then the database is in
// test mode and is fully open. Deploy with:
//     firebase use will-wristband
//     firebase deploy --only firestore:rules
class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Stream<User?> get authState => _auth.authStateChanges();

  static User? get currentUser => _auth.currentUser;

  static Future<User> signIn({
    required String email,
    required String password,
  }) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return result.user!;
  }

  static Future<User> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (displayName != null && displayName.trim().isNotEmpty) {
      await result.user!.updateDisplayName(displayName.trim());
      await result.user!.reload();
    }
    return _auth.currentUser!;
  }

  static Future<void> signOut() => _auth.signOut();

  static Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());
}
