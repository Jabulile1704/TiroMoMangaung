import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isLoadingUserData = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoadingUserData => _isLoadingUserData;
  bool get isAuthenticated => _currentUser != null;
  String? get userType => _currentUser?.userType;

  // Email verification status
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) async {
    if (user != null) {
      await _loadUserData(user.uid);
    } else {
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<void> _loadUserData(String uid) async {
    try {
      _isLoadingUserData = true;
      notifyListeners();

      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      _isLoadingUserData = false;
      notifyListeners();
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String userType,
    String? companyName,
    String? registrationNumber,
    String? industryType,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Send email verification
        await credential.user!.sendEmailVerification();

        final now = DateTime.now();
        final userData = UserModel(
          id: credential.user!.uid,
          email: email,
          fullName: fullName,
          phoneNumber: phoneNumber,
          userType: userType,
          isActive: true,
          createdAt: now,
          updatedAt: now,
          companyName: companyName,
          registrationNumber: registrationNumber,
          industryType: industryType,
          verificationStatus: userType == 'employer' ? 'pending' : null,
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userData.toFirestore());

        _currentUser = userData;
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'An unexpected error occurred';
    }
    return 'Failed to create account';
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Save FCM token after successful login
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && _auth.currentUser != null) {
        await NotificationService.saveTokenToFirestore(
          _auth.currentUser!.uid,
          token,
        );
      }

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // SEND EMAIL VERIFICATION
  Future<String?> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in';
      if (user.emailVerified) return 'Email already verified';

      await user.sendEmailVerification();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Failed to send verification email';
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  // CHECK EMAIL VERIFICATION STATUS
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
    notifyListeners();
  }

  // SEND PASSWORD RESET EMAIL
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No account found with this email address';
        case 'invalid-email':
          return 'Invalid email address';
        default:
          return e.message ?? 'Failed to send reset email';
      }
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  // CHANGE PASSWORD (requires current password)
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        return 'No user logged in';
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      return null; // Success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
          return 'Current password is incorrect';
        case 'weak-password':
          return 'New password is too weak';
        case 'requires-recent-login':
          return 'Please log out and log in again to change password';
        default:
          return e.message ?? 'Failed to change password';
      }
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<String?> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? bio,
    List<String>? skills,
    String? workExperience,
    String? education,
    String? profilePictureUrl,
    String? companyName,
    String? companyDescription,
    String? website,
    String? documentUrl,
  }) async {
    try {
      if (_currentUser == null) return 'User not authenticated';

      _isLoading = true;
      notifyListeners();

      final updates = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (fullName != null) updates['fullName'] = fullName;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (bio != null) updates['bio'] = bio;
      if (skills != null) updates['skills'] = skills;
      if (workExperience != null) updates['workExperience'] = workExperience;
      if (education != null) updates['education'] = education;
      if (profilePictureUrl != null) {
        updates['profilePictureUrl'] = profilePictureUrl;
      }
      if (companyName != null) updates['companyName'] = companyName;
      if (companyDescription != null) {
        updates['companyDescription'] = companyDescription;
      }
      if (website != null) updates['website'] = website;

      // Add document URL to the documents array
      if (documentUrl != null) {
        final currentDocs = _currentUser!.documents ?? [];
        final newDoc = {
          'name': 'Document_${DateTime.now().millisecondsSinceEpoch}',
          'url': documentUrl,
          'uploadedAt': DateTime.now().toIso8601String(),
        };
        updates['documents'] = [...currentDocs, newDoc];
      }

      await _firestore
          .collection('users')
          .doc(_currentUser!.id)
          .update(updates);

      await _loadUserData(_currentUser!.id);
      return null; // Success
    } catch (e) {
      return 'Failed to update profile: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
