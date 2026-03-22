import 'dart:typed_data';

enum AcademicRank { excellent, good, fair, average }

enum SortBy { nameAZ, gpaDesc, studentId }

enum Gender { male, female, other }

Gender _genderFromString(String? value) {
  switch (value) {
    case 'male':
      return Gender.male;
    case 'female':
      return Gender.female;
    case 'other':
      return Gender.other;
    default:
      return Gender.other;
  }
}

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

  Student copyWith({
    String? id,
    String? name,
    String? studentCode,
    String? className,
    String? department,
    String? major,
    String? course,
    String? email,
    String? phone,
    String? address,
    DateTime? birthDate,
    Gender? gender,
    double? gpa,
    String? avatarUrl,
    Uint8List? avatarBytes,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      studentCode: studentCode ?? this.studentCode,
      className: className ?? this.className,
      department: department ?? this.department,
      major: major ?? this.major,
      course: course ?? this.course,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      gpa: gpa ?? this.gpa,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarBytes: avatarBytes ?? this.avatarBytes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'studentCode': studentCode,
      'className': className,
      'department': department,
      'major': major,
      'course': course,
      'email': email,
      'phone': phone,
      'address': address,
      'birthDate': birthDate.millisecondsSinceEpoch,
      'gender': gender.name,
      'gpa': gpa,
      'avatarUrl': avatarUrl,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    final birthRaw = map['birthDate'];
    final birthMillis = birthRaw is int
        ? birthRaw
        : int.tryParse('$birthRaw') ?? 0;
    final gpaRaw = map['gpa'];
    final gpaValue = gpaRaw is num ? gpaRaw.toDouble() : 0.0;

    return Student(
      id: '${map['id'] ?? ''}',
      name: '${map['name'] ?? ''}',
      studentCode: '${map['studentCode'] ?? ''}',
      className: '${map['className'] ?? ''}',
      department: '${map['department'] ?? ''}',
      major: '${map['major'] ?? ''}',
      course: '${map['course'] ?? ''}',
      email: '${map['email'] ?? ''}',
      phone: '${map['phone'] ?? ''}',
      address: '${map['address'] ?? ''}',
      birthDate: DateTime.fromMillisecondsSinceEpoch(birthMillis),
      gender: _genderFromString(map['gender']?.toString()),
      gpa: gpaValue,
      avatarUrl: map['avatarUrl']?.toString(),
    );
  }
}

