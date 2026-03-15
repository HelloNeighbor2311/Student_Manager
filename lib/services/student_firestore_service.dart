import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:student_manager/models/student.dart';

class StudentFirestoreService {
  static const Duration _requestTimeout = Duration(seconds: 8);

  StudentFirestoreService({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  FirebaseFirestore get _firestoreOrThrow {
    if (!isFirebaseInitialized) {
      throw StateError('Firebase chưa được khởi tạo.');
    }
    return _firestoreOverride ?? FirebaseFirestore.instance;
  }

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestoreOrThrow.collection('students');

  bool get isFirebaseInitialized => Firebase.apps.isNotEmpty;

  Future<void> seedIfEmpty(List<Student> seeds) async {
    if (!isFirebaseInitialized) {
      return;
    }
    final firestore = _firestoreOrThrow;
    final snapshot = await _collection.limit(1).get().timeout(_requestTimeout);
    if (snapshot.docs.isNotEmpty) {
      return;
    }

    final batch = firestore.batch();
    for (final student in seeds) {
      final ref = _collection.doc(student.id);
      batch.set(ref, student.toMap());
    }
    await batch.commit().timeout(_requestTimeout);
  }

  Future<List<Student>> fetchStudents() async {
    if (!isFirebaseInitialized) {
      throw StateError('Firebase chưa được khởi tạo.');
    }

    final snapshot = await _collection.get().timeout(_requestTimeout);
    final students = snapshot.docs
        .map((doc) => Student.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
    students.sort((a, b) => a.name.compareTo(b.name));
    return students;
  }

  Future<void> addStudent(Student student) async {
    if (!isFirebaseInitialized) {
      throw StateError('Firebase chưa được khởi tạo.');
    }
    await _collection
        .doc(student.id)
        .set(student.toMap())
        .timeout(_requestTimeout);
  }

  Future<void> updateStudent(Student student) async {
    if (!isFirebaseInitialized) {
      throw StateError('Firebase chưa được khởi tạo.');
    }
    await _collection
        .doc(student.id)
        .update(student.toMap())
        .timeout(_requestTimeout);
  }

  Future<void> deleteStudent(String id) async {
    if (!isFirebaseInitialized) {
      throw StateError('Firebase chưa được khởi tạo.');
    }
    await _collection.doc(id).delete().timeout(_requestTimeout);
  }

  Future<List<Student>> fetchOrSeedStudents(List<Student> seeds) async {
    final current = await fetchStudents();
    if (current.isNotEmpty) {
      return current;
    }

    await seedIfEmpty(seeds);
    return fetchStudents();
  }
}
