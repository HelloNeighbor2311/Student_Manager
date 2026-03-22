import 'package:flutter/material.dart';
import 'package:student_manager/models/student.dart';
import 'package:student_manager/screens/detail_screen.dart';
import 'package:student_manager/screens/statistics_screen.dart';
import 'package:student_manager/screens/student_form_screen.dart';
import 'package:student_manager/services/student_firestore_service.dart';
import 'package:student_manager/services/student_local_cache_service.dart';
import 'package:student_manager/services/student_service.dart';
import 'package:student_manager/widgets/student_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _pageSize = 12;

  final StudentFirestoreService _firestoreService = StudentFirestoreService();
  final StudentLocalCacheService _localCacheService =
      StudentLocalCacheService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
    final ValueNotifier<List<Student>> _studentsNotifier =
      ValueNotifier<List<Student>>(<Student>[]);

  List<Student> _students = <Student>[];
  bool _isLoading = true;
  bool _isPaging = false;
  String? _loadError;
  SortBy _sortBy = SortBy.nameAZ;
  String _departmentFilter = 'Tất cả';
  bool _showWarningOnly = false;
  int _visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _studentsNotifier.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isPaging) {
      return;
    }

    final threshold = _scrollController.position.maxScrollExtent - 220;
    if (_scrollController.position.pixels < threshold) {
      return;
    }

    final total = _filteredStudents.length;
    if (_visibleCount >= total) {
      return;
    }

    setState(() {
      _isPaging = true;
    });

    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      setState(() {
        _visibleCount = (_visibleCount + _pageSize).clamp(0, total);
        _isPaging = false;
      });
    });
  }

  Future<void> _saveLocal() async {
    await _localCacheService.saveStudents(_students);
  }

  Future<void> _loadStudents() async {
    final seeds = StudentService.seedStudents();
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    final cached = await _localCacheService.loadStudents();
    if (cached.isNotEmpty && mounted) {
      setState(() {
        _students = cached;
        _studentsNotifier.value = _students;
        _isLoading = false;
      });
    }

    try {
      final loaded = await _firestoreService.fetchOrSeedStudents(seeds);
      if (!mounted) return;
      setState(() {
        _students = loaded;
        _studentsNotifier.value = _students;
        _isLoading = false;
      });
      await _saveLocal();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _students = cached.isNotEmpty ? cached : seeds;
        _studentsNotifier.value = _students;
        _isLoading = false;
        _loadError = cached.isNotEmpty
            ? 'Không thể kết nối Firestore. Đang dùng dữ liệu cục bộ đã lưu.'
            : 'Không thể kết nối Firestore. Ứng dụng đang dùng dữ liệu mẫu cục bộ.';
      });
      await _saveLocal();
    }

    _resetPaging();
  }

  void _resetPaging() {
    if (!mounted) return;
    setState(() {
      _visibleCount = _pageSize;
    });
  }

  List<Student> get _filteredStudents {
    final q = _searchController.text.trim().toLowerCase();

    final list = _students
        .where((student) {
          final inDepartment =
              _departmentFilter == 'Tất cả' ||
              student.department == _departmentFilter;
          if (!inDepartment) return false;

          if (_showWarningOnly && !student.isWarning) return false;

          if (q.isEmpty) return true;
          return student.name.toLowerCase().contains(q) ||
              student.studentCode.toLowerCase().contains(q) ||
              student.className.toLowerCase().contains(q);
        })
        .toList(growable: false);

    switch (_sortBy) {
      case SortBy.nameAZ:
        list.sort((a, b) => a.name.compareTo(b.name));
      case SortBy.gpaDesc:
        list.sort((a, b) => b.gpa.compareTo(a.gpa));
      case SortBy.studentId:
        list.sort((a, b) => a.studentCode.compareTo(b.studentCode));
    }

    return list;
  }

  List<Student> get _visibleStudents {
    final filtered = _filteredStudents;
    return filtered.take(_visibleCount.clamp(0, filtered.length)).toList();
  }

  Future<void> _addStudent() async {
    final result = await Navigator.push<StudentFormResult>(
      context,
      MaterialPageRoute(
        builder: (_) => StudentFormScreen(existingStudents: _students),
      ),
    );

    if (result == null || !mounted) return;

    try {
      await _firestoreService.addStudent(result.student);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể lưu Firestore. Đã lưu dữ liệu cục bộ.'),
        ),
      );
    }

    setState(() {
      _students = [..._students, result.student];
      _studentsNotifier.value = _students;
    });
    await _saveLocal();
    _resetPaging();
  }

  Future<void> _editStudent(Student student) async {
    final result = await Navigator.push<StudentFormResult>(
      context,
      MaterialPageRoute(
        builder: (_) => StudentFormScreen(
          existingStudents: _students,
          initialStudent: student,
        ),
      ),
    );

    if (result == null || !mounted) return;

    final updated = result.student;
    try {
      await _firestoreService.updateStudent(updated);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể cập nhật Firestore. Đã cập nhật cục bộ.'),
        ),
      );
    }

    setState(() {
      _students = _students
          .map((s) => s.id == updated.id ? updated : s)
          .toList(growable: false);
      _studentsNotifier.value = _students;
    });
    await _saveLocal();
  }

  Future<void> _openDetails(Student student) async {
    final result = await Navigator.push<StudentDetailResult>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DetailScreen(student: student, existingStudents: _students),
      ),
    );

    if (result == null || !mounted) return;

    if (result.type == StudentDetailActionType.deleted) {
      await _deleteStudent(student);
      return;
    }

    if (result.type == StudentDetailActionType.edited &&
        result.student != null) {
      final updated = result.student!;
      try {
        await _firestoreService.updateStudent(updated);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể cập nhật Firestore. Đã cập nhật cục bộ.'),
          ),
        );
      }

      setState(() {
        _students = _students
            .map((s) => s.id == updated.id ? updated : s)
            .toList(growable: false);
        _studentsNotifier.value = _students;
      });
      await _saveLocal();
    }
  }

  Future<void> _deleteStudent(Student student) async {
    try {
      await _firestoreService.deleteStudent(student.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể xóa trên Firestore. Đã xóa cục bộ.'),
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _students = _students
          .where((s) => s.id != student.id)
          .toList(growable: false);
      _studentsNotifier.value = _students;
    });
    await _saveLocal();
    _resetPaging();
  }

  Future<void> _confirmDelete(Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa sinh viên ${student.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteStudent(student);
    }
  }

  Future<void> _openStatistics() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => StatisticsScreen(studentsListenable: _studentsNotifier),
      ),
    );
  }

  Future<void> _showSortSheet() async {
    final selected = await showModalBottomSheet<SortBy>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.sort_by_alpha_rounded),
              title: const Text('Tên A-Z'),
              selected: _sortBy == SortBy.nameAZ,
              onTap: () => Navigator.pop(context, SortBy.nameAZ),
            ),
            ListTile(
              leading: const Icon(Icons.trending_down_rounded),
              title: const Text('GPA giảm dần'),
              selected: _sortBy == SortBy.gpaDesc,
              onTap: () => Navigator.pop(context, SortBy.gpaDesc),
            ),
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('MSSV tăng dần'),
              selected: _sortBy == SortBy.studentId,
              onTap: () => Navigator.pop(context, SortBy.studentId),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (selected == null) return;
    setState(() {
      _sortBy = selected;
    });
    _resetPaging();
  }

  Future<void> _scrollToTop() async {
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredStudents;
    final students = _visibleStudents;
    final isFiltering =
        _departmentFilter != 'Tất cả' ||
        _searchController.text.trim().isNotEmpty;
    final avgGpa = _students.isEmpty
        ? 0.0
        : _students.fold<double>(0.0, (sum, s) => sum + s.gpa) /
              _students.length;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _addStudent,
        child: const Icon(Icons.person_add_alt_1_rounded),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        height: 74,
        child: Row(
          children: [
            _BottomNavButton(
              icon: Icons.home_rounded,
              label: 'Trang chủ',
              onTap: _scrollToTop,
            ),
            _BottomNavButton(
              icon: Icons.analytics_outlined,
              label: 'Thống kê',
              onTap: _openStatistics,
            ),
            const Spacer(),
            _BottomNavButton(
              icon: Icons.sort_rounded,
              label: 'Sắp xếp',
              onTap: _showSortSheet,
            ),
            _BottomNavButton(
              icon: Icons.refresh_rounded,
              label: 'Tải lại',
              onTap: _loadStudents,
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.13),
                    const Color(0xFFF1F6FA),
                    Colors.white,
                  ],
                ),
              ),
            ),
          ),
          RefreshIndicator(
            onRefresh: _loadStudents,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 186,
                  toolbarHeight: 64,
                  title: const Text('Student Manager'),
                  flexibleSpace: FlexibleSpaceBar(
                    background: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 74, 16, 14),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF0D8A90), Color(0xFF54A6DC)],
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x351F5D7A),
                                blurRadius: 18,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isFiltering
                                            ? '${filtered.length}/${_students.length} sinh viên phù hợp bộ lọc'
                                            : '${_students.length} sinh viên đang quản lý',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Dữ liệu đồng bộ Firestore và bộ nhớ cục bộ',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: Color(0xFFD7F5FF),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.auto_graph_rounded,
                                  size: 34,
                                  color: Colors.white.withValues(alpha: 0.95),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(36),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatPill(
                              icon: Icons.people_alt_rounded,
                              label: 'Phù hợp',
                              value: '${filtered.length}/${_students.length}',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatPill(
                              icon: Icons.visibility_rounded,
                              label: 'Đang xem',
                              value: '${students.length}',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatPill(
                            icon: Icons.school_rounded,
                            label: 'GPA TB',
                            value: avgGpa.toStringAsFixed(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 52,
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) {
                              setState(() {});
                              _resetPaging();
                            },
                            decoration: InputDecoration(
                              hintText: 'Tìm theo tên, MSSV, lớp...',
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: _searchController.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Xóa tìm kiếm',
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
                                        _resetPaging();
                                      },
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 44,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              ...[
                                'Tất cả',
                                'CNTT',
                                'Kinh Tế',
                              ]
                                  .map((dept) {
                                    final selected =
                                        dept == _departmentFilter;
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        showCheckmark: false,
                                        label: Text(dept),
                                        selected: selected,
                                        onSelected: (_) {
                                          setState(() {
                                            _departmentFilter = dept;
                                          });
                                          _resetPaging();
                                        },
                                      ),
                                    );
                                  })
                                  .toList(growable: false),
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.warning_rounded,
                                          size: 16),
                                      SizedBox(width: 4),
                                      Text('Cảnh báo'),
                                    ],
                                  ),
                                  selected: _showWarningOnly,
                                  onSelected: (selected) {
                                    setState(() {
                                      _showWarningOnly = selected;
                                    });
                                    _resetPaging();
                                  },
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.7),
                                  selectedColor: const Color(0xFFFEE2E2),
                                  side: BorderSide(
                                    color: _showWarningOnly
                                        ? const Color(0xFFDC2626)
                                        : Colors.grey[300] ?? Colors.grey,
                                    width: 1.5,
                                  ),
                                  labelStyle: TextStyle(
                                    color: _showWarningOnly
                                        ? const Color(0xFF7F1D1D)
                                        : Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_loadError != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Material(
                        color: const Color(0xFFFFF3E4),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: Color(0xFF9B5A00),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _loadError!,
                                  style: const TextStyle(
                                    color: Color(0xFF8A5100),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (filtered.isEmpty)
                  const SliverFillRemaining(child: _EmptyState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 108),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.crossAxisExtent;
                        final crossAxisCount = width >= 1040
                            ? 4
                            : width >= 740
                            ? 3
                            : 2;

                        return SliverGrid(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final student = students[index];
                            return StudentCard(
                              student: student,
                              onTap: () => _openDetails(student),
                              onAvatarTap: () => _openDetails(student),
                              onEdit: () => _editStudent(student),
                              onDelete: () => _confirmDelete(student),
                            );
                          }, childCount: students.length),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                mainAxisExtent: 245,
                              ),
                        );
                      },
                    ),
                  ),
                if (!_isLoading && students.length < filtered.length)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 118),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF0F6C74)),
            const SizedBox(width: 6),
            Text(
              '$label: ',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2B3A42),
              ),
            ),
            Expanded(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0B4A57),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFDFF1F8),
              ),
              child: const Icon(
                Icons.manage_search_rounded,
                size: 36,
                color: Color(0xFF0A6C78),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Không có sinh viên phù hợp',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Thử đổi bộ lọc hoặc từ khóa để tìm đúng danh sách bạn cần.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF5E6B75),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 21),
              const SizedBox(height: 1),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
