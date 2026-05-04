import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _userName;
  String? _userEmail;
  bool _hasSeenWelcomeBack = false;
  bool _isFirstTimeSignup = false;
  bool _isInitialized = false;
  bool _isEmailVerified = false;
  bool _isGoogleUser = false;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  StreamSubscription<User?>? _authSubscription;

  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  bool get hasSeenWelcomeBack => _hasSeenWelcomeBack;
  bool get isFirstTimeSignup => _isFirstTimeSignup;
  bool get isEmailVerified => _isEmailVerified;
  bool get isGoogleUser => _isGoogleUser;
  String? get userId => _firebaseAuth.currentUser?.uid;

  AuthProvider() {
    _initAuth();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initAuth() async {
    // Listen to auth state changes from Firebase
    _authSubscription = _firebaseAuth.authStateChanges().listen((
      User? user,
    ) async {
      if (user != null) {
        _isLoggedIn = true;
        _userEmail = user.email;
        _isGoogleUser = user.providerData.any(
          (p) => p.providerId == 'google.com',
        );
        // Google users are always considered verified
        _isEmailVerified = _isGoogleUser || user.emailVerified;

        // Load stored preferences
        final prefs = await SharedPreferences.getInstance();
        _userName = prefs.getString('userName') ?? user.displayName;
        _hasSeenWelcomeBack = prefs.getBool('hasSeenWelcomeBack') ?? false;

        // If userName came from Firebase (Google), persist it
        if (_userName != null && prefs.getString('userName') == null) {
          await prefs.setString('userName', _userName!);
        }
      } else {
        _isLoggedIn = false;
        _isEmailVerified = false;
        _isGoogleUser = false;
      }
      _isInitialized = true;
      notifyListeners();
    });
  }

  Future<void> setHasSeenWelcomeBack(bool value) async {
    _hasSeenWelcomeBack = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenWelcomeBack', value);
    notifyListeners();
  }

  void finishInitialWelcome() {
    _isFirstTimeSignup = false;
    notifyListeners();
  }

  // ---------- Email/Password Auth ----------

  Future<void> login(String email, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      _isEmailVerified = user.emailVerified;
      _isFirstTimeSignup = false;
      _hasSeenWelcomeBack = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenWelcomeBack', false);
      notifyListeners();
    }
  }

  Future<void> signup(String email, String password) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      // Send verification email
      await user.sendEmailVerification();

      _isEmailVerified = false;
      _isFirstTimeSignup = true;
      _userName = null;
      _hasSeenWelcomeBack = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenWelcomeBack', true);
      // Clear previous user data
      await prefs.remove('userName');
      notifyListeners();
    }
  }

  Future<void> sendVerificationEmail() async {
    final user = _firebaseAuth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<bool> checkEmailVerified() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.reload();
      final refreshedUser = _firebaseAuth.currentUser;
      if (refreshedUser != null && refreshedUser.emailVerified) {
        _isEmailVerified = true;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  // ---------- Google Sign-In ----------

  Future<void> signInWithGoogle() async {
    // In 7.2.0+, we use initialize and authenticate
    // serverClientId is the Web client ID from google-services.json (client_type: 3)
    await _googleSignIn.initialize(
      serverClientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ?? '',
    );
    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

    // Get the auth details from the Google sign-in
    // In 7.2.0, authentication is a synchronous getter with only idToken
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    // Create a credential for Firebase using the idToken
    final OAuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase with the Google credential
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      final prefs = await SharedPreferences.getInstance();

      // Check if this is a "new" user for this device
      final existingEmail = prefs.getString('userEmail');
      final isNewUser = existingEmail != user.email;

      await prefs.setString('userEmail', user.email ?? '');
      if (user.displayName != null) {
        await prefs.setString('userName', user.displayName!);
      }

      _isLoggedIn = true;
      _userEmail = user.email;
      _userName = user.displayName;
      _isEmailVerified = true; // Google users are always verified
      _isGoogleUser = true;

      if (isNewUser) {
        _isFirstTimeSignup = true;
        _hasSeenWelcomeBack = true;
        await prefs.setBool('hasSeenWelcomeBack', true);
      } else {
        _isFirstTimeSignup = false;
        _hasSeenWelcomeBack = false;
        await prefs.setBool('hasSeenWelcomeBack', false);
      }

      notifyListeners();
    }
  }

  // Onboarding & Profile

  Future<void> completeOnboarding(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    _userName = name;
    _isFirstTimeSignup = false;

    // Also update Firebase display name
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.updateDisplayName(name);
    }

    notifyListeners();
  }

  Future<void> updateUserName(String newName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', newName);
    _userName = newName;

    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.updateDisplayName(newName);
    }

    notifyListeners();
  }

  // ---------- Logout ----------

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenWelcomeBack', false);

    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Error signing out from Google: $e');
    }

    await _firebaseAuth.signOut();

    _isLoggedIn = false;
    _hasSeenWelcomeBack = false;
    _isFirstTimeSignup = false;
    _isEmailVerified = false;
    _isGoogleUser = false;
    // We keep _userName and _userEmail for the "Welcome Back" experience
    notifyListeners();
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Error signing out from Google: $e');
    }

    await _firebaseAuth.signOut();

    _isLoggedIn = false;
    _userName = null;
    _userEmail = null;
    _isFirstTimeSignup = false;
    _isEmailVerified = false;
    _isGoogleUser = false;
    notifyListeners();
  }

  //  Error Helpers

  /// Returns a user-friendly error message for Firebase Auth exceptions.
  static String getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
