import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:student_manager/models/student.dart';
import 'package:student_manager/services/avatar_storage_service.dart';

class StudentFormResult {
  const StudentFormResult({required this.student, required this.isEdit});

  final Student student;
  final bool isEdit;
}

class StudentFormScreen extends StatefulWidget {
  const StudentFormScreen({
    super.key,
    required this.existingStudents,
    this.initialStudent,
  });

  final List<Student> existingStudents;
  final Student? initialStudent;

  bool get isEdit => initialStudent != null;

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _studentCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _gpaController = TextEditingController();

  DateTime? _birthDate;
  Gender? _gender;
  String? _department;
  String? _major;
  String? _className;
  String? _course;

  String? _avatarUrl;
  Uint8List? _avatarBytes;

  final _picker = ImagePicker();
  final _avatarStorageService = AvatarStorageService();
  bool _dirty = false;
  bool _showMissingDateError = false;
  bool _isSubmitting = false;
  bool _avatarChanged = false;

  static const int _phoneMaxLength = 10;

  static const _departments = ['CNTT', 'Kinh Tế'];
  static const _majorsByDepartment = {
    'CNTT': ['Khoa học máy tính', 'Kỹ thuật phần mềm', 'Trí tuệ nhân tạo'],
    'Kinh Tế': ['Quản trị kinh doanh', 'Kế toán', 'Tài chính ngân hàng'],
  };
  static const _classNames = [
    'CNTT-K18A',
    'CNTT-K18B',
    'CNTT-K19A',
    'QTKD-K18A',
    'QTKD-K19A',
  ];
  static const _courses = ['K18', 'K19', 'K20', 'K21'];

  @override
  void initState() {
    super.initState();
    final student = widget.initialStudent;
    if (student != null) {
      _nameController.text = student.name;
      _studentCodeController.text = student.studentCode;
      _emailController.text = student.email;
      _phoneController.text = student.phone;
      _addressController.text = student.address;
      _gpaController.text = student.gpa.toStringAsFixed(2);
      _birthDate = student.birthDate;
      _gender = student.gender;
      _department = student.department;
      _major = student.major;
      _className = student.className;
      _course = student.course;
      _avatarUrl = student.avatarUrl;
      _avatarBytes = student.avatarBytes;

      // Ensure dropdown initial values always exist in current option lists.
      if (!_departments.contains(_department)) {
        _department = null;
      }
      if (!_majors.contains(_major)) {
        _major = null;
      }
      if (!_classNames.contains(_className)) {
        _className = null;
      }
      if (!_courses.contains(_course)) {
        _course = null;
      }
    }

    for (final c in [
      _nameController,
      _studentCodeController,
      _emailController,
      _phoneController,
      _addressController,
      _gpaController,
    ]) {
      c.addListener(() {
        if (!_dirty) {
          setState(() => _dirty = true);
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentCodeController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _gpaController.dispose();
    super.dispose();
  }

  List<String> get _majors => _majorsByDepartment[_department] ?? const [];

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 80);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _avatarBytes = bytes;
      _avatarUrl = null;
      _avatarChanged = true;
      _dirty = true;
    });
  }

  Future<void> _openImageSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn từ thư viện'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Chụp ảnh từ camera'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - 18, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1985),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _dirty = true;
        _showMissingDateError = false;
      });
    }
  }

  String _normalizeStudentCode(String value) {
    return value.trim().toUpperCase();
  }

  String _normalizeEmail(String value) {
    return value.trim().toLowerCase();
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName là bắt buộc';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final required = _validateRequired(value, 'Email');
    if (required != null) return required;
    final email = _normalizeEmail(value!);
    final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(email)) {
      return 'Email không đúng định dạng (example@domain.com)';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final phone = value.trim();
    if (!RegExp(r'^\d+$').hasMatch(phone)) {
      return 'SĐT chỉ được chứa chữ số';
    }
    if (phone.length != _phoneMaxLength) {
      return 'SĐT phải gồm đúng $_phoneMaxLength số';
    }
    return null;
  }

  String? _validateGpa(String? value) {
    if (value == null || value.trim().isEmpty) return 'GPA là bắt buộc';
    final gpa = double.tryParse(value.trim());
    if (gpa == null) return 'GPA phải là số';
    if (gpa < 0 || gpa > 4) return 'GPA phải trong khoảng 0.0 - 4.0';
    return null;
  }

  String? _validateStudentCode(String? value) {
    final required = _validateRequired(value, 'MSSV');
    if (required != null) return required;
    final code = _normalizeStudentCode(value!);
    final formatRegex = RegExp(r'^[A-Z0-9\-]{6,20}$');
    if (!formatRegex.hasMatch(code)) {
      return 'MSSV gồm 6-20 ký tự: chữ, số hoặc dấu -';
    }
    final editingId = widget.initialStudent?.id;

    final duplicate = widget.existingStudents.any(
      (s) => _normalizeStudentCode(s.studentCode) == code && s.id != editingId,
    );

    if (duplicate) return 'MSSV đã tồn tại trong hệ thống';
    return null;
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy thay đổi?'),
        content: const Text('Bạn đã nhập dữ liệu. Bạn có chắc muốn hủy không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tiếp tục nhập'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _save() async {
    if (_isSubmitting) return;

    final isValid = _formKey.currentState?.validate() ?? false;
    if (_birthDate == null) {
      setState(() => _showMissingDateError = true);
    }

    if (!isValid ||
        _birthDate == null ||
        _gender == null ||
        _department == null ||
        _major == null ||
        _className == null ||
        _course == null) {
      return;
    }

    final base = widget.initialStudent;
    final studentId = base?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    var avatarUrl = _avatarUrl;

    setState(() {
      _isSubmitting = true;
    });

    if (_avatarChanged && _avatarBytes != null) {
      try {
        avatarUrl = await _avatarStorageService.uploadStudentAvatar(
          studentId: studentId,
          bytes: _avatarBytes!,
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload ảnh đại diện thất bại. Vui lòng thử lại.'),
          ),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }
    }

    final student = Student(
      id: studentId,
      name: _nameController.text.trim(),
      studentCode: _normalizeStudentCode(_studentCodeController.text),
      className: _className!,
      department: _department!,
      major: _major!,
      course: _course!,
      email: _normalizeEmail(_emailController.text),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      birthDate: _birthDate!,
      gender: _gender!,
      gpa: double.parse(_gpaController.text.trim()),
      avatarUrl: avatarUrl,
      avatarBytes: _avatarBytes,
    );

    if (!mounted) return;

    Navigator.pop(
      context,
      StudentFormResult(student: student, isEdit: widget.isEdit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEdit ? 'Sửa sinh viên' : 'Thêm sinh viên';
    final birthDateText = _birthDate == null
        ? 'Chọn ngày sinh'
        : DateFormat('dd/MM/yyyy').format(_birthDate!);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await _confirmDiscard();
        if (discard && mounted) {
          Navigator.of(this.context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                      final discard = await _confirmDiscard();
                      if (!mounted || !discard) return;
                      Navigator.of(this.context).pop();
                    },
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _save,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Lưu'),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Stack(
                  children: [
                    _FormAvatar(
                      bytes: _avatarBytes,
                      avatarUrl: _avatarUrl,
                      name: _nameController.text.trim(),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Material(
                        color: Theme.of(context).colorScheme.primary,
                        shape: const CircleBorder(),
                        child: IconButton(
                          onPressed: _isSubmitting ? null : _openImageSourceSheet,
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Họ tên *'),
                validator: (value) => _validateRequired(value, 'Họ tên'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _studentCodeController,
                decoration: const InputDecoration(labelText: 'MSSV *'),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-]')),
                  LengthLimitingTextInputFormatter(20),
                  _UpperCaseTextFormatter(),
                ],
                validator: _validateStudentCode,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email *'),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'SĐT'),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_phoneMaxLength),
                ],
                validator: _validatePhone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Địa chỉ'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ngày sinh'),
                subtitle: Text(birthDateText),
                trailing: const Icon(Icons.calendar_month_outlined),
                onTap: _pickDate,
              ),
              if (_showMissingDateError)
                const Padding(
                  padding: EdgeInsets.only(left: 12, bottom: 8),
                  child: Text(
                    'Ngày sinh là bắt buộc',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Gender>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Giới tính *'),
                items: const [
                  DropdownMenuItem(value: Gender.male, child: Text('Nam')),
                  DropdownMenuItem(value: Gender.female, child: Text('Nữ')),
                  DropdownMenuItem(value: Gender.other, child: Text('Khác')),
                ],
                validator: (value) =>
                    value == null ? 'Giới tính là bắt buộc' : null,
                onChanged: (value) => setState(() {
                  _gender = value;
                  _dirty = true;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('department-$_department'),
                initialValue: _department,
                decoration: const InputDecoration(labelText: 'Khoa *'),
                items: _departments
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                validator: (value) => value == null ? 'Khoa là bắt buộc' : null,
                onChanged: (value) => setState(() {
                  _department = value;
                  if (!_majors.contains(_major)) {
                    _major = null;
                  }
                  _dirty = true;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('major-$_department-$_major'),
                initialValue: _major,
                decoration: const InputDecoration(labelText: 'Ngành *'),
                items: _majors
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                validator: (value) =>
                    value == null ? 'Ngành là bắt buộc' : null,
                onChanged: (value) => setState(() {
                  _major = value;
                  _dirty = true;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _className,
                decoration: const InputDecoration(labelText: 'Lớp *'),
                items: _classNames
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                validator: (value) => value == null ? 'Lớp là bắt buộc' : null,
                onChanged: (value) => setState(() {
                  _className = value;
                  _dirty = true;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _course,
                decoration: const InputDecoration(labelText: 'Khóa học *'),
                items: _courses
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                validator: (value) =>
                    value == null ? 'Khóa học là bắt buộc' : null,
                onChanged: (value) => setState(() {
                  _course = value;
                  _dirty = true;
                }),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _gpaController,
                decoration: const InputDecoration(
                  labelText: 'GPA (0.0 - 4.0) *',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: const [_GpaTextInputFormatter()],
                validator: _validateGpa,
              ),
              const SizedBox(height: 96),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  const _UpperCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

class _GpaTextInputFormatter extends TextInputFormatter {
  const _GpaTextInputFormatter();

  static final RegExp _gpaRegex = RegExp(r'^(?:[0-3](?:\.\d{0,2})?|4(?:\.0{0,2})?)?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (_gpaRegex.hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}

class _FormAvatar extends StatelessWidget {
  const _FormAvatar({this.bytes, this.avatarUrl, required this.name});

  final Uint8List? bytes;
  final String? avatarUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();

    return Container(
      width: 104,
      height: 104,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFDAEEF1),
      ),
      clipBehavior: Clip.antiAlias,
      child: bytes != null
          ? Image.memory(bytes!, fit: BoxFit.cover)
          : (avatarUrl != null && avatarUrl!.isNotEmpty)
          ? Image.network(
              avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    );
  }
}
