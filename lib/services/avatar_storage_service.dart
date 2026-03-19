import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class AvatarStorageService {
  static const String _bucket = 'avatars';

  SupabaseClient get _client => Supabase.instance.client;

  Future<String> uploadStudentAvatar({
    required String studentId,
    required Uint8List bytes,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'students/$studentId/$timestamp.jpg';

    await _client.storage.from(_bucket).uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(
        upsert: true,
        cacheControl: '3600',
        contentType: 'image/jpeg',
      ),
    );

    return _client.storage.from(_bucket).getPublicUrl(path);
  }
}