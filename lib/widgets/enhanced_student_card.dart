import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:student_manager/models/student.dart';
import 'package:student_manager/widgets/student_avatar.dart';

class EnhancedStudentCard extends StatefulWidget {
  final Student student;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAvatarTap;
  final VoidCallback? onEmail;
  final VoidCallback? onCall;
  final VoidCallback? onCopy;
  final VoidCallback? onNote;
  final bool isSelected;
  final VoidCallback onSelectionChanged;

  const EnhancedStudentCard({
    super.key,
    required this.student,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onAvatarTap,
    this.onEmail,
    this.onCall,
    this.onCopy,
    this.onNote,
    this.isSelected = false,
    required this.onSelectionChanged,
  });

  @override
  State<EnhancedStudentCard> createState() => _EnhancedStudentCardState();
}

class _EnhancedStudentCardState extends State<EnhancedStudentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  Offset _swipeOffset = Offset.zero;
  bool _showLeftActions = false;
  bool _showRightActions = false;
  
  // Long press & quick peek tracking
  late Timer? _quickPeekTimer;
  bool _isLongPressing = false;
  // OverlayEntry? _quickPeekOverlay;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _quickPeekTimer = null;
  }

  @override
  void dispose() {
    _slideController.dispose();
    _quickPeekTimer?.cancel();
    // _quickPeekOverlay?.remove();
    super.dispose();
  }

  void _resetSwipe() {
    _slideController.reverse();
    setState(() {
      _swipeOffset = Offset.zero;
      _showLeftActions = false;
      _showRightActions = false;
    });
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _swipeOffset = Offset(
        (_swipeOffset.dx + details.delta.dx).clamp(-120.0, 120.0),
        0,
      );
      _showLeftActions = _swipeOffset.dx < -30;
      _showRightActions = _swipeOffset.dx > 30;
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (_swipeOffset.dx.abs() > 60) {
      _slideController.forward();
    } else {
      _resetSwipe();
    }
  }

  void _executeLeftAction(VoidCallback action) {
    _resetSwipe();
    action();
  }

  void _executeRightAction(VoidCallback action) {
    _resetSwipe();
    action();
  }

  Color _getAcademicRankColor(AcademicRank rank) {
    switch (rank) {
      case AcademicRank.excellent:
        return const Color(0xFFD4AF37); // Gold
      case AcademicRank.good:
        return const Color(0xFF00A86B); // Green
      case AcademicRank.fair:
        return const Color(0xFFFF9500); // Orange
      case AcademicRank.average:
        return const Color(0xFFE53935); // Red
    }
  }

  Color _getTextColorForRank(AcademicRank rank) {
    switch (rank) {
      case AcademicRank.excellent:
        return const Color(0xFF8B6F47);
      case AcademicRank.good:
        return const Color(0xFF00563B);
      case AcademicRank.fair:
        return const Color(0xFFC65911);
      case AcademicRank.average:
        return const Color(0xFF8B0000);
    }
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    setState(() {
      _isLongPressing = true;
      // _pressPosition = details.globalPosition;
    });

    // Enter multi-select mode
    widget.onSelectionChanged();
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    setState(() => _isLongPressing = false);
  }

  void _handlePointerDown(PointerDownEvent event) {
    _quickPeekTimer?.cancel();
    // _quickPeekOverlay?.remove();
    // _quickPeekOverlay = null;

    _quickPeekTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      // Show quick peek only if not in swipe or long press
      if (_swipeOffset.dx == 0 && !_isLongPressing) {
        _showQuickPeek(event.position);
      }
    });
  }

  void _handlePointerUp(PointerUpEvent event) {
    _quickPeekTimer?.cancel();
    // _quickPeekOverlay?.remove();
    // _quickPeekOverlay = null;
  }

  void _showQuickPeek(Offset position) {
    // _quickPeekOverlay = OverlayEntry(
    //   builder: (context) =>
    //       QuickPeekPreview(student: widget.student, position: position),
    // );
    //
    // Overlay.of(context).insert(_quickPeekOverlay!);
    //
    // Future.delayed(const Duration(seconds: 3), () {
    //   _quickPeekOverlay?.remove();
    //   _quickPeekOverlay = null;
    // });
  }

  @override
  Widget build(BuildContext context) {
    final rank = widget.student.academicRank;
    final rankColor = _getAcademicRankColor(rank);
    final textColor = _getTextColorForRank(rank);

    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      child: GestureDetector(
        onTap: _swipeOffset.dx == 0 ? widget.onTap : null,
        onHorizontalDragUpdate: _handleHorizontalDragUpdate,
        onHorizontalDragEnd: _handleHorizontalDragEnd,
        onLongPressStart: _handleLongPressStart,
        onLongPressEnd: _handleLongPressEnd,
        child: Stack(
        children: [
          // Swipe action background
          Positioned.fill(
            child: Row(
              children: [
                // Right swipe actions (expand from left) - Call and Email
                Expanded(
                  child: Visibility(
                    visible: _showRightActions,
                    child: Container(
                      color: const Color(0xFF00A86B),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 60,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: widget.onCall != null
                                    ? () => _executeRightAction(widget.onCall!)
                                    : null,
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.phone,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Gọi',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: widget.onEmail != null
                                    ? () =>
                                          _executeRightAction(widget.onEmail!)
                                    : null,
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.email,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Email',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Left swipe actions (expand from right) - Copy and Note
                Expanded(
                  child: Visibility(
                    visible: _showLeftActions,
                    child: Container(
                      color: const Color(0xFF0066CC),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: 60,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: widget.onCopy != null
                                    ? () => _executeLeftAction(widget.onCopy!)
                                    : null,
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.copy,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Sao chép',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: widget.onNote != null
                                    ? () => _executeLeftAction(widget.onNote!)
                                    : null,
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.note_add,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Ghi chú',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main card
          Transform.translate(
            offset: _swipeOffset,
            child: Card(
              elevation: 2,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: widget.isSelected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        )
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with avatar and menu
                      Row(
                        children: [
                          // Selection checkbox (visible in multi-select mode)
                          if (widget.isSelected)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Checkbox(
                                value: widget.isSelected,
                                onChanged: (_) => widget.onSelectionChanged(),
                              ),
                            ),
                          // Avatar with gradient border
                          _AvatarWithBorder(
                            student: widget.student,
                            rankColor: rankColor,
                            onTap: widget.onAvatarTap,
                          ),
                          const Spacer(),
                          // Context menu
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              Future<void>.delayed(Duration.zero, () {
                                if (value == 'edit') widget.onEdit();
                                if (value == 'delete') widget.onDelete();
                                if (value == 'email') widget.onEmail?.call();
                                if (value == 'call') widget.onCall?.call();
                              });
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 18),
                                    SizedBox(width: 8),
                                    Text('Sửa'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'email',
                                child: Row(
                                  children: [
                                    Icon(Icons.mail, size: 18),
                                    SizedBox(width: 8),
                                    Text('Gửi email'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'call',
                                child: Row(
                                  children: [
                                    Icon(Icons.call, size: 18),
                                    SizedBox(width: 8),
                                    Text('Gọi'),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Xóa',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Student name
                      Text(
                        widget.student.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      // Student code and class
                      Row(
                        children: [
                          const Icon(Icons.badge, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            widget.student.studentCode,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.class_,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.student.className,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // GPA and academic rank badge
                      Row(
                        children: [
                          // GPA gem
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: rankColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: rankColor, width: 1.5),
                            ),
                            child: Text(
                              widget.student.gpa.toStringAsFixed(2),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Academic rank badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: rankColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.student.academicRankLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Department info
                      Text(
                        widget.student.department,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}

class _AvatarWithBorder extends StatelessWidget {
  final Student student;
  final Color rankColor;
  final VoidCallback onTap;

  const _AvatarWithBorder({
    required this.student,
    required this.rankColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [rankColor, rankColor.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: rankColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: StudentAvatar(
          student: student,
          size: 52,
          useHero: true,
          onTap: onTap,
        ),
      ),
    );
  }
}
