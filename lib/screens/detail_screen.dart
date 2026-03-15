import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:student_manager/models/student.dart';
import 'package:student_manager/widgets/student_avatar.dart';

enum StudentDetailAction { deleted }

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(title: const Text('Chi tiết sinh viên')),
        bottomNavigationBar: _BottomActionBar(student: student),
        body: Column(
          children: [
            _HeaderCard(student: student),
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Thông tin cá nhân'),
                Tab(text: 'Học tập'),
                Tab(text: 'Liên hệ'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _PersonalTab(student: student),
                  _AcademicTab(student: student),
                  _ContactTab(student: student),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          StudentAvatar(student: student, size: 84, useHero: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'MSSV: ${student.studentCode}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalTab extends StatelessWidget {
  const _PersonalTab({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('dd/MM/yyyy').format(student.birthDate);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoTile(title: 'Ngày sinh', value: dateText),
        _InfoTile(title: 'Giới tính', value: student.genderLabel),
        _InfoTile(title: 'Địa chỉ', value: student.address),
      ],
    );
  }
}

class _AcademicTab extends StatelessWidget {
  const _AcademicTab({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoTile(title: 'Khoa', value: student.department),
        _InfoTile(title: 'Ngành', value: student.major),
        _InfoTile(title: 'Lớp', value: student.className),
        _InfoTile(title: 'Khóa học', value: student.course),
        _InfoTile(title: 'GPA', value: student.gpa.toStringAsFixed(2)),
        _InfoTile(title: 'Học lực', value: student.academicRankLabel),
      ],
    );
  }
}

class _ContactTab extends StatelessWidget {
  const _ContactTab({required this.student});

  final Student student;

  void _showActionMessage(BuildContext context, String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Đang mở chức năng $label...')));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoTile(title: 'Email', value: student.email),
        Card(
          child: ListTile(
            title: const Text('SĐT'),
            subtitle: Text(student.phone),
            trailing: Wrap(
              spacing: 6,
              children: [
                IconButton(
                  tooltip: 'Gọi',
                  icon: const Icon(Icons.call_outlined),
                  onPressed: () => _showActionMessage(context, 'gọi điện'),
                ),
                IconButton(
                  tooltip: 'Nhắn tin',
                  icon: const Icon(Icons.sms_outlined),
                  onPressed: () => _showActionMessage(context, 'nhắn tin'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.student});

  final Student student;

  Future<void> _confirmDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
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

    if (shouldDelete == true && context.mounted) {
      Navigator.pop(context, StudentDetailAction.deleted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đi tới màn hình chỉnh sửa.')),
                  );
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Chỉnh sửa'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
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
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(title: Text(title), subtitle: Text(value)),
    );
  }
}
