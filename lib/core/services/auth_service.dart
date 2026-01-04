import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _hasCloudKey = false;
  bool get hasCloudKey => _hasCloudKey;

  AuthService() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        checkForCloudKey();
      } else {
        _hasCloudKey = false;
        _isMpinVerified = false;
      }
      notifyListeners();
    });
  }

  Future<void> checkForCloudKey() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()!.containsKey('encrypted_key')) {
        _hasCloudKey = true;
      } else {
        _hasCloudKey = false;
      }
      notifyListeners();
    }
  }

  Future<String?> getCloudKey() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()!.containsKey('encrypted_key')) {
        return doc.data()!['encrypted_key'] as String;
      }
    }
    return null;
  }

  Future<void> saveCloudKey(String encryptedKey) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'encrypted_key': encryptedKey,
      }, SetOptions(merge: true));
      _hasCloudKey = true;
      notifyListeners();
    }
  }

  // Auth State Changes Stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current User
  User? get currentUser => _auth.currentUser;

  // Sign Up
  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create Auth User
      final UserCredential credential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? user = credential.user;

      if (user != null) {
        // Update Display Name
        await user.updateDisplayName(name);

        // Create Firestore Document
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'displayName': name,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });

        // No key yet, naturally.

        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "An error occurred during sign up.";
    } catch (e) {
      throw "An unknown error occurred.";
    }
  }

  // Sign In
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update Last Login
      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
        // Check for key immediately upon sign in
        await checkForCloudKey();
      }

      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "An error occurred during sign in.";
    } catch (e) {
      throw "An unknown error occurred.";
    }
  }

  // Google Sign In
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return null; // User canceled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      if (user != null) {
        // Create/Update Firestore Document
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await checkForCloudKey();
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "An error occurred during Google Sign In.";
    } catch (e) {
      throw e.toString();
    }
  }

  bool _isMpinVerified = false;
  bool get isMpinVerified => _isMpinVerified;

  void verifyMpin() {
    _isMpinVerified = true;
    notifyListeners();
  }

  void revokeMpin() {
    _isMpinVerified = false;
    notifyListeners();
  }

  // Sign Out
  Future<void> signOut() async {
    _isMpinVerified = false;
    await GoogleSignIn(
      scopes: ['email'],
    ).signOut(); // Ensure Google is also signed out
    await _auth.signOut();
  }
}
