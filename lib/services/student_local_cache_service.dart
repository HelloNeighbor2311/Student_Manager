import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_manager/models/student.dart';

class StudentLocalCacheService {
  static const String _studentsKey = 'students_cache_v1';

  Future<List<Student>> loadStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_studentsKey);
    if (raw == null || raw.trim().isEmpty) {
      return <Student>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <Student>[];
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Student.fromMap)
          .toList(growable: false);
    } catch (_) {
      return <Student>[];
    }
  }

  Future<void> saveStudents(List<Student> students) async {
    final prefs = await SharedPreferences.getInstance();
    final data = students.map((s) => s.toMap()).toList(growable: false);
    await prefs.setString(_studentsKey, jsonEncode(data));
  }
}
