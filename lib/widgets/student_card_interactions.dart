import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:student_manager/models/student.dart';

/// GPA Trend Sparkline Chart
class GPATrendChart extends StatelessWidget {
  final double currentGpa;
  final List<double> historicalGpa;

  const GPATrendChart({
    super.key,
    required this.currentGpa,
    this.historicalGpa = const [3.2, 3.3, 3.4, 3.5, 3.6],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Xu hướng GPA',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          // Sparkline simulation
          SizedBox(
            height: 40,
            width: 200,
            child: CustomPaint(
              painter: SparklinePainter(historicalGpa + [currentGpa]),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'GPA hiện tại: ${currentGpa.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (historicalGpa.isNotEmpty)
            Text(
              'Học kỳ trước: ${historicalGpa.last.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text('Xu hướng: '),
              Text(
                currentGpa > historicalGpa.last ? '📈 Tăng' : '📉 Giảm',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: currentGpa > historicalGpa.last
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SparklinePainter extends CustomPainter {
  final List<double> data;

  SparklinePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFF0066CC)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = (size.width / (data.length - 1)) * i;
      final normalizedY =
          (data[i] - minValue) / (range > 0 ? range : 1);
      final y = size.height - (normalizedY * size.height);
      points.add(Offset(x, y));
    }

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }

    // Draw points
    final pointPaint = Paint()
      ..color = const Color(0xFF0066CC)
      ..style = PaintingStyle.fill;
    for (final point in points) {
      canvas.drawCircle(point, 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(SparklinePainter oldDelegate) => oldDelegate.data != data;
}

/// Quick Note Dialog
class QuickNoteDialog extends StatefulWidget {
  final String studentName;
  final String initialNote;
  final Function(String) onSave;

  const QuickNoteDialog({
    super.key,
    required this.studentName,
    this.initialNote = '',
    required this.onSave,
  });

  @override
  State<QuickNoteDialog> createState() => _QuickNoteDialogState();
}

class _QuickNoteDialogState extends State<QuickNoteDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('📝 Ghi chú nhanh'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ghi chú cho ${widget.studentName}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'Ví dụ: Cần nhắc nhở về học phí, Tham gia tích cực...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            widget.onSave(_controller.text);
            Navigator.pop(context);
          },
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}

/// Schedule View Bottom Sheet
class ScheduleBottomSheet extends StatelessWidget {
  final String studentName;

  const ScheduleBottomSheet({
    super.key,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    final weekDays = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6'];
    final courses = [
      {'day': 0, 'name': 'Toán A1', 'time': '07:00-08:30', 'attended': true},
      {'day': 0, 'name': 'Lý thuyết CS', 'time': '09:00-10:30', 'attended': false},
      {'day': 1, 'name': 'Anh văn', 'time': '10:00-11:30', 'attended': true},
      {'day': 2, 'name': 'CSDL', 'time': '13:00-14:30', 'attended': true},
      {'day': 3, 'name': 'OOP', 'time': '07:00-08:30', 'attended': false},
      {'day': 4, 'name': 'Web Dev', 'time': '15:00-16:30', 'attended': true},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📅 Lịch học tuần của $studentName',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            itemCount: weekDays.length,
            itemBuilder: (context, dayIndex) {
              final dayCourses = courses
                  .where((c) => c['day'] == dayIndex)
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weekDays[dayIndex],
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  ...dayCourses.map((course) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: course['attended'] == true
                                ? Colors.green
                                : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(course['name'].toString()),
                              Text(
                                course['time'].toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
                  const Divider(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Labels Manager Bottom Sheet
class LabelsManagerBottomSheet extends StatefulWidget {
  final List<String> selectedLabels;
  final Function(List<String>) onApply;

  const LabelsManagerBottomSheet({
    super.key,
    required this.selectedLabels,
    required this.onApply,
  });

  @override
  State<LabelsManagerBottomSheet> createState() =>
      _LabelsManagerBottomSheetState();
}

class _LabelsManagerBottomSheetState extends State<LabelsManagerBottomSheet> {
  late List<String> _selected;
  final List<String> _availableLabels = [
    'Cần theo dõi',
    'Lớp trưởng',
    'Học bổng',
    'Ưu tú',
    'Cần giúp đỡ',
    'Vắng học',
  ];

  @override
  void initState() {
    super.initState();
    _selected = [...widget.selectedLabels];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏷️ Thêm nhãn',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableLabels.map((label) {
              final isSelected = _selected.contains(label);
              return FilterChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selected.add(label);
                    } else {
                      _selected.remove(label);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () {
                  widget.onApply(_selected);
                  Navigator.pop(context);
                },
                child: const Text('Áp dụng'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Quick Peek Preview
class QuickPeekPreview extends StatelessWidget {
  final Student student;
  final Offset position;

  const QuickPeekPreview({
    super.key,
    required this.student,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    Color rankColor;
    switch (student.academicRank) {
      case AcademicRank.excellent:
        rankColor = const Color(0xFFD4AF37);
      case AcademicRank.good:
        rankColor = const Color(0xFF00A86B);
      case AcademicRank.fair:
        rankColor = const Color(0xFFFF9500);
      case AcademicRank.average:
        rankColor = const Color(0xFFE53935);
    }

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned(
            left: position.dx - 100,
            top: position.dy - 50,
            child: Container(
              width: 200,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: rankColor.withValues(alpha: 0.2),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundImage: student.avatarBytes != null
                          ? MemoryImage(student.avatarBytes!)
                          : null,
                      child: student.avatarBytes == null
                          ? Text(
                              student.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    student.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: rankColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      student.academicRankLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: rankColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'GPA: ${student.gpa.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '✅ Đã đóng học phí',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Copy Student Info
void copyStudentInfo(BuildContext context, Student student) {
  final info =
      '${student.name} | ${student.studentCode} | ${student.className} | ${student.email}';
  Clipboard.setData(ClipboardData(text: info));

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('✅ Đã sao chép thông tin của ${student.name}.'),
      duration: const Duration(milliseconds: 1500),
    ),
  );
}
