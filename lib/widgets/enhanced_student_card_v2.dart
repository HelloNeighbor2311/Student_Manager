import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:student_manager/models/student.dart';
import 'package:student_manager/widgets/student_avatar.dart';
import 'package:student_manager/widgets/student_card_constants.dart';

class EnhancedStudentCard extends StatefulWidget {
  final Student student;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAvatarTap;
  final VoidCallback? onEmail;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;
  final VoidCallback? onNotify;
  final bool isSelected;
  final VoidCallback onSelectionChanged;

  const EnhancedStudentCard({
    super.key,
    required this.student,
    required this.onEdit,
    required this.onDelete,
    required this.onAvatarTap,
    this.onEmail,
    this.onCall,
    this.onMessage,
    this.onNotify,
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
  bool _isLongPressing = false;
  Timer? _quickPeekTimer;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: StudentCardConstants.swipeAnimationDuration,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _quickPeekTimer?.cancel();
    super.dispose();
  }

  // ===== Gesture Handlers =====
  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _swipeOffset = Offset(
        (_swipeOffset.dx + details.delta.dx)
            .clamp(-StudentCardConstants.swipeMaxOffset, 
                   StudentCardConstants.swipeMaxOffset),
        0,
      );
      _showLeftActions = _swipeOffset.dx < -StudentCardConstants.swipeActivationThreshold;
      _showRightActions = _swipeOffset.dx > StudentCardConstants.swipeActivationThreshold;
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (_swipeOffset.dx.abs() > StudentCardConstants.swipeActionThreshold) {
      _slideController.forward();
    } else {
      _resetSwipe();
    }
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    HapticFeedback.mediumImpact();
    setState(() => _isLongPressing = true);
    widget.onSelectionChanged();
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    setState(() => _isLongPressing = false);
  }

  void _handlePointerDown(PointerDownEvent event) {
    _quickPeekTimer?.cancel();
    _quickPeekTimer = Timer(StudentCardConstants.quickPeekDelay, () {
      if (!mounted) return;
      if (_swipeOffset.dx == 0 && !_isLongPressing) {
        // TODO: Implement quick peek preview
      }
    });
  }

  void _handlePointerUp(PointerUpEvent event) {
    _quickPeekTimer?.cancel();
  }

  // ===== Helper Methods =====
  void _resetSwipe() {
    _slideController.reverse();
    setState(() {
      _swipeOffset = Offset.zero;
      _showLeftActions = false;
      _showRightActions = false;
    });
  }

  void _executeAction(VoidCallback action) {
    _resetSwipe();
    action();
  }

  // ===== Build Methods =====
  @override
  Widget build(BuildContext context) {
    final rank = widget.student.academicRank;

    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      child: GestureDetector(
        onHorizontalDragUpdate: _handleHorizontalDragUpdate,
        onHorizontalDragEnd: _handleHorizontalDragEnd,
        onLongPressStart: _handleLongPressStart,
        onLongPressEnd: _handleLongPressEnd,
        child: Stack(
          children: [
            _buildSwipeBackground(context),
            _buildMainCard(context, rank),
          ],
        ),
      ),
    );
  }

  /// Build background actions when swiping
  Widget _buildSwipeBackground(BuildContext context) {
    return Positioned.fill(
      child: Row(
        children: [
          Expanded(
            child: Visibility(
              visible: _showRightActions,
              child: _buildSwipeActionPanel(
                color: StudentCardConstants.rightSwipeColor,
                actions: [
                  if (widget.onCall != null)
                    _SwipeActionButton(
                      icon: Icons.call,
                      onTap: () => _executeAction(widget.onCall!),
                    ),
                  if (widget.onMessage != null)
                    _SwipeActionButton(
                      icon: Icons.message,
                      onTap: () => _executeAction(widget.onMessage!),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Visibility(
              visible: _showLeftActions,
              child: _buildSwipeActionPanel(
                color: StudentCardConstants.leftSwipeColor,
                actions: [
                  if (widget.onNotify != null)
                    _SwipeActionButton(
                      icon: Icons.notifications,
                      onTap: () => _executeAction(widget.onNotify!),
                    ),
                  if (widget.onEmail != null)
                    _SwipeActionButton(
                      icon: Icons.mail,
                      onTap: () => _executeAction(widget.onEmail!),
                    ),
                ],
                alignment: MainAxisAlignment.end,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build colored panel with action buttons
  Widget _buildSwipeActionPanel({
    required Color color,
    required List<Widget> actions,
    MainAxisAlignment alignment = MainAxisAlignment.start,
  }) {
    return Container(
      color: color,
      child: Row(
        mainAxisAlignment: alignment,
        children: actions,
      ),
    );
  }

  /// Build main card with all content
  Widget _buildMainCard(BuildContext context, AcademicRank rank) {
    final isWarning = widget.student.isWarning;
    return Transform.translate(
      offset: _swipeOffset,
      child: Card(
        elevation: 2,
        color: isWarning
            ? StudentCardConstants.warningBackgroundColor
            : StudentCardConstants.whiteBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StudentCardConstants.cardBorderRadius),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(StudentCardConstants.cardBorderRadius),
            border: Border.all(
              color: isWarning
                  ? StudentCardConstants.warningBorderColor
                  : widget.isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(StudentCardConstants.cardPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: StudentCardConstants.spacingLarge),
                _buildStudentInfo(context, rank),
                const SizedBox(height: StudentCardConstants.spacingXLarge),
                _buildGPABadges(rank),
                const SizedBox(height: StudentCardConstants.spacingMedium),
                _buildDepartmentInfo(),
                if (isWarning) ...[
                  const SizedBox(height: StudentCardConstants.spacingLarge),
                  _buildWarningBanner(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build header with avatar, selection checkbox, and menu
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        if (widget.isSelected)
          Padding(
            padding: const EdgeInsets.only(right: StudentCardConstants.spacingMedium),
            child: Checkbox(
              value: widget.isSelected,
              onChanged: (_) => widget.onSelectionChanged(),
            ),
          ),
        _AvatarWithBorder(
          student: widget.student,
          rankColor: widget.student.academicRank.badgeColor,
          onTap: widget.onAvatarTap,
        ),
        const Spacer(),
        _buildContextMenu(context),
      ],
    );
  }

  /// Build student name, code, and class info
  Widget _buildStudentInfo(BuildContext context, AcademicRank rank) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.student.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: StudentCardConstants.spacingMedium),
        _buildStudentCodeAndClass(),
      ],
    );
  }

  /// Build GPA gem and academic rank badges
  Widget _buildGPABadges(AcademicRank rank) {
    final rankColor = rank.badgeColor;
    final textColor = rank.textColor;

    return Row(
      children: [
        // GPA Gem
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: StudentCardConstants.spacingLarge,
            vertical: StudentCardConstants.spacingSmall,
          ),
          decoration: BoxDecoration(
            color: rank.lightenBadgeColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: rankColor, width: 1.5),
          ),
          child: Text(
            widget.student.gpa.toStringAsFixed(2),
            style: TextStyle(
              fontSize: StudentCardConstants.fontSizeMedium,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(width: StudentCardConstants.spacingMedium),
        // Academic Rank Badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: StudentCardConstants.spacingMedium,
            vertical: StudentCardConstants.spacingSmall,
          ),
          decoration: BoxDecoration(
            color: rank.lightBadgeColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.student.academicRankLabel,
            style: TextStyle(
              fontSize: StudentCardConstants.fontSizeSmall,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  /// Build student code and class
  Widget _buildStudentCodeAndClass() {
    return Row(
      children: [
        const Icon(Icons.badge, size: StudentCardConstants.iconSizeSmall, 
                  color: StudentCardConstants.greyText),
        const SizedBox(width: StudentCardConstants.spacingSmall),
        Text(
          widget.student.studentCode,
          style: const TextStyle(
            fontSize: StudentCardConstants.fontSizeSmall,
            color: StudentCardConstants.greyText,
          ),
        ),
        const SizedBox(width: StudentCardConstants.spacingXLarge),
        const Icon(Icons.class_, size: StudentCardConstants.iconSizeSmall,
                  color: StudentCardConstants.greyText),
        const SizedBox(width: StudentCardConstants.spacingSmall),
        Text(
          widget.student.className,
          style: const TextStyle(
            fontSize: StudentCardConstants.fontSizeSmall,
            color: StudentCardConstants.greyText,
          ),
        ),
      ],
    );
  }

  /// Build department info
  Widget _buildDepartmentInfo() {
    return Text(
      widget.student.department,
      style: const TextStyle(
        fontSize: StudentCardConstants.fontSizeSmall,
        color: StudentCardConstants.greyText,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  /// Build warning banner for low GPA students (GPA < 2.0)
  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: StudentCardConstants.spacingMedium,
        vertical: StudentCardConstants.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: StudentCardConstants.warningBackgroundColor,
        border: Border.all(
          color: StudentCardConstants.warningBorderColor,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_rounded,
            size: StudentCardConstants.iconSizeSmall,
            color: StudentCardConstants.warningIconColor,
          ),
          const SizedBox(width: StudentCardConstants.spacingSmall),
          Text(
            'Cảnh báo: GPA dưới 2.0',
            style: TextStyle(
              fontSize: StudentCardConstants.fontSizeSmall,
              fontWeight: FontWeight.w600,
              color: StudentCardConstants.warningTextColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Build context menu (3 dots)
  Widget _buildContextMenu(BuildContext context) {
    return PopupMenuButton<String>(
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
              Icon(Icons.edit, size: StudentCardConstants.iconSizeMenu),
              SizedBox(width: StudentCardConstants.spacingMedium),
              Text('Sửa'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'email',
          child: Row(
            children: [
              Icon(Icons.mail, size: StudentCardConstants.iconSizeMenu),
              SizedBox(width: StudentCardConstants.spacingMedium),
              Text('Gửi email'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'call',
          child: Row(
            children: [
              Icon(Icons.call, size: StudentCardConstants.iconSizeMenu),
              SizedBox(width: StudentCardConstants.spacingMedium),
              Text('Gọi'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: StudentCardConstants.iconSizeMenu,
                  color: StudentCardConstants.errorRed),
              SizedBox(width: StudentCardConstants.spacingMedium),
              Text('Xóa', style: TextStyle(color: StudentCardConstants.errorRed)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Swipe action button component
class _SwipeActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SwipeActionButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: StudentCardConstants.actionButtonWidth,
      child: Material(
        color: StudentCardConstants.transparentColor,
        child: InkWell(
          onTap: onTap,
          child: Icon(
            icon,
            color: StudentCardConstants.swipeActionIconColor,
            size: StudentCardConstants.iconSizeActionButton,
          ),
        ),
      ),
    );
  }
}

/// Avatar with gradient border based on academic rank
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
