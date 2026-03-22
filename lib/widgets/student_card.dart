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
    final isWarning = student.isWarning;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: isWarning
                ? const Color(0xFFDC2626).withValues(alpha: 0.2)
                : const Color(0x122A4258),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Card(
        color: isWarning ? const Color(0xFFFEE2E2) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: isWarning
              ? const BorderSide(
                  color: Color(0xFFDC2626),
                  width: 2,
                )
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
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
                    color: isWarning ? const Color(0xFF7F1D1D) : primary,
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
                        color: isWarning
                            ? const Color(0xFFDC2626).withValues(alpha: 0.14)
                            : primary.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'GPA ${student.gpa.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: isWarning ? const Color(0xFFDC2626) : primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isWarning) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.14),
                      border: Border.all(
                        color: const Color(0xFFDC2626),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning_rounded,
                          size: 12,
                          color: Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Cảnh báo: GPA < 2.0',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF7F1D1D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
