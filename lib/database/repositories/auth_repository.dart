import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../models/user/user.dart';
import '../../models/user/customer.dart';
import '../daos/user_dao.dart';

class AuthRepository {
  final UserDao _userDao;

  AuthRepository({required UserDao userDao}) : _userDao = userDao;

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<(User?, String?)> login(String email, String password) async {
    try {
      final credential = await firebase_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      final user = await _userDao.getUserById(uid);
      return (user, null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return (null, _mapFirebaseAuthError(e));
    } catch (e) {
      return (null, 'Loi he thong: ' + e.toString());
    }
  }

  Future<String?> register(Customer customer) async {
    try {
      final credential = await firebase_auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: customer.email,
        password: customer.password,
      );
      final uid = credential.user!.uid;

      final now = DateTime.now().millisecondsSinceEpoch;
      final fbUser = Customer(
        id: uid,
        username: customer.username,
        password: customer.password,
        fullName: customer.fullName,
        email: customer.email,
        phone: customer.phone,
        avatar: customer.avatar,
        membershipLevel: customer.membershipLevel,
        points: customer.points,
        totalSpent: customer.totalSpent,
        createdAt: now,
        updatedAt: now,
        lastLogin: now,
      );

      final rowsAffected = await _userDao.insertUser(fbUser);
      if (rowsAffected <= 0) {
        await firebase_auth.FirebaseAuth.instance.currentUser?.delete();
        return 'Khong the tao tai khoan. Vui long thu lai.';
      }

      return null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      return _mapFirebaseAuthError(e);
    } catch (e) {
      return 'Loi he thong: ' + e.toString();
    }
  }

  Future<void> logout() async {
    await firebase_auth.FirebaseAuth.instance.signOut();
  }

  Future<(User?, String?)> loginWithGoogle() async {
    try {
      print("=== GOOGLE SIGN IN DEBUG ===");

      print("1. Calling GoogleSignIn.instance.initialize()...");
      await GoogleSignIn.instance.initialize(
        serverClientId: '221774097926-qao52t5v05dp40vv60pjken5cmtbc864.apps.googleusercontent.com',
      );
      print("2. Initialize done. Calling GoogleSignIn.instance.authenticate()...");
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate(
        scopeHint: ['email', 'profile'],
      );
      print("3. Got googleUser: ${googleUser.displayName} <${googleUser.email}>");

      print("4. Getting authentication tokens...");
      final googleAuth = googleUser.authentication;
      print("5. idToken present: ${googleAuth.idToken != null}");

      print("6. Creating Firebase credential...");
      final firebase_auth.OAuthCredential credential =
          firebase_auth.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      print("7. Signing into Firebase with credential...");
      final firebase_auth.UserCredential userCredential =
          await firebase_auth.FirebaseAuth.instance.signInWithCredential(credential);
      final firebase_auth.User fbUser = userCredential.user!;
      print("8. Firebase user: ${fbUser.uid}");

      var localUser = await _userDao.getUserById(fbUser.uid);
      if (localUser == null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final newUser = Customer(
          id: fbUser.uid,
          username: fbUser.displayName ?? fbUser.email?.split('@').first ?? 'user',
          password: '',
          fullName: fbUser.displayName ?? '',
          email: fbUser.email ?? '',
          phone: '',
          avatar: fbUser.photoURL,
          createdAt: now,
          updatedAt: now,
          lastLogin: now,
        );
        await _userDao.insertUser(newUser);
        localUser = await _userDao.getUserById(fbUser.uid);
      }

      print("=== GOOGLE SIGN IN SUCCESS ===");
      return (localUser, null);
    } on PlatformException catch (e) {
      print("!!! PLATFORM EXCEPTION !!!");
      print("Code: ${e.code}");
      print("Message: ${e.message}");
      print("Details: ${e.details}");
      return (null, 'Loi he thong Google: ${e.code} - ${e.message}');
    } on GoogleSignInException catch (e) {
      print("!!! GOOGLE SIGN IN EXCEPTION !!!");
      print("Code: ${e.code}");
      print("Description: ${e.description}");
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return (null, 'Nguoi dung da huy dang nhap.');
      }
      return (null, 'Loi Google Sign-In: ${e.description}');
    } on firebase_auth.FirebaseAuthException catch (e) {
      print("!!! FIREBASE AUTH EXCEPTION !!!");
      print("Code: ${e.code}");
      print("Message: ${e.message}");
      return (null, _mapFirebaseAuthError(e));
    } catch (e) {
      print("!!! GENERAL EXCEPTION !!!");
      print(e.toString());
      return (null, 'Loi he thong: ' + e.toString());
    }
  }

  Future<User?> getUserProfile(String userId) async {
    return await _userDao.getUserById(userId);
  }

  Future<bool> updateUser(User user) async {
    try {
      final result = await _userDao.updateUser(user);
      return result > 0;
    } catch (e) {
      return false;
    }
  }

  String _mapFirebaseAuthError(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Tai khoan khong ton tai.';
      case 'wrong-password':
        return 'Sai mat khau.';
      case 'email-already-in-use':
        return 'Email da duoc su dung.';
      case 'invalid-email':
        return 'Email khong hop le.';
      case 'weak-password':
        return 'Mat khau phai co it nhat 6 ky tu.';
      case 'operation-not-allowed':
        return 'Phuong thuc dang nhap nay bi vo hieu hoa.';
      case 'user-disabled':
        return 'Tai khoan da bi vo hieu hoa.';
      case 'too-many-requests':
        return 'Qua nhieu yeu cau. Vui long thu lai sau.';
      case 'invalid-credential':
        return 'Thong tin dang nhap khong hop le.';
      default:
        return 'Da xay ra loi. Vui long thu lai.';
    }
  }
}
