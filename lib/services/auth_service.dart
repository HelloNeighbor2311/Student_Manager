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
    return _googleSignIn ??= _initializeGoogleSignIn();
  }

  GoogleSignIn _initializeGoogleSignIn() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS uses the GIDClientID from Info.plist
      return GoogleSignIn(
        scopes: const ['email', 'profile'],
        clientId: '1024315521379-htg5572e49n4v9jflpki5nv857eeevod.apps.googleusercontent.com',
      );
    } else {
      // Android and other platforms: use google-services.json configuration
      return GoogleSignIn(
        scopes: const ['email', 'profile'],
      );
    }
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

      debugPrint('Starting Google Sign-In on ${defaultTargetPlatform.toString()}');
      
      final googleUser = await _googleSignInClient.signIn();
      if (googleUser == null) {
        throw StateError('Bạn đã hủy đăng nhập Google.');
      }

      debugPrint('Google user signed in: ${googleUser.email}');

      final googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null) {
        debugPrint('Access token is null');
        throw StateError('Không thể lấy access token từ Google. Vui lòng thử lại.');
      }
      
      if (googleAuth.idToken == null) {
        debugPrint('ID token is null');
        throw StateError('Không thể lấy ID token từ Google. Vui lòng thử lại.');
      }

      debugPrint('Got authentication tokens from Google');

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('Created Firebase credential, signing in...');

      final result = await _firebaseAuth.signInWithCredential(credential);
      
      debugPrint('Successfully signed in with Google: ${result.user?.email}');
      
      return result;
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth signInWithGoogle failed: ${e.code} | ${e.message}');
      throw StateError(_buildDetailedError(e));
    } catch (e) {
      debugPrint('Unexpected error during Google Sign-In: $e');
      throw StateError('Đăng nhập Google thất bại: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      if (_googleSignIn != null) {
        await _googleSignIn!.signOut().catchError((_) => null);
      }
      debugPrint('Successfully signed out');
    } catch (e) {
      debugPrint('Error during sign out: $e');
      rethrow;
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
