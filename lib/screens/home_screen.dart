import 'package:flutter/material.dart';
import 'package:student_manager/models/student.dart';
import 'package:student_manager/screens/detail_screen.dart';
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

  List<Student> _students = <Student>[];
  bool _isLoading = true;
  bool _isPaging = false;
  String? _loadError;
  SortBy _sortBy = SortBy.nameAZ;
  String _departmentFilter = 'Tất cả';
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
        _isLoading = false;
      });
    }

    try {
      final loaded = await _firestoreService.fetchOrSeedStudents(seeds);
      if (!mounted) return;
      setState(() {
        _students = loaded;
        _isLoading = false;
      });
      await _saveLocal();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _students = cached.isNotEmpty ? cached : seeds;
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredStudents;
    final students = _visibleStudents;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addStudent,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Thêm'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadStudents,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              toolbarHeight: 64,
              title: const Text('Student Management - G7'),
              actions: [
                PopupMenuButton<SortBy>(
                  tooltip: 'Sắp xếp',
                  initialValue: _sortBy,
                  onSelected: (value) {
                    setState(() {
                      _sortBy = value;
                    });
                    _resetPaging();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: SortBy.nameAZ, child: Text('Tên A-Z')),
                    PopupMenuItem(
                      value: SortBy.gpaDesc,
                      child: Text('GPA giảm dần'),
                    ),
                    PopupMenuItem(
                      value: SortBy.studentId,
                      child: Text('MSSV tăng dần'),
                    ),
                  ],
                ),
              ],
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _PinnedHeaderDelegate(
                height: 64,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: SizedBox(
                    height: 48,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) {
                        setState(() {});
                        _resetPaging();
                      },
                      decoration: InputDecoration(
                        hintText: 'Tìm theo tên, MSSV, lớp...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _PinnedHeaderDelegate(
                height: 48,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: ['Tất cả', 'CNTT', 'Kinh Tế']
                          .map((dept) {
                            final selected = dept == _departmentFilter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
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
                    ),
                  ),
                ),
              ),
            ),
            if (_loadError != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Material(
                    color: const Color(0xFFFFF4E5),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _loadError!,
                        style: const TextStyle(color: Color(0xFF8A5100)),
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
              const SliverFillRemaining(
                child: Center(child: Text('Không có sinh viên phù hợp.')),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final student = students[index];
                    return StudentCard(
                      student: student,
                      onAvatarTap: () => _openDetails(student),
                      onEdit: () => _editStudent(student),
                      onDelete: () => _confirmDelete(student),
                    );
                  }, childCount: students.length),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 245,
                  ),
                ),
              ),
            if (!_isLoading && students.length < filtered.length)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 110),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  _PinnedHeaderDelegate({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
