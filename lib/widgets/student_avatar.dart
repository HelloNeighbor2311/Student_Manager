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
    final hasBytes = student.avatarBytes != null;
    final hasUrl = student.avatarUrl?.isNotEmpty ?? false;

    final avatar = Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF76C9CC), Color(0xFF3A8FCA)],
        ),
      ),
      child: ClipOval(
        child: hasBytes
            ? Image.memory(student.avatarBytes!, fit: BoxFit.cover)
            : hasUrl
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD8F0F7), Color(0xFFC9E4F4)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF145061),
        ),
      ),
    );
  }
}
