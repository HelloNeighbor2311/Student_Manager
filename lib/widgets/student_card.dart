import 'package:flutter/material.dart';
import 'package:student_manager/models/student.dart';
import 'package:student_manager/widgets/student_avatar.dart';

class StudentCard extends StatelessWidget {
  const StudentCard({
    super.key,
    required this.student,
    required this.onEdit,
    required this.onDelete,
    required this.onAvatarTap,
  });

  final Student student;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAvatarTap;

  (String, Color) _rankStyle(AcademicRank rank) {
    switch (rank) {
      case AcademicRank.excellent:
        return ('Xuất sắc', const Color(0xFF0A8F5A));
      case AcademicRank.good:
        return ('Giỏi', const Color(0xFFC99A00));
      case AcademicRank.fair:
        return ('Khá', const Color(0xFFE67E22));
      case AcademicRank.average:
        return ('Trung bình', const Color(0xFF7F8C8D));
    }
  }

  @override
  Widget build(BuildContext context) {
    final (rankText, rankColor) = _rankStyle(student.academicRank);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StudentAvatar(
                  student: student,
                  useHero: true,
                  onTap: onAvatarTap,
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    // Delay action until popup menu route is fully dismissed.
                    Future<void>.delayed(Duration.zero, () {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    });
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Sửa')),
                    PopupMenuItem(value: 'delete', child: Text('Xóa')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              student.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'MSSV: ${student.studentCode}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Lớp: ${student.className}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'GPA: ${student.gpa.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: rankColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                rankText,
                style: TextStyle(
                  color: rankColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
