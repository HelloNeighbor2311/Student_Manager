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
    required this.onTap,
  });

  final Student student;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAvatarTap;
  final VoidCallback onTap;

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
    final primary = Theme.of(context).colorScheme.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x122A4258),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          splashColor: primary.withValues(alpha: 0.4),
          highlightColor: primary.withValues(alpha: 0.2),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StudentAvatar(
                      student: student,
                      size: 48,
                      useHero: true,
                      onTap: onAvatarTap,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        student.department,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF60707D),
                        ),
                      ),
                    ),
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
                const SizedBox(height: 10),
                Text(
                  student.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 10),
                _MetaLine(
                  icon: Icons.badge_outlined,
                  text: 'MSSV: ${student.studentCode}',
                ),
                const SizedBox(height: 5),
                _MetaLine(
                  icon: Icons.groups_2_outlined,
                  text: 'Lớp: ${student.className}',
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: rankColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          rankText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: rankColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'GPA ${student.gpa.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6B7C89)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF40515C),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
