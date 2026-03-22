import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn;

  final FirebaseAuth _firebaseAuth;
  GoogleSignIn? _googleSignIn;

  GoogleSignIn get _googleSignInClient {
    return _googleSignIn ??= GoogleSignIn(scopes: const ['email']);
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth signInWithEmailPassword failed: ${e.code} | ${e.message}');
      throw StateError(_buildDetailedError(e));
    }
  }

  Future<UserCredential> registerWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth registerWithEmailPassword failed: ${e.code} | ${e.message}');
      throw StateError(_buildDetailedError(e));
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        return await _firebaseAuth.signInWithPopup(provider);
      }

      final googleUser = await _googleSignInClient.signIn();
      if (googleUser == null) {
        throw StateError('Bạn đã hủy đăng nhập Google.');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth signInWithGoogle failed: ${e.code} | ${e.message}');
      throw StateError(_buildDetailedError(e));
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    if (_googleSignIn != null) {
      await _googleSignIn!.signOut().catchError((_) => null);
    }
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa.';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng.';
      case 'email-already-in-use':
        return 'Email đã được sử dụng.';
      case 'weak-password':
        return 'Mật khẩu quá yếu (tối thiểu 6 ký tự).';
      case 'operation-not-allowed':
        return 'Phương thức đăng nhập chưa được bật trong Firebase Console.';
      case 'account-exists-with-different-credential':
        return 'Email đã tồn tại với phương thức đăng nhập khác.';
      case 'popup-closed-by-user':
        return 'Bạn đã đóng cửa sổ đăng nhập Google.';
      case 'network-request-failed':
        return 'Không có kết nối mạng. Vui lòng thử lại.';
      default:
        return e.message ?? 'Đăng nhập thất bại. Vui lòng thử lại.';
    }
  }

  String _buildDetailedError(FirebaseAuthException e) {
    final friendly = _mapFirebaseAuthError(e);
    final technicalMessage = e.message == null || e.message!.trim().isEmpty
        ? 'Không có mô tả chi tiết từ Firebase.'
        : e.message!.trim();

    return '$friendly\n\nChi tiết lỗi: [${e.code}] $technicalMessage';
  }
}
