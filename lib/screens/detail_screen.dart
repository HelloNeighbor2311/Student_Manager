import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:url_launcher/url_launcher.dart';
import 'package:student_manager/models/student.dart';
import 'package:student_manager/screens/student_form_screen.dart';
import 'package:student_manager/widgets/student_avatar.dart';

enum StudentDetailActionType { deleted, edited }

class StudentDetailResult {
  const StudentDetailResult({required this.type, this.student});
  final StudentDetailActionType type;
  final Student? student;
}

class DetailScreen extends StatefulWidget {
  const DetailScreen({
    super.key,
    required this.student,
    required this.existingStudents,
  });

  final Student student;
  final List<Student> existingStudents;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Student _currentStudent;

  @override
  void initState() {
    super.initState();
    _currentStudent = widget.student;
  }

  // Hàm hỗ trợ gọi điện/gửi mail (requires url_launcher package)
  // Future<void> _launchUrl(String url) async {
  //   final uri = Uri.parse(url);
  //   if (await canLaunchUrl(uri)) {
  //     await launchUrl(uri);
  //   }
  // }

  void _showFeatureInfo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng này cần cài đặt package url_launcher'),
      ),
    );
  }

  void _editStudent(BuildContext context) async {
    final result = await Navigator.push<StudentFormResult>(
      context,
      MaterialPageRoute(
        builder: (_) => StudentFormScreen(
          existingStudents: widget.existingStudents,
          initialStudent: _currentStudent,
        ),
      ),
    );

    if (result == null || !context.mounted) return;

    Navigator.pop(
      context,
      StudentDetailResult(
        type: StudentDetailActionType.edited,
        student: result.student,
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa sinh viên ${_currentStudent.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Đóng dialog
              Navigator.pop(
                context,
                StudentDetailResult(
                  type: StudentDetailActionType.deleted,
                  student: _currentStudent,
                ),
              );
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            'Chi tiết sinh viên',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: Column(
          children: [
            // --- HEADER SECTION ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Hero(
                    tag: studentAvatarHeroTag(_currentStudent.id),
                    child: StudentAvatar(student: _currentStudent, size: 120),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentStudent.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'MSSV: ${_currentStudent.studentCode}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),

            // --- TAB BAR ---
            Container(
              color: Colors.white,
              child: const TabBar(
                labelColor: Color(0xFF006D77),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF006D77),
                indicatorWeight: 3,
                tabs: [
                  Tab(text: 'Cá nhân'),
                  Tab(text: 'Học tập'),
                  Tab(text: 'Liên hệ'),
                ],
              ),
            ),

            // --- TAB CONTENT ---
            Expanded(
              child: TabBarView(
                children: [
                  _buildPersonalInfo(),
                  _buildAcademicInfo(),
                  _buildContactInfo(),
                ],
              ),
            ),
          ],
        ),

        // --- BOTTOM ACTION BAR ---
        bottomNavigationBar: _buildBottomBar(context),
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoTile(
          label: 'Ngày sinh',
          value: DateFormat('dd/MM/yyyy').format(_currentStudent.birthDate),
          icon: Icons.cake_outlined,
        ),
        _InfoTile(
          label: 'Giới tính',
          value: _currentStudent.gender.name == 'male' ? 'Nam' : 'Nữ',
          icon: Icons.person_outline,
        ),
        _InfoTile(
          label: 'Địa chỉ',
          value: _currentStudent.address,
          icon: Icons.location_on_outlined,
        ),
      ],
    );
  }

  Widget _buildAcademicInfo() {
    final rank = _currentStudent.academicRank;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoTile(
          label: 'Khoa',
          value: _currentStudent.department,
          icon: Icons.account_balance_outlined,
        ),
        _InfoTile(
          label: 'Ngành',
          value: _currentStudent.major,
          icon: Icons.school_outlined,
        ),
        _InfoTile(
          label: 'Lớp',
          value: _currentStudent.className,
          icon: Icons.class_outlined,
        ),
        _InfoTile(
          label: 'Khóa học',
          value: _currentStudent.course,
          icon: Icons.calendar_today_outlined,
        ),
        const Divider(height: 32),
        _InfoTile(
          label: 'GPA',
          value: _currentStudent.gpa.toStringAsFixed(2),
          icon: Icons.grade_outlined,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getRankColor(rank).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getRankText(rank),
              style: TextStyle(
                color: _getRankColor(rank),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoTile(
          label: 'Email',
          value: _currentStudent.email,
          icon: Icons.email_outlined,
          onTap: () => _showFeatureInfo(context),
        ),
        _InfoTile(
          label: 'Số điện thoại',
          value: _currentStudent.phone,
          icon: Icons.phone_outlined,
          onTap: () => _showFeatureInfo(context),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF006D77)),
                  foregroundColor: const Color(0xFF006D77),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _editStudent(context),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Chỉnh sửa'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFFE29578),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _confirmDelete(context),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Xóa'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(AcademicRank rank) {
    switch (rank) {
      case AcademicRank.excellent:
        return const Color(0xFF0A8F5A);
      case AcademicRank.good:
        return const Color(0xFFC99A00);
      case AcademicRank.fair:
        return const Color(0xFFE67E22);
      case AcademicRank.average:
        return const Color(0xFF7F8C8D);
    }
  }

  String _getRankText(AcademicRank rank) {
    switch (rank) {
      case AcademicRank.excellent:
        return 'Xuất sắc';
      case AcademicRank.good:
        return 'Giỏi';
      case AcademicRank.fair:
        return 'Khá';
      case AcademicRank.average:
        return 'Trung bình';
    }
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
    this.trailing,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFEDF6F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF006D77), size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2D3748),
        ),
      ),
      trailing:
          trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: Colors.grey)
              : null),
      onTap: onTap,
    );
  }
}
