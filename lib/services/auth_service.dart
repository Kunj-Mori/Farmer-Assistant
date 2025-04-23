import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  AuthService() {
    // Enable offline persistence
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    
    _auth.authStateChanges().listen((user) {
      _user = user;
      if (user != null) {
        _loadUserData();
      } else {
        _userData = null;
      }
      notifyListeners();
    });
  }

  User? get currentUser => _user;
  Map<String, dynamic>? get userData => _userData;
  User? get currentUserAuth => _auth.currentUser;

  Future<void> _loadUserData() async {
    if (_user == null) return;
    
    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        _userData = doc.data();
        notifyListeners();
      } else {
        print('No user data found in Firestore');
      }
    } catch (e) {
      print('Error loading user data: $e');
      // If offline, try to get cached data
      try {
        final doc = await _firestore.collection('users').doc(_user!.uid)
          .get(const GetOptions(source: Source.cache));
        if (doc.exists) {
          _userData = doc.data();
          notifyListeners();
        }
      } catch (e) {
        print('Error loading cached user data: $e');
      }
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String state,
    required String district,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Create user with email and password
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Initialize user data
      final userData = {
        'email': email,
        'state': state,
        'district': district,
        'username': email.split('@')[0], // Default username from email
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Store user data in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);

      // Update local state
      _user = userCredential.user;
      _userData = userData;
      
      // Notify listeners of state change
      notifyListeners();

      return userCredential;
    } catch (e) {
      print('Error during sign up: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Load user data immediately after sign in
      await _loadUserData();

      return userCredential;
    } catch (e) {
      print('Error during sign in: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _userData = null;
    } catch (e) {
      print('Error during sign out: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getUserPreferences() async {
    if (_user == null) throw Exception('No user logged in');
    
    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        return doc.data() ?? {};
      }
      return {};
    } catch (e) {
      print('Error getting user preferences: $e');
      // If offline, try to get cached data
      try {
        final doc = await _firestore.collection('users').doc(_user!.uid)
          .get(const GetOptions(source: Source.cache));
        if (doc.exists) {
          return doc.data() ?? {};
        }
      } catch (e) {
        print('Error getting cached user preferences: $e');
      }
      return {};
    }
  }

  // Update user preferences
  Future<void> updateUserPreferences({
    required String username,
    required String state,
    required String district,
    DateTime? dob,
  }) async {
    try {
      // Update display name in Firebase Auth
      await currentUserAuth?.updateDisplayName(username);

      // Update user preferences in Firestore
      await _firestore.collection('users').doc(currentUserAuth!.uid).update({
        'username': username,
        'state': state,
        'district': district,
        'dob': dob,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user preferences: $e');
      rethrow;
    }
  }

  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
    String username,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(username);

      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'username': username,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> updateUserProfile({
    required String username,
    required String email,
    required String phone,
    String? location,
    String? description,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'No user logged in';

      // Update Auth profile
      if (email != user.email) {
        await user.updateEmail(email);
      }
      await user.updateDisplayName(username);

      // Update Firestore profile
      await _firestore.collection('users').doc(user.uid).update({
        'username': username,
        'email': email,
        'phone': phone,
        'location': location,
        'description': description,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  String _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email';
        case 'wrong-password':
          return 'Wrong password provided';
        case 'email-already-in-use':
          return 'Email is already registered';
        case 'invalid-email':
          return 'Invalid email address';
        case 'weak-password':
          return 'Password is too weak';
        case 'requires-recent-login':
          return 'Please log in again to update your profile';
        default:
          return e.message ?? 'An error occurred';
      }
    }
    return e.toString();
  }

  Future<Map<String, dynamic>> getUserData() async {
    if (_userData != null) return _userData!;

    try {
      _isLoading = true;
      notifyListeners();

      if (currentUserAuth == null) throw 'No user logged in';

      final doc = await _firestore
          .collection('users')
          .doc(currentUserAuth!.uid)
          .get();

      if (!doc.exists) throw 'User data not found';

      _userData = doc.data();
      return _userData!;
    } catch (e) {
      print('Error getting user data: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserData(Map<String, dynamic> userData) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (currentUserAuth == null) throw 'No user logged in';

      await _firestore
          .collection('users')
          .doc(currentUserAuth!.uid)
          .update(userData);

      _userData = {...?_userData, ...userData};
    } catch (e) {
      print('Error updating user data: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 