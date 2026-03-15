import 'dart:math';

import 'package:flutter/material.dart';
import 'package:student_manager/models/student.dart';
import 'package:student_manager/screens/detail_screen.dart';
import 'package:student_manager/screens/student_form_screen.dart';
import 'package:student_manager/services/student_service.dart';
import 'package:student_manager/widgets/student_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _pageSize = 8;
  static const String _filterAll = 'Tất cả';
  static const String _filterIT = 'Khoa CNTT';
  static const String _filterEco = 'Khoa Kinh Tế';
  static const String _filterGpa = 'GPA > 3.0';

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  final List<Student> _allStudents = StudentService.seedStudents();
  final List<Student> _visibleStudents = <Student>[];

  String _selectedQuickFilter = _filterAll;
  SortBy _sortBy = SortBy.nameAZ;
  bool _loadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _reloadVisibleData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  int get _activeFilterCount {
    var count = 0;
    if (_selectedQuickFilter != _filterAll) count++;
    if (_sortBy != SortBy.nameAZ) count++;
    if (_searchController.text.trim().isNotEmpty) count++;
    return count;
  }

  List<Student> get _filteredStudents {
    final query = _searchController.text.trim().toLowerCase();
    final result = _allStudents.where((student) {
      final matchesSearch =
          query.isEmpty ||
          student.name.toLowerCase().contains(query) ||
          student.studentCode.toLowerCase().contains(query) ||
          student.email.toLowerCase().contains(query);
      if (!matchesSearch) return false;

      switch (_selectedQuickFilter) {
        case _filterIT:
          return student.department == 'CNTT';
        case _filterEco:
          return student.department == 'Kinh Tế';
        case _filterGpa:
          return student.gpa > 3.0;
        default:
          return true;
      }
    }).toList();

    switch (_sortBy) {
      case SortBy.nameAZ:
        result.sort((a, b) => a.name.compareTo(b.name));
      case SortBy.gpaDesc:
        result.sort((a, b) => b.gpa.compareTo(a.gpa));
      case SortBy.studentId:
        result.sort((a, b) => a.studentCode.compareTo(b.studentCode));
    }
    return result;
  }

  Future<void> _onRefresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _reloadVisibleData();
  }

  void _onScroll() {
    if (_loadingMore || !_hasMore) return;
    final threshold = _scrollController.position.maxScrollExtent - 120;
    if (_scrollController.position.pixels >= threshold) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final source = _filteredStudents;
    final nextEnd = min(_visibleStudents.length + _pageSize, source.length);
    if (_visibleStudents.length < nextEnd) {
      setState(() {
        _visibleStudents
          ..clear()
          ..addAll(source.take(nextEnd));
      });
    }

    setState(() {
      _loadingMore = false;
      _hasMore = _visibleStudents.length < source.length;
    });
  }

  void _reloadVisibleData() {
    final source = _filteredStudents;
    final initialEnd = min(_pageSize, source.length);
    setState(() {
      _visibleStudents
        ..clear()
        ..addAll(source.take(initialEnd));
      _hasMore = _visibleStudents.length < source.length;
      _loadingMore = false;
    });
  }

  void _onQuickFilterSelected(String value) {
    setState(() {
      _selectedQuickFilter = value;
    });
    _reloadVisibleData();
  }

  Future<void> _openDetail(Student student) async {
    final result = await Navigator.push<StudentDetailResult>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DetailScreen(student: student, existingStudents: _allStudents),
      ),
    );

    if (result == null) return;

    if (result.type == StudentDetailActionType.deleted) {
      setState(() {
        _allStudents.removeWhere((item) => item.id == student.id);
      });
      _reloadVisibleData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã xóa: ${student.name}')));
    }

    if (result.type == StudentDetailActionType.edited &&
        result.student != null) {
      final edited = result.student!;
      final index = _allStudents.indexWhere((item) => item.id == edited.id);
      if (index >= 0) {
        setState(() {
          _allStudents[index] = edited;
        });
        _reloadVisibleData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật sinh viên thành công')),
        );
      }
    }
  }

  Future<void> _openAddStudentForm() async {
    final result = await Navigator.push<StudentFormResult>(
      context,
      MaterialPageRoute(
        builder: (_) => StudentFormScreen(existingStudents: _allStudents),
      ),
    );
    if (result == null || !mounted) return;

    setState(() {
      _allStudents.insert(0, result.student);
    });
    _reloadVisibleData();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Thêm sinh viên thành công')));
  }

  Future<void> _openEditStudentForm(Student student) async {
    final result = await Navigator.push<StudentFormResult>(
      context,
      MaterialPageRoute(
        builder: (_) => StudentFormScreen(
          existingStudents: _allStudents,
          initialStudent: student,
        ),
      ),
    );
    if (result == null || !mounted) return;

    final index = _allStudents.indexWhere((item) => item.id == student.id);
    if (index < 0) return;
    setState(() {
      _allStudents[index] = result.student;
    });
    _reloadVisibleData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cập nhật sinh viên thành công')),
    );
  }

  void _openSortFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lọc & Sắp xếp',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sắp xếp',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Tên (A-Z)'),
                          selected: _sortBy == SortBy.nameAZ,
                          onSelected: (_) =>
                              setSheetState(() => _sortBy = SortBy.nameAZ),
                        ),
                        ChoiceChip(
                          label: const Text('GPA (cao -> thấp)'),
                          selected: _sortBy == SortBy.gpaDesc,
                          onSelected: (_) =>
                              setSheetState(() => _sortBy = SortBy.gpaDesc),
                        ),
                        ChoiceChip(
                          label: const Text('MSSV'),
                          selected: _sortBy == SortBy.studentId,
                          onSelected: (_) =>
                              setSheetState(() => _sortBy = SortBy.studentId),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _sortBy = SortBy.nameAZ;
                                _selectedQuickFilter = _filterAll;
                                _searchController.clear();
                              });
                              _reloadVisibleData();
                              Navigator.pop(context);
                            },
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              _reloadVisibleData();
                              Navigator.pop(context);
                            },
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();
    final hasNoData = _visibleStudents.isEmpty;
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 900 ? 2 : 3;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddStudentForm,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              titleSpacing: 16,
              title: const Text(
                'Danh sách sinh viên',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              actions: [
                _BadgeIconButton(
                  count: _activeFilterCount,
                  icon: Icons.tune_rounded,
                  onPressed: _openSortFilterSheet,
                ),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(106),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    children: [
                      _SearchField(
                        controller: _searchController,
                        onChanged: (_) {
                          setState(() {});
                          _reloadVisibleData();
                        },
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _QuickFilterChip(
                              label: _filterAll,
                              selected: _selectedQuickFilter == _filterAll,
                              onSelected: () =>
                                  _onQuickFilterSelected(_filterAll),
                            ),
                            _QuickFilterChip(
                              label: _filterIT,
                              selected: _selectedQuickFilter == _filterIT,
                              onSelected: () =>
                                  _onQuickFilterSelected(_filterIT),
                            ),
                            _QuickFilterChip(
                              label: _filterEco,
                              selected: _selectedQuickFilter == _filterEco,
                              onSelected: () =>
                                  _onQuickFilterSelected(_filterEco),
                            ),
                            _QuickFilterChip(
                              label: _filterGpa,
                              selected: _selectedQuickFilter == _filterGpa,
                              onSelected: () =>
                                  _onQuickFilterSelected(_filterGpa),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (hasNoData)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(query: query),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverGrid.builder(
                  itemCount: _visibleStudents.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (context, index) {
                    final student = _visibleStudents[index];
                    return StudentCard(
                      student: student,
                      onAvatarTap: () => _openDetail(student),
                      onEdit: () => _openEditStudentForm(student),
                      onDelete: () {
                        setState(() {
                          _allStudents.removeWhere(
                            (item) => item.id == student.id,
                          );
                        });
                        _reloadVisibleData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã xóa: ${student.name}')),
                        );
                      },
                    );
                  },
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: _loadingMore
                      ? const CircularProgressIndicator()
                      : _hasMore
                      ? const SizedBox.shrink()
                      : const Text(
                          'Đã hiển thị tất cả sinh viên',
                          style: TextStyle(color: Colors.black54),
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

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Tìm theo họ tên, MSSV, email...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: const Color(0xFFF1F5F8),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _QuickFilterChip extends StatelessWidget {
  const _QuickFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _BadgeIconButton extends StatelessWidget {
  const _BadgeIconButton({
    required this.count,
    required this.icon,
    required this.onPressed,
  });

  final int count;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(onPressed: onPressed, icon: Icon(icon)),
        if (count > 0)
          Positioned(
            right: 6,
            top: 7,
            child: Container(
              height: 18,
              width: 18,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_outlined, size: 80, color: Colors.black38),
            const SizedBox(height: 12),
            Text(
              query.isEmpty
                  ? 'Chưa có sinh viên nào trong danh sách.'
                  : 'Không tìm thấy sinh viên phù hợp.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy thử thay đổi từ khóa hoặc bộ lọc để xem kết quả khác.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
