import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign Up
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String userType,
  }) async {
    try {
      // Create auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user model
      final user = UserModel(
        uid: userCredential.user!.uid,
        name: name,
        email: email,
        phone: phone,
        userType: userType,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(user.toMap());

      _currentUser = user;
      notifyListeners();
      return user;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign In with Email or Custom User ID
  Future<UserModel> signInWithIdentifier({
    required String identifier,
    required String password,
  }) async {
    try {
      late String email;

      // Determine if the identifier is an email or a customUserID
      if (identifier.contains('@')) {
        // Input is an Email
        email = identifier;
      } else {
        // Input is a Custom User ID, query Firestore to fetch the Email
        final querySnapshot = await _firestore
            .collection('users')
            .where('customUserID', isEqualTo: identifier)
            .get();

        if (querySnapshot.docs.isEmpty) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'No user found with this custom user ID',
          );
        }

        // Retrieve the email from the user document
        email = querySnapshot.docs.first.data()['email'];
      }

      // Authenticate using Email and Password
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Fetch the user data from Firestore
      final userData = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      // Convert Firestore data into a UserModel
      final user = UserModel.fromMap(
          userData.data() as Map<String, dynamic>, userCredential.user!.uid);
      _currentUser = user;
      notifyListeners();
      return user;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign In with Email
  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get user data from Firestore
      final userData = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      final user = UserModel.fromMap(
          userData.data() as Map<String, dynamic>, userCredential.user!.uid);
      _currentUser = user;
      notifyListeners();
      return user;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign In with Phone
  Future<void> signInWithPhone(
    String phoneNumber,
    Function(String) onCodeSent,
    Function(String) onError,
  ) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(_handleAuthException(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Verify Phone Code
  Future<UserModel> verifyPhoneCode(
      String verificationId, String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final userData = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      final user = UserModel.fromMap(
          userData.data() as Map<String, dynamic>, userCredential.user!.uid);
      _currentUser = user;
      notifyListeners();
      return user;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  String _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'This email is already registered';
        case 'invalid-email':
          return 'Invalid email address';
        case 'operation-not-allowed':
          return 'Operation not allowed';
        case 'weak-password':
          return 'Password is too weak';
        case 'user-disabled':
          return 'This account has been disabled';
        case 'user-not-found':
          return 'No user found with this email';
        case 'wrong-password':
          return 'Incorrect password';
        case 'invalid-verification-code':
          return 'Invalid verification code';
        default:
          return 'An error occurred. Please try again';
      }
    }
    return 'An error occurred. Please try again';
  }
}
