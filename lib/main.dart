import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const StudentManagerApp());
}

class StudentManagerApp extends StatelessWidget {
  const StudentManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Manager',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006D77)),
        scaffoldBackgroundColor: const Color(0xFFF5F8FA),
      ),
      home: const HomeScreen(),
    );
  }
}

enum AcademicRank { excellent, good, fair, average }

enum SortBy { nameAZ, gpaDesc, studentId }

class Student {
  const Student({
    required this.id,
    required this.name,
    required this.studentCode,
    required this.className,
    required this.department,
    required this.email,
    required this.gpa,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String studentCode;
  final String className;
  final String department;
  final String email;
  final double gpa;
  final String? avatarUrl;

  AcademicRank get academicRank {
    if (gpa >= 3.6) return AcademicRank.excellent;
    if (gpa >= 3.2) return AcademicRank.good;
    if (gpa >= 2.5) return AcademicRank.fair;
    return AcademicRank.average;
  }
}

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

  final List<Student> _allStudents = _seedStudents();
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
    var result = _allStudents.where((student) {
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
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đi tới màn hình thêm sinh viên.')),
          );
        },
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
                      onEdit: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sửa: ${student.name}')),
                        );
                      },
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

class StudentCard extends StatelessWidget {
  const StudentCard({
    super.key,
    required this.student,
    required this.onEdit,
    required this.onDelete,
  });

  final Student student;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
                _Avatar(student: student),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    final fallbackText = student.name.trim().isEmpty
        ? '?'
        : student.name.trim().substring(0, 1).toUpperCase();
    final hasUrl = student.avatarUrl?.isNotEmpty ?? false;

    return SizedBox(
      width: 44,
      height: 44,
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

List<Student> _seedStudents() {
  return const [
    Student(
      id: '1',
      name: 'Nguyễn Minh Anh',
      studentCode: 'SV2024001',
      className: 'CNTT-K18A',
      department: 'CNTT',
      email: 'minhanh@univ.edu.vn',
      gpa: 3.82,
      avatarUrl: 'https://i.pravatar.cc/150?img=47',
    ),
    Student(
      id: '2',
      name: 'Trần Quốc Bảo',
      studentCode: 'SV2024002',
      className: 'QTKD-K18B',
      department: 'Kinh Tế',
      email: 'quocbao@univ.edu.vn',
      gpa: 3.26,
      avatarUrl: 'https://i.pravatar.cc/150?img=12',
    ),
    Student(
      id: '3',
      name: 'Lê Thảo My',
      studentCode: 'SV2024003',
      className: 'CNTT-K18B',
      department: 'CNTT',
      email: 'thaomy@univ.edu.vn',
      gpa: 3.12,
    ),
    Student(
      id: '4',
      name: 'Phạm Gia Huy',
      studentCode: 'SV2024004',
      className: 'KTQT-K18A',
      department: 'Kinh Tế',
      email: 'giahuy@univ.edu.vn',
      gpa: 2.76,
    ),
    Student(
      id: '5',
      name: 'Đỗ Quỳnh Trang',
      studentCode: 'SV2024005',
      className: 'CNTT-K18C',
      department: 'CNTT',
      email: 'quynhtrang@univ.edu.vn',
      gpa: 3.67,
      avatarUrl: 'https://i.pravatar.cc/150?img=32',
    ),
    Student(
      id: '6',
      name: 'Vũ Đức Long',
      studentCode: 'SV2024006',
      className: 'QTKD-K18A',
      department: 'Kinh Tế',
      email: 'duclong@univ.edu.vn',
      gpa: 2.34,
    ),
    Student(
      id: '7',
      name: 'Bùi Hải Nam',
      studentCode: 'SV2024007',
      className: 'CNTT-K19A',
      department: 'CNTT',
      email: 'hainam@univ.edu.vn',
      gpa: 3.94,
      avatarUrl: 'https://i.pravatar.cc/150?img=15',
    ),
    Student(
      id: '8',
      name: 'Ngô Thu Hà',
      studentCode: 'SV2024008',
      className: 'KTQT-K19B',
      department: 'Kinh Tế',
      email: 'thuha@univ.edu.vn',
      gpa: 3.04,
    ),
    Student(
      id: '9',
      name: 'Hoàng Minh Khoa',
      studentCode: 'SV2024009',
      className: 'CNTT-K19B',
      department: 'CNTT',
      email: 'minhkhoa@univ.edu.vn',
      gpa: 2.62,
      avatarUrl: 'https://i.pravatar.cc/150?img=4',
    ),
    Student(
      id: '10',
      name: 'Tạ Khánh Linh',
      studentCode: 'SV2024010',
      className: 'QTKD-K19A',
      department: 'Kinh Tế',
      email: 'khanhlinh@univ.edu.vn',
      gpa: 3.48,
    ),
    Student(
      id: '11',
      name: 'Phan Nhật Quang',
      studentCode: 'SV2024011',
      className: 'CNTT-K20A',
      department: 'CNTT',
      email: 'nhatquang@univ.edu.vn',
      gpa: 3.22,
    ),
    Student(
      id: '12',
      name: 'Lý Ngọc Bích',
      studentCode: 'SV2024012',
      className: 'KTQT-K20A',
      department: 'Kinh Tế',
      email: 'ngocbich@univ.edu.vn',
      gpa: 2.95,
      avatarUrl: 'https://i.pravatar.cc/150?img=29',
    ),
    Student(
      id: '13',
      name: 'Đinh Tiến Đạt',
      studentCode: 'SV2024013',
      className: 'CNTT-K20B',
      department: 'CNTT',
      email: 'tiendat@univ.edu.vn',
      gpa: 3.58,
    ),
    Student(
      id: '14',
      name: 'Mai Hoài An',
      studentCode: 'SV2024014',
      className: 'QTKD-K20B',
      department: 'Kinh Tế',
      email: 'hoaian@univ.edu.vn',
      gpa: 2.49,
    ),
    Student(
      id: '15',
      name: 'Trương Gia Linh',
      studentCode: 'SV2024015',
      className: 'CNTT-K21A',
      department: 'CNTT',
      email: 'gialinh@univ.edu.vn',
      gpa: 3.74,
      avatarUrl: 'https://i.pravatar.cc/150?img=21',
    ),
    Student(
      id: '16',
      name: 'Nguyễn Đức Mạnh',
      studentCode: 'SV2024016',
      className: 'KTQT-K21A',
      department: 'Kinh Tế',
      email: 'ducmanh@univ.edu.vn',
      gpa: 3.01,
    ),
    Student(
      id: '17',
      name: 'Lương Thu Uyên',
      studentCode: 'SV2024017',
      className: 'CNTT-K21B',
      department: 'CNTT',
      email: 'thuyen@univ.edu.vn',
      gpa: 2.81,
    ),
    Student(
      id: '18',
      name: 'Kiều Anh Dũng',
      studentCode: 'SV2024018',
      className: 'QTKD-K21B',
      department: 'Kinh Tế',
      email: 'anhdung@univ.edu.vn',
      gpa: 3.39,
      avatarUrl: 'https://i.pravatar.cc/150?img=8',
    ),
  ];
}
