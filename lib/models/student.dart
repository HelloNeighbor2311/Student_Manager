import 'dart:typed_data';

enum AcademicRank { excellent, good, fair, average }

enum SortBy { nameAZ, gpaDesc, studentId }

enum Gender { male, female, other }

class Student {
  const Student({
    required this.id,
    required this.name,
    required this.studentCode,
    required this.className,
    required this.department,
    required this.major,
    required this.course,
    required this.email,
    required this.phone,
    required this.address,
    required this.birthDate,
    required this.gender,
    required this.gpa,
    this.avatarUrl,
    this.avatarBytes,
  });

  final String id;
  final String name;
  final String studentCode;
  final String className;
  final String department;
  final String major;
  final String course;
  final String email;
  final String phone;
  final String address;
  final DateTime birthDate;
  final Gender gender;
  final double gpa;
  final String? avatarUrl;
  final Uint8List? avatarBytes;

  AcademicRank get academicRank {
    if (gpa >= 3.6) return AcademicRank.excellent;
    if (gpa >= 3.2) return AcademicRank.good;
    if (gpa >= 2.5) return AcademicRank.fair;
    return AcademicRank.average;
  }

  String get academicRankLabel {
    switch (academicRank) {
      case AcademicRank.excellent:
        return 'Xuất sắc';
      case AcademicRank.good:
        return 'Giỏi';
      case AcademicRank.fair:
        return 'Khá';
      case AcademicRank.average:
        return 'Trung bình';
    }
  }

  String get genderLabel {
    switch (gender) {
      case Gender.male:
        return 'Nam';
      case Gender.female:
        return 'Nữ';
      case Gender.other:
        return 'Khác';
    }
  }
}
