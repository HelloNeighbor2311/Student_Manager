import 'package:flutter/material.dart';

/// Animated shimmer loading skeleton
class ShimmerLoader extends StatefulWidget {
  final int itemCount;
  final double itemHeight;

  const ShimmerLoader({super.key, this.itemCount = 5, this.itemHeight = 160});

  @override
  State<ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: widget.itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShimmerCard(animation: _controller, height: widget.itemHeight),
        );
      },
    );
  }
}

class ShimmerCard extends StatelessWidget {
  final AnimationController animation;
  final double height;

  const ShimmerCard({super.key, required this.animation, required this.height});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          height: height,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: _buildShimmerContent(),
        );
      },
    );
  }

  Widget _buildShimmerContent() {
    return Row(
      children: [
        // Avatar skeleton
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: _getShimmerColor(),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        // Text skeleton
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: double.infinity,
                height: 16,
                decoration: BoxDecoration(
                  color: _getShimmerColor(),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 200,
                height: 12,
                decoration: BoxDecoration(
                  color: _getShimmerColor(),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getShimmerColor(),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 60,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _getShimmerColor(),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getShimmerColor() {
    return Color.lerp(
      const Color(0xFFE8E8E8),
      const Color(0xFFF5F5F5),
      animation.value,
    )!;
  }
}

/// Empty state widget
class EmptyStateWidget extends StatelessWidget {
  final VoidCallback onAddStudent;
  final VoidCallback? onImportExcel;

  const EmptyStateWidget({
    super.key,
    required this.onAddStudent,
    this.onImportExcel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_outlined,
                size: 60,
                color: Color(0xFF006D77),
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              'Chưa có sinh viên nào',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Subtitle
            Text(
              'Bắt đầu bằng cách thêm sinh viên mới hoặc import danh sách từ Excel',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            // Action buttons
            Column(
              children: [
                FilledButton.icon(
                  onPressed: onAddStudent,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Thêm sinh viên'),
                ),
                const SizedBox(height: 12),
                if (onImportExcel != null)
                  OutlinedButton.icon(
                    onPressed: onImportExcel,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Import Excel'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Network error banner
class NetworkErrorBanner extends StatelessWidget {
  final VoidCallback onRetry;

  const NetworkErrorBanner({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_outlined, color: Color(0xFF8A5100)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Mất kết nối mạng. Dữ liệu từ bộ nhớ tạm.',
              style: TextStyle(color: Color(0xFF8A5100), fontSize: 13),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

/// Enhanced filter chip
class FilterChip2 extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onSelected;

  const FilterChip2({
    super.key,
    required this.label,
    this.count,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return AnimatedScale(
      scale: selected ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: InputChip(
        label: Text(count != null ? '$label ($count)' : label),
        selected: selected,
        onPressed: onSelected,
        backgroundColor: Colors.white,
        selectedColor: primaryColor.withValues(alpha: 0.15),
        side: BorderSide(
          color: selected ? primaryColor : Colors.grey[300]!,
          width: selected ? 2 : 1,
        ),
        labelStyle: TextStyle(
          color: selected ? primaryColor : Colors.black87,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}

/// FAB menu button
class FABMenuButton extends StatefulWidget {
  final VoidCallback onAddStudent;
  final VoidCallback onImportExcel;
  final VoidCallback? onScanCard;

  const FABMenuButton({
    super.key,
    required this.onAddStudent,
    required this.onImportExcel,
    this.onScanCard,
  });

  @override
  State<FABMenuButton> createState() => _FABMenuButtonState();
}

class _FABMenuButtonState extends State<FABMenuButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Backdrop
        if (_isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleMenu,
              child: Container(color: Colors.black.withValues(alpha: 0.3)),
            ),
          ),
        // Menu items
        if (_isOpen) ...[
          _AnimatedFABMenuItem(
            animation: Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(0, -80),
            ).animate(_controller),
            icon: Icons.upload_file_rounded,
            label: 'Import Excel',
            onTap: () {
              _toggleMenu();
              widget.onImportExcel();
            },
            backgroundColor: const Color(0xFF4A90E2),
          ),
          if (widget.onScanCard != null)
            _AnimatedFABMenuItem(
              animation: Tween<Offset>(
                begin: Offset.zero,
                end: const Offset(0, -160),
              ).animate(_controller),
              icon: Icons.qr_code_2_rounded,
              label: 'Quét thẻ',
              onTap: () {
                _toggleMenu();
                widget.onScanCard?.call();
              },
              backgroundColor: const Color(0xFF9B59B6),
            ),
        ],
        // Main FAB
        FloatingActionButton.extended(
          onPressed: _isOpen ? _toggleMenu : widget.onAddStudent,
          icon: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _controller,
            size: 28,
          ),
          label: Text(_isOpen ? 'Đóng' : 'Thêm'),
          tooltip: _isOpen ? 'Đóng menu' : 'Thêm sinh viên mới',
        ),
      ],
    );
  }
}

class _AnimatedFABMenuItem extends StatelessWidget {
  final Animation<Offset> animation;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;

  const _AnimatedFABMenuItem({
    required this.animation,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: animation,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Tooltip(
          message: label,
          child: FloatingActionButton(
            heroTag: label,
            onPressed: onTap,
            backgroundColor: backgroundColor,
            mini: true,
            child: Icon(icon, size: 20),
          ),
        ),
      ),
    );
  }
}

/// Collapsible app bar delegate
class CollapsibleAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double expandedHeight;
  final Widget title;
  final Widget? actions;
  final LinearGradient gradient;

  CollapsibleAppBarDelegate({
    required this.expandedHeight,
    required this.title,
    this.actions,
    required this.gradient,
  });

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => expandedHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0, 1);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradient background
        Container(decoration: BoxDecoration(gradient: gradient)),
        // Content
        if (progress <= 0.5)
          Column(
            children: [
              Expanded(
                child: Opacity(
                  opacity: (1 - progress).toDouble(),
                  child: title,
                ),
              ),
            ],
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Danh sách SV',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ?actions,
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  bool shouldRebuild(CollapsibleAppBarDelegate oldDelegate) {
    return oldDelegate.expandedHeight != expandedHeight;
  }
}

/// Search suggestions widget
class SearchSuggestionsDropdown extends StatelessWidget {
  final List<String> suggestions;
  final VoidCallback onClear;
  final Function(String) onSuggestionTap;

  const SearchSuggestionsDropdown({
    super.key,
    required this.suggestions,
    required this.onClear,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Column(
        children: [
          for (final suggestion in suggestions)
            InkWell(
              onTap: () => onSuggestionTap(suggestion),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history, size: 18, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(child: Text(suggestion)),
                  ],
                ),
              ),
            ),
          Divider(height: 1, color: Colors.grey[200]),
          InkWell(
            onTap: onClear,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Xóa lịch sử',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
