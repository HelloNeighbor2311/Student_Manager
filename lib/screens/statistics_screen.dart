import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:student_manager/models/student.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key, required this.studentsListenable});

  final ValueListenable<List<Student>> studentsListenable;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics & Reports')),
      body: ValueListenableBuilder<List<Student>>(
        valueListenable: studentsListenable,
        builder: (context, students, _) {
          final total = students.length;
          if (total == 0) {
            return const Center(
              child: Text('Chưa có dữ liệu sinh viên để thống kê.'),
            );
          }
          return _StatisticsBody(students: students);
        },
      ),
    );
  }
}

class _StatisticsBody extends StatelessWidget {
  const _StatisticsBody({required this.students});

  final List<Student> students;

  @override
  Widget build(BuildContext context) {
    final avgGpa =
        students.fold<double>(0, (sum, s) => sum + s.gpa) / students.length;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Total Students: ${students.length}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Average GPA: ${avgGpa.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
