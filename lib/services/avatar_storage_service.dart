import 'dart:typed_data';

// Supabase dependency not available - this service is disabled
// import 'package:supabase_flutter/supabase_flutter.dart';

class AvatarStorageService {
  // Supabase storage disabled

  Future<String> uploadStudentAvatar({
    required String studentId,
    required Uint8List bytes,
  }) async {
    // Returning empty string - Supabase storage is disabled
    return '';
  }
}
