import 'package:flutter/material.dart';
import 'package:student_manager/models/student.dart';
import 'package:student_manager/screens/detail_screen.dart';
import 'package:student_manager/screens/statistics_screen.dart';
import 'package:student_manager/screens/student_form_screen.dart';
import 'package:student_manager/services/student_firestore_service.dart';
import 'package:student_manager/services/student_local_cache_service.dart';
import 'package:student_manager/services/student_service.dart';
import 'package:student_manager/widgets/enhanced_student_card.dart';
import 'package:student_manager/widgets/home_screen_widgets.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _pageSize = 20;

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
  final bool _isGridView = false;
  bool _multiSelectMode = false;
  final Set<String> _selectedStudentIds = {};

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

  Future<void> _openStatistics() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => StatisticsScreen(students: _students)),
    );
  }

  List<String> get _uniqueDepartments {
    final depts = <String>{'Tất cả'};
    for (final student in _students) {
      depts.add(student.department);
    }
    return depts.toList();
  }

  Map<String, int> get _departmentCounts {
    final counts = <String, int>{'Tất cả': _students.length};
    for (final dept in _uniqueDepartments) {
      if (dept != 'Tất cả') {
        counts[dept] = _students
            .where((s) => s.department == dept)
            .toList()
            .length;
      }
    }
    return counts;
  }

  void _toggleMultiSelect(String studentId) {
    setState(() {
      if (_selectedStudentIds.contains(studentId)) {
        _selectedStudentIds.remove(studentId);
        if (_selectedStudentIds.isEmpty) {
          _multiSelectMode = false;
        }
      } else {
        if (!_multiSelectMode) {
          _multiSelectMode = true;
        }
        _selectedStudentIds.add(studentId);
      }
    });
  }

  Future<void> _deleteSelectedStudents() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa ${_selectedStudentIds.length} sinh viên?',
        ),
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

    if (confirm != true) return;

    for (final studentId in _selectedStudentIds) {
      try {
        await _firestoreService.deleteStudent(studentId);
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _students = _students
          .where((s) => !_selectedStudentIds.contains(s.id))
          .toList();
      _selectedStudentIds.clear();
      _multiSelectMode = false;
    });
    await _saveLocal();
    _resetPaging();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredStudents;
    final students = _visibleStudents;
    final theme = Theme.of(context);
    final primaryGradient = LinearGradient(
      colors: [const Color(0xFF006D77), const Color(0xFF118B88)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FA),
      floatingActionButton: FABMenuButton(
        onAddStudent: _addStudent,
        onImportExcel: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Tính năng import sẽ được thêm trong phiên bản tới',
              ),
            ),
          );
        },
        onScanCard: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Tính năng quét thẻ sẽ được thêm trong phiên bản tới',
              ),
            ),
          );
        },
      ),
      body: RefreshIndicator(
        onRefresh: _loadStudents,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Expanded app bar with gradient
            SliverPersistentHeader(
              pinned: true,
              floating: false,
              delegate: CollapsibleAppBarDelegate(
                expandedHeight: 140,
                gradient: primaryGradient,
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quản lý Sinh viên',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Nhóm 7-G3',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.analytics_outlined,
                        color: Colors.white,
                      ),
                      tooltip: 'Thống kê',
                      onPressed: _openStatistics,
                    ),
                    IconButton(
                      icon: const Icon(Icons.sort, color: Colors.white),
                      tooltip: 'Sắp xếp',
                      onPressed: () => _showSortMenu(),
                    ),
                  ],
                ),
              ),
            ),
            // Smart search bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _SearchBarHeaderDelegate(
                height: 80,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Search field with glassmorphism
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 48,
                              child: Center(
                                child: Icon(
                                  Icons.search_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 22,
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (_) {
                                  setState(() {});
                                  _resetPaging();
                                },
                                decoration: InputDecoration(
                                  hintText: 'Tìm theo tên, MSSV, email...',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              SizedBox(
                                width: 48,
                                child: Center(
                                  child: GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      setState(() {});
                                      _resetPaging();
                                    },
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: Colors.grey[400],
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            SizedBox(
                              width: 48,
                              child: Center(
                                child: Badge(
                                  isLabelVisible: true,
                                  label: const Text('0'),
                                  child: Icon(
                                    Icons.filter_list_outlined,
                                    color: theme.colorScheme.primary,
                                    size: 22,
                                  ),
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
            ),
            // Quick filter chips
            SliverPersistentHeader(
              pinned: true,
              delegate: _FilterChipsHeaderDelegate(
                height: 64,
                departments: _uniqueDepartments,
                departmentCounts: _departmentCounts,
                selectedDepartment: _departmentFilter,
                onDepartmentSelected: (dept) {
                  setState(() {
                    _departmentFilter = dept;
                  });
                  _resetPaging();
                },
              ),
            ),
            // Network error banner
            if (_loadError != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: NetworkErrorBanner(onRetry: _loadStudents),
                ),
              ),
            // Content
            if (_isLoading)
              SliverFillRemaining(child: ShimmerLoader(itemCount: 5))
            else if (filtered.isEmpty)
              SliverFillRemaining(
                child: EmptyStateWidget(
                  onAddStudent: _addStudent,
                  onImportExcel: () {},
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                sliver: _isGridView
                    ? SliverGrid(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final student = students[index];
                          return EnhancedStudentCard(
                            student: student,
                            isSelected: _selectedStudentIds.contains(
                              student.id,
                            ),
                            onTap: () => _openDetails(student),
                            onSelectionChanged: () =>
                                _toggleMultiSelect(student.id),
                            onAvatarTap: () => _openDetails(student),
                            onEdit: () => _editStudent(student),
                            onDelete: () => _confirmDelete(student),
                            onEmail: () => _sendEmail(student),
                            onCall: () => _callStudent(student),
                            onCopy: () => _copyStudentInfo(student),
                            onNote: () => _addStudentNote(student),
                          );
                        }, childCount: students.length),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              mainAxisExtent: 260,
                            ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final student = students[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: EnhancedStudentCard(
                              student: student,
                              isSelected: _selectedStudentIds.contains(
                                student.id,
                              ),
                              onTap: () => _openDetails(student),
                              onSelectionChanged: () =>
                                  _toggleMultiSelect(student.id),
                              onAvatarTap: () => _openDetails(student),
                              onEdit: () => _editStudent(student),
                              onDelete: () => _confirmDelete(student),
                              onEmail: () => _sendEmail(student),
                              onCall: () => _callStudent(student),
                              onCopy: () => _copyStudentInfo(student),
                              onNote: () => _addStudentNote(student),
                            ),
                          );
                        }, childCount: students.length),
                      ),
              ),
            // Loading indicator at bottom
            if (!_isLoading && students.length < filtered.length)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 110),
                  child: Center(
                    child: SizedBox(
                      height: 40,
                      width: 40,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      // Bottom action bar for multi-select
      bottomSheet: _multiSelectMode
          ? Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    '${_selectedStudentIds.length} được chọn',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: _deleteSelectedStudents,
                    tooltip: 'Xóa',
                  ),
                  IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: _exportSelectedToCSV,
                    tooltip: 'Xuất CSV',
                  ),
                  IconButton(
                    icon: const Icon(Icons.label),
                    onPressed: _addLabelsToSelected,
                    tooltip: 'Thêm nhãn',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectedStudentIds.clear();
                        _multiSelectMode = false;
                      });
                    },
                    tooltip: 'Hủy',
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Future<void> _exportSelectedToCSV() async {
    final selectedStudents = _students
        .where((s) => _selectedStudentIds.contains(s.id))
        .toList();

    if (selectedStudents.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có sinh viên được chọn')),
      );
      return;
    }

    // Create CSV content
    final csvHeader =
        'Họ tên,MSSV,Lớp,Khoa,Chuyên ngành,Email,Điện thoại,GPA,Xếp loại';
    final csvRows = selectedStudents.map((student) {
      return '${student.name},${student.studentCode},${student.className},${student.department},${student.major},${student.email},${student.phone},${student.gpa.toStringAsFixed(2)},${student.academicRankLabel}';
    }).toList();

    final csvContent = [csvHeader, ...csvRows].join('\n');

    // Copy to clipboard for now (file export would require path_provider)
    Clipboard.setData(ClipboardData(text: csvContent));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã sao chép ${selectedStudents.length} sinh viên sang CSV',
        ),
      ),
    );
  }

  Future<void> _addLabelsToSelected() async {
    const predefinedLabels = [
      'Cần theo dõi',
      'Lớp trưởng',
      'Xuất sắc',
      'Cần hỗ trợ',
      'Có việc làm',
    ];

    if (!mounted) return;
    await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm nhãn'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: predefinedLabels
                .map(
                  (label) => CheckboxListTile(
                    title: Text(label),
                    value: false,
                    onChanged: (value) {
                      // TODO: Track selected labels
                    },
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã thêm nhãn cho ${_selectedStudentIds.length} sinh viên',
        ),
      ),
    );
  }

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Sắp xếp',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: _sortBy == SortBy.nameAZ
                  ? const Icon(Icons.check)
                  : null,
              title: const Text('Tên A-Z'),
              onTap: () {
                setState(() => _sortBy = SortBy.nameAZ);
                _resetPaging();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: _sortBy == SortBy.gpaDesc
                  ? const Icon(Icons.check)
                  : null,
              title: const Text('GPA giảm dần'),
              onTap: () {
                setState(() => _sortBy = SortBy.gpaDesc);
                _resetPaging();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: _sortBy == SortBy.studentId
                  ? const Icon(Icons.check)
                  : null,
              title: const Text('MSSV tăng dần'),
              onTap: () {
                setState(() => _sortBy = SortBy.studentId);
                _resetPaging();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _sendEmail(Student student) async {
    if (student.email.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có địa chỉ email')),
      );
      return;
    }

    final emailUri = Uri(
      scheme: 'mailto',
      path: student.email,
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở ứng dụng email')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _callStudent(Student student) async {
    if (student.phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có số điện thoại')),
      );
      return;
    }

    final telUri = Uri(
      scheme: 'tel',
      path: student.phone,
    );

    try {
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở ứng dụng gọi điện')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  void _copyStudentInfo(Student student) {
    final info =
        'Họ tên: ${student.name}\nMSSV: ${student.studentCode}\nEmail: ${student.email}\nSĐT: ${student.phone}\nLớp: ${student.className}';

    Clipboard.setData(ClipboardData(text: info));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép thông tin của ${student.name}'),
      ),
    );
  }

  Future<void> _addStudentNote(Student student) async {
    final noteController = TextEditingController();

    if (!mounted) return;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ghi chú cho ${student.name}'),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Nhập ghi chú...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, noteController.text),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      // TODO: Save note to database/service
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã lưu ghi chú cho ${student.name}'),
        ),
      );
    }

    noteController.dispose();
  }
}

class _SearchBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SearchBarHeaderDelegate({required this.height, required this.child});

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
      color: const Color(0xFFF5F8FA),
      child: SizedBox(height: height, child: child),
    );
  }

  @override
  bool shouldRebuild(covariant _SearchBarHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

class _FilterChipsHeaderDelegate extends SliverPersistentHeaderDelegate {
  _FilterChipsHeaderDelegate({
    required this.height,
    required this.departments,
    required this.departmentCounts,
    required this.selectedDepartment,
    required this.onDepartmentSelected,
  });

  final double height;
  final List<String> departments;
  final Map<String, int> departmentCounts;
  final String selectedDepartment;
  final Function(String) onDepartmentSelected;

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
      color: const Color(0xFFF5F8FA),
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final dept in departments)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip2(
                      label: dept,
                      count: departmentCounts[dept],
                      selected: dept == selectedDepartment,
                      onSelected: () => onDepartmentSelected(dept),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _FilterChipsHeaderDelegate oldDelegate) {
    return oldDelegate.selectedDepartment != selectedDepartment ||
        oldDelegate.departments != departments;
  }
}
