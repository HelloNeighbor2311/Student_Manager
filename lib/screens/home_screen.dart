import 'package:flutter/material.dart';
import 'package:student_manager/models/student.dart';
import 'package:student_manager/screens/detail_screen.dart';
import 'package:student_manager/screens/student_form_screen.dart';
import 'package:student_manager/services/student_firestore_service.dart';
import 'package:student_manager/services/student_service.dart';
import 'package:student_manager/widgets/student_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StudentFirestoreService _firestoreService = StudentFirestoreService();
  final TextEditingController _searchController = TextEditingController();

  List<Student> _students = <Student>[];
  bool _isLoading = true;
  String? _loadError;
  SortBy _sortBy = SortBy.nameAZ;
  String _departmentFilter = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    final seeds = StudentService.seedStudents();
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final loaded = await _firestoreService.fetchOrSeedStudents(seeds);
      if (!mounted) return;
      setState(() {
        _students = loaded;
        _isLoading = false;
      });
    } catch (_) {
      // Fallback to local seed data if Firestore is unavailable.
      if (!mounted) return;
      setState(() {
        _students = seeds;
        _isLoading = false;
        _loadError =
            'Không thể kết nối Firestore. Ứng dụng đang dùng dữ liệu mẫu cục bộ.';
      });
    }
  }

  List<Student> get _filteredStudents {
    final q = _searchController.text.trim().toLowerCase();

    var list = _students.where((student) {
      final inDepartment =
          _departmentFilter == 'Tất cả' ||
          student.department == _departmentFilter;
      if (!inDepartment) return false;

      if (q.isEmpty) return true;
      return student.name.toLowerCase().contains(q) ||
          student.studentCode.toLowerCase().contains(q) ||
          student.className.toLowerCase().contains(q);
    }).toList();

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
      setState(() {
        _students = [..._students, result.student];
      });
    } catch (_) {
      setState(() {
        _students = [..._students, result.student];
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không thể lưu Firestore. Đã lưu tạm trong phiên hiện tại.',
          ),
        ),
      );
    }
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
          content: Text(
            'Không thể cập nhật Firestore. Đã cập nhật tạm cục bộ.',
          ),
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _students = _students
          .map((s) => s.id == updated.id ? updated : s)
          .toList(growable: false);
    });
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
        // Keep local update even if cloud update fails.
      }

      setState(() {
        _students = _students
            .map((s) => s.id == updated.id ? updated : s)
            .toList(growable: false);
      });
    }
  }

  Future<void> _deleteStudent(Student student) async {
    try {
      await _firestoreService.deleteStudent(student.id);
    } catch (_) {
      // Keep local delete behavior even if cloud delete fails.
    }

    if (!mounted) return;
    setState(() {
      _students = _students
          .where((s) => s.id != student.id)
          .toList(growable: false);
    });
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
    final students = _filteredStudents;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Manager'),
        actions: [
          PopupMenuButton<SortBy>(
            tooltip: 'Sắp xếp',
            initialValue: _sortBy,
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: SortBy.nameAZ, child: Text('Tên A-Z')),
              PopupMenuItem(value: SortBy.gpaDesc, child: Text('GPA giảm dần')),
              PopupMenuItem(
                value: SortBy.studentId,
                child: Text('MSSV tăng dần'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addStudent,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Thêm'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadStudents,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên, MSSV, lớp...',
                    prefixIcon: const Icon(Icons.search_rounded),
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Tất cả', 'CNTT', 'Kinh Tế']
                      .map((dept) {
                        final selected = dept == _departmentFilter;
                        return ChoiceChip(
                          label: Text(dept),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _departmentFilter = dept),
                        );
                      })
                      .toList(growable: false),
                ),
              ),
            ),
            if (_loadError != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
            else if (students.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text('Không có sinh viên phù hợp.')),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
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
          ],
        ),
      ),
    );
  }
}
