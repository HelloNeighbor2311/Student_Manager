import 'package:flutter/material.dart';
import 'package:student_manager/models/student.dart';

String studentAvatarHeroTag(String studentId) => 'student-avatar-$studentId';

class StudentAvatar extends StatelessWidget {
  const StudentAvatar({
    super.key,
    required this.student,
    this.size = 44,
    this.useHero = false,
    this.onTap,
  });

  final Student student;
  final double size;
  final bool useHero;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fallbackText = student.name.trim().isEmpty
        ? '?'
        : student.name.trim().substring(0, 1).toUpperCase();
    final hasUrl = student.avatarUrl?.isNotEmpty ?? false;

    final avatar = SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: hasUrl
            ? Image.network(
                student.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _AvatarFallback(text: fallbackText),
              )
            : _AvatarFallback(text: fallbackText),
      ),
    );

    final wrapped = useHero
        ? Hero(tag: studentAvatarHeroTag(student.id), child: avatar)
        : avatar;

    if (onTap == null) return wrapped;
    return InkWell(
      borderRadius: BorderRadius.circular(size / 2),
      onTap: onTap,
      child: wrapped,
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFDAEEF1),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF10454B),
        ),
      ),
    );
  }
}
