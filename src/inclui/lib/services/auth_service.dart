import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseDatabase _database = FirebaseDatabase.instance;

  static Future<bool> isUserLoggedIn() async {
    return _auth.currentUser != null;
  }

  static bool isUserVerified() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.emailVerified ?? false;
  }

  static Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  static Future<void> signUp(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await sendEmailVerification();
  }

  static Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static User? get currentUser => _auth.currentUser;

  static String? getUserEmail() {
    return _auth.currentUser?.email;
  }

  static String? getUserId() {
    return _auth.currentUser?.uid;
  }

  static Future<User?> reloadUser() async {
    final user = _auth.currentUser;
    await user?.reload();
    return _auth.currentUser;
  }

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  Future<void> saveUserPreferences(List<String> preferences) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _database.ref('users/${user.uid}/preferences').set(preferences);
  }

  Future<List<String>> getUserPreferences() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _database.ref('users/${user.uid}/preferences').get();

    if (snapshot.exists && snapshot.value is List) {
      return List<String>.from(snapshot.value as List);
    }

    return [];
  }
}
