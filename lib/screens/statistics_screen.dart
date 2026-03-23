import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:student_manager/models/student.dart';

class ScholarshipStudent {
  final Student student;
  final String scholarship;

  ScholarshipStudent({required this.student, required this.scholarship});
}

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key, required this.studentsListenable});

  final ValueNotifier<List<Student>> studentsListenable;

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String? _focusedSectionId;
  Rect? _focusRect;
  final GlobalKey _stackKey = GlobalKey();
  final Map<String, GlobalKey> _sectionKeys = <String, GlobalKey>{};

  bool _isFocused(String id) => _focusedSectionId == id;

  GlobalKey _sectionKey(String id) {
    return _sectionKeys.putIfAbsent(id, () => GlobalKey(debugLabel: id));
  }

  void _toggleFocus(String id) {
    setState(() {
      _focusedSectionId = _focusedSectionId == id ? null : id;
      if (_focusedSectionId == null) {
        _focusRect = null;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateFocusRect();
    });
  }

  void _updateFocusRect() {
    if (!mounted || _focusedSectionId == null) return;

    final stackContext = _stackKey.currentContext;
    final sectionContext = _sectionKeys[_focusedSectionId!]?.currentContext;
    if (stackContext == null || sectionContext == null) return;

    final stackBox = stackContext.findRenderObject() as RenderBox?;
    final sectionBox = sectionContext.findRenderObject() as RenderBox?;
    if (stackBox == null || sectionBox == null) return;

    final offset = sectionBox.localToGlobal(Offset.zero, ancestor: stackBox);
    final newRect = offset & sectionBox.size;

    if (_focusRect == newRect) return;
    setState(() {
      _focusRect = newRect;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard thống kê')),
      body: ValueListenableBuilder<List<Student>>(
        valueListenable: widget.studentsListenable,
        builder: (context, students, _) {
          if (students.isEmpty) {
            return const Center(child: Text('Không có dữ liệu thống kê'));
          }

          final departmentCount = _countBy(students, (s) => s.department);
          final majorCount = _countBy(students, (s) => s.major);
          final classCount = _countBy(students, (s) => s.className);
          final courseCount = _countBy(students, (s) => s.course);
          final avgByDepartment = _averageGpaBy(students, (s) => s.department);
          final avgByCourse = _averageGpaBy(students, (s) => s.course);

          if (_focusedSectionId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateFocusRect();
            });
          }

          return Stack(
            key: _stackKey,
            children: [
              SingleChildScrollView(
                physics: _focusedSectionId == null
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatisticsCards(students),
                    const SizedBox(height: 16),
                    _buildInteractiveSection(
                      id: 'dept-pie',
                      title: 'Phân bổ theo khoa/ngành (Pie)',
                      subtitle: 'Tỷ trọng sinh viên giữa các khoa',
                      details: const [
                        'Nhấn lại để thu gọn.',
                        'Bảng màu thể hiện tỷ trọng theo từng khoa/ngành.',
                      ],
                      child: _buildDepartmentPieChart(departmentCount),
                    ),
                    const SizedBox(height: 16),
                    _buildInteractiveSection(
                      id: 'dept-gpa-bar',
                      title: 'So sánh GPA trung bình theo khoa (Cột)',
                      subtitle: 'Top khoa có quy mô lớn nhất',
                      details: const [
                        'Mỗi cột đại diện GPA trung bình của 1 khoa.',
                        'Khi focus, bạn có thể quan sát nhãn trục rõ hơn.',
                      ],
                      child: _buildAvgGpaByDepartmentBar(
                        students,
                        avgByDepartment,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInteractiveSection(
                      id: 'course-line',
                      title: 'GPA trung bình theo khóa (Đường)',
                      subtitle: 'Xu hướng chất lượng theo từng khóa học',
                      details: const [
                        'Đường càng cao thì chất lượng GPA trung bình càng tốt.',
                        'Hữu ích để so sánh xu hướng theo từng niên khóa.',
                      ],
                      child: _buildAvgByCourseAreaChart(avgByCourse),
                    ),
                    const SizedBox(height: 16),
                    _buildInteractiveSection(
                      id: 'gpa-area',
                      title: 'Phân bố GPA toàn trường (Biểu đồ miền)',
                      subtitle: 'Mức độ tập trung theo dải điểm',
                      details: const [
                        'Đỉnh miền cao cho biết nhiều sinh viên ở dải GPA đó.',
                        'Dùng để đánh giá phân bố chất lượng toàn cục.',
                      ],
                      child: _buildGpaAreaChart(students),
                    ),
                    const SizedBox(height: 16),
                    _buildInteractiveSection(
                      id: 'class-bar',
                      title: 'Số lượng theo lớp (Cột)',
                      subtitle: 'Top lớp có sĩ số cao',
                      details: const [
                        'Các nhãn trục đã xoay để tránh chồng chữ.',
                        'Ưu tiên hiển thị lớp có số lượng sinh viên lớn.',
                      ],
                      child: _buildTopGroupCountBar(classCount, top: 8),
                    ),
                    const SizedBox(height: 16),

                    _buildInteractiveSection(
                      id: 'scholarship-table',
                      title: 'Top 3 Sinh viên học bổng theo Khoa - Khóa',
                      subtitle: 'Sinh viên GPA cao nhất mỗi khoa theo khóa',
                      details: const [
                        'Bảng có cuộn ngang để không tràn viền.',
                        'Tên và mã sinh viên dài sẽ được rút gọn thông minh.',
                      ],
                      child: _buildScholarshipTable(context, students),
                    ),
                    const SizedBox(height: 16),
                    _buildInteractiveSection(
                      id: 'major-bar',
                      title: 'Số lượng theo ngành (Cột)',
                      subtitle: 'So sánh nhanh giữa các ngành',
                      details: const [
                        'Giúp nhận ra ngành có quy mô tuyển sinh lớn.',
                        'Nhãn trục được tối ưu cho màn hình nhỏ.',
                      ],
                      child: _buildTopGroupCountBar(majorCount, top: 8),
                    ),
                    const SizedBox(height: 16),
                    _buildInteractiveSection(
                      id: 'overview-table',
                      title: 'Tổng quan dữ liệu học vụ',
                      subtitle: 'Bảng chi tiết theo khoa/ngành/lớp/khóa',
                      details: const [
                        'Tóm tắt nhanh các nhóm lớn nhất theo từng chiều dữ liệu.',
                        'Kết hợp sĩ số và GPA trung bình để so sánh đa chiều.',
                      ],
                      child: _buildDataOverviewTable(
                        departmentCount: departmentCount,
                        majorCount: majorCount,
                        classCount: classCount,
                        courseCount: courseCount,
                        avgByDepartment: avgByDepartment,
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
              IgnorePointer(
                ignoring: true,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: _focusedSectionId == null ? 0 : 1,
                  child: CustomPaint(
                    painter: _FocusBackdropPainter(holeRect: _focusRect),
                    size: Size.infinite,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInteractiveSection({
    required String id,
    required String title,
    required String subtitle,
    required Widget child,
    required List<String> details,
  }) {
    return KeyedSubtree(
      key: _sectionKey(id),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        scale: _isFocused(id) ? 1.03 : 1,
        child: _SectionCard(
          title: title,
          subtitle: subtitle,
          isFocused: _isFocused(id),
          focusDetails: details,
          onTap: () => _toggleFocus(id),
          child: child,
        ),
      ),
    );
  }

  Map<String, List<Student>> _top3ScholarshipByDepartmentCourse(
    List<Student> students,
  ) {
    final Map<String, List<Student>> groups = {};

    for (final s in students) {
      final dept = s.department.trim().isEmpty
          ? 'Chưa phân khoa'
          : s.department;
      final course = s.course.trim().isEmpty ? 'Chưa khóa' : s.course;

      final key = '$dept - $course';

      groups.putIfAbsent(key, () => []);
      groups[key]!.add(s);
    }

    final result = <String, List<Student>>{};

    groups.forEach((key, list) {
      list.sort((a, b) => b.gpa.compareTo(a.gpa));
      result[key] = list.take(3).toList();
    });

    return result;
  }

  Widget _buildScholarshipTable(BuildContext context, List<Student> students) {
    final data = _top3ScholarshipByDepartmentCourse(students);
    final minTableWidth = MediaQuery.of(context).size.width + 120;

    return Column(
      children: data.entries.map((entry) {
        final group = entry.key;
        final list = entry.value;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Khoa - Khóa: $group",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: minTableWidth),
                    child: DataTable(
                      columnSpacing: 18,
                      headingRowHeight: 42,
                      dataRowMinHeight: 46,
                      dataRowMaxHeight: 66,
                      columns: const [
                        DataColumn(
                          label: SizedBox(width: 36, child: Text('Top')),
                        ),
                        DataColumn(
                          label: SizedBox(width: 122, child: Text('Tên')),
                        ),
                        DataColumn(
                          label: SizedBox(width: 108, child: Text('MSSV')),
                        ),
                        DataColumn(
                          label: SizedBox(width: 44, child: Text('GPA')),
                        ),
                        DataColumn(
                          label: SizedBox(width: 86, child: Text('Học lực')),
                        ),
                      ],
                      rows: List.generate(list.length, (i) {
                        final s = list[i];

                        return DataRow(
                          cells: [
                            DataCell(Text('#${i + 1}')),
                            DataCell(
                              SizedBox(
                                width: 122,
                                child: Text(
                                  s.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 108,
                                child: Text(
                                  s.studentCode,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(Text(s.gpa.toStringAsFixed(2))),
                            DataCell(
                              SizedBox(
                                width: 86,
                                child: Text(
                                  s.academicRankLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatisticsCards(List<Student> students) {
    final totalStudents = students.length;
    final avgGpa =
        students.fold<double>(0, (sum, s) => sum + s.gpa) / totalStudents;
    final maxGpa = students.fold<double>(
      0,
      (max, s) => s.gpa > max ? s.gpa : max,
    );
    final minGpa = students.fold<double>(
      4.0,
      (min, s) => s.gpa < min ? s.gpa : min,
    );
    final excellent = students.where((s) => s.gpa >= 3.6).length;
    final warning = students.where((s) => s.gpa < 2.5).length;
    final departments = students.map((s) => s.department).toSet().length;
    final classes = students.map((s) => s.className).toSet().length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width < 640 ? 2 : 3;
        final childAspectRatio = width < 640 ? 1.24 : 1.08;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
          children: [
            _StatisticCard(
              label: 'Tổng sinh viên',
              value: totalStudents.toString(),
              icon: Icons.groups_rounded,
              color: const Color(0xFF1976D2),
            ),
            _StatisticCard(
              label: 'GPA trung bình',
              value: avgGpa.toStringAsFixed(2),
              icon: Icons.trending_up_rounded,
              color: const Color(0xFF2E7D32),
            ),
            _StatisticCard(
              label: 'GPA cao nhất',
              value: maxGpa.toStringAsFixed(2),
              icon: Icons.stars_rounded,
              color: const Color(0xFFE65100),
            ),
            _StatisticCard(
              label: 'GPA thấp nhất',
              value: minGpa.toStringAsFixed(2),
              icon: Icons.trending_down_rounded,
              color: const Color(0xFFC62828),
            ),
            _StatisticCard(
              label: 'Xuất sắc (>=3.6)',
              value: excellent.toString(),
              icon: Icons.workspace_premium_rounded,
              color: const Color(0xFF00796B),
            ),
            _StatisticCard(
              label: 'Cần cải thiện (<2.5)',
              value: warning.toString(),
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFF6A1B9A),
            ),
            _StatisticCard(
              label: 'Số khoa/ngành',
              value: departments.toString(),
              icon: Icons.account_tree_outlined,
              color: const Color(0xFF5D4037),
            ),
            _StatisticCard(
              label: 'Số lớp',
              value: classes.toString(),
              icon: Icons.meeting_room_outlined,
              color: const Color(0xFF00838F),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDepartmentPieChart(Map<String, int> departmentCount) {
    final total = departmentCount.values.fold<int>(0, (a, b) => a + b);
    final sorted = _sortedCountEntries(departmentCount, top: 6);

    final colors = <Color>[
      const Color(0xFF1976D2),
      const Color(0xFF388E3C),
      const Color(0xFFF57C00),
      const Color(0xFF7B1FA2),
      const Color(0xFFD32F2F),
      const Color(0xFF00796B),
    ];

    final sections = <PieChartSectionData>[];
    for (int index = 0; index < sorted.length; index++) {
      final entry = sorted[index];
      final percentage = (entry.value / total) * 100;
      sections.add(
        PieChartSectionData(
          color: colors[index % colors.length],
          value: entry.value.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 72,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 26,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: List.generate(sorted.length, (i) {
            final item = sorted[i];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[i % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text('${item.key} (${item.value})'),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAvgGpaByDepartmentBar(
    List<Student> students,
    Map<String, double> avgByDepartment,
  ) {
    final countByDepartment = _countBy(students, (s) => s.department);
    final keys = countByDepartment.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topKeys = keys.take(6).map((e) => e.key).toList(growable: false);

    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < topKeys.length; i++) {
      final gpa = avgByDepartment[topKeys[i]] ?? 0;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: gpa,
              color: const Color(0xFF006D77),
              width: 20,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 280,
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          maxY: 4.0,
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 68,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= topKeys.length) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Transform.rotate(
                      angle: -0.78,
                      child: SizedBox(
                        width: 64,
                        child: Text(
                          _shortLabel(topKeys[i], 18),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.black.withValues(alpha: 0.07),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildGpaAreaChart(List<Student> students) {
    final ranges = <String>['<2.0', '2.0-2.5', '2.5-3.0', '3.0-3.5', '3.5-4.0'];
    final counts = <double>[0, 0, 0, 0, 0];

    for (final student in students) {
      final gpa = student.gpa;
      if (gpa < 2.0) {
        counts[0]++;
      } else if (gpa < 2.5) {
        counts[1]++;
      } else if (gpa < 3.0) {
        counts[2]++;
      } else if (gpa < 3.5) {
        counts[3]++;
      } else {
        counts[4]++;
      }
    }

    final maxY = (counts.reduce((a, b) => a > b ? a : b) + 1).toDouble();

    return SizedBox(
      height: 260,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 4,
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.black.withValues(alpha: 0.08),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= ranges.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(ranges[i], style: const TextStyle(fontSize: 10));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                counts.length,
                (i) => FlSpot(i.toDouble(), counts[i]),
              ),
              color: const Color(0xFF0A7B83),
              barWidth: 3,
              isCurved: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, p, barData, index) => FlDotCirclePainter(
                  radius: 3,
                  color: const Color(0xFF0A7B83),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0A7B83).withValues(alpha: 0.38),
                    const Color(0xFF0A7B83).withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopGroupCountBar(Map<String, int> groupCount, {int top = 8}) {
    final sorted = _sortedCountEntries(groupCount, top: top);
    final maxY =
        (sorted.fold<int>(0, (max, e) => e.value > max ? e.value : max) + 1)
            .toDouble();

    return SizedBox(
      height: 280,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barGroups: List.generate(sorted.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: sorted[i].value.toDouble(),
                  width: 18,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xFF2C7DA0), Color(0xFF61A5C2)],
                  ),
                ),
              ],
            );
          }),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 68,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= sorted.length) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Transform.rotate(
                      angle: -0.78,
                      child: SizedBox(
                        width: 64,
                        child: Text(
                          _shortLabel(sorted[i].key, 18),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.black.withValues(alpha: 0.07),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildAvgByCourseAreaChart(Map<String, double> avgByCourse) {
    final sorted = avgByCourse.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (sorted.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Không có dữ liệu khóa học')),
      );
    }

    final spots = List.generate(
      sorted.length,
      (i) => FlSpot(i.toDouble(), sorted[i].value),
    );

    return SizedBox(
      height: 260,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: 0,
          maxY: 4,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.black.withValues(alpha: 0.08),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 68,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= sorted.length) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Transform.rotate(
                      angle: -0.78,
                      child: SizedBox(
                        width: 58,
                        child: Text(
                          _shortLabel(sorted[i].key, 16),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF3A86FF),
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, p, barData, index) => FlDotCirclePainter(
                  radius: 2.8,
                  color: const Color(0xFF3A86FF),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF3A86FF).withValues(alpha: 0.32),
                    const Color(0xFF3A86FF).withValues(alpha: 0.04),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataOverviewTable({
    required Map<String, int> departmentCount,
    required Map<String, int> majorCount,
    required Map<String, int> classCount,
    required Map<String, int> courseCount,
    required Map<String, double> avgByDepartment,
  }) {
    final topDepartment = _sortedCountEntries(departmentCount, top: 3);
    final topMajor = _sortedCountEntries(majorCount, top: 3);
    final topClass = _sortedCountEntries(classCount, top: 3);
    final topCourse = _sortedCountEntries(courseCount, top: 3);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _TopListBlock(
              title: 'Top khoa/ngành theo sĩ số',
              rows: topDepartment
                  .map(
                    (e) =>
                        '${e.key}: ${e.value} SV | GPA TB: ${(avgByDepartment[e.key] ?? 0).toStringAsFixed(2)}',
                  )
                  .toList(growable: false),
            ),
            const Divider(height: 20),
            _TopListBlock(
              title: 'Top ngành theo sĩ số',
              rows: topMajor
                  .map((e) => '${e.key}: ${e.value} SV')
                  .toList(growable: false),
            ),
            const Divider(height: 20),
            _TopListBlock(
              title: 'Top lớp theo sĩ số',
              rows: topClass
                  .map((e) => '${e.key}: ${e.value} SV')
                  .toList(growable: false),
            ),
            const Divider(height: 20),
            _TopListBlock(
              title: 'Top khóa theo sĩ số',
              rows: topCourse
                  .map((e) => '${e.key}: ${e.value} SV')
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, int> _countBy(
    List<Student> students,
    String Function(Student s) pick,
  ) {
    final result = <String, int>{};
    for (final student in students) {
      final raw = pick(student).trim();
      final key = raw.isEmpty ? 'Chưa phân loại' : raw;
      result[key] = (result[key] ?? 0) + 1;
    }
    return result;
  }

  Map<String, double> _averageGpaBy(
    List<Student> students,
    String Function(Student s) pick,
  ) {
    final sum = <String, double>{};
    final count = <String, int>{};

    for (final student in students) {
      final raw = pick(student).trim();
      final key = raw.isEmpty ? 'Chưa phân loại' : raw;
      sum[key] = (sum[key] ?? 0) + student.gpa;
      count[key] = (count[key] ?? 0) + 1;
    }

    final avg = <String, double>{};
    for (final key in sum.keys) {
      avg[key] = (sum[key] ?? 0) / (count[key] ?? 1);
    }
    return avg;
  }

  List<MapEntry<String, int>> _sortedCountEntries(
    Map<String, int> map, {
    int top = 8,
  }) {
    final list = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.take(top).toList(growable: false);
  }

  String _shortLabel(String input, int max) {
    if (input.length <= max) return input;
    return '${input.substring(0, max - 1)}...';
  }
}

class _FocusBackdropPainter extends CustomPainter {
  _FocusBackdropPainter({required this.holeRect});

  final Rect? holeRect;

  @override
  void paint(Canvas canvas, Size size) {
    final layerRect = Offset.zero & size;
    canvas.saveLayer(layerRect, Paint());

    canvas.drawRect(
      layerRect,
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );

    final rect = holeRect;
    if (rect != null) {
      final hole = RRect.fromRectAndRadius(
        rect.inflate(6),
        const Radius.circular(20),
      );
      canvas.drawRRect(hole, Paint()..blendMode = BlendMode.clear);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FocusBackdropPainter oldDelegate) {
    return oldDelegate.holeRect != holeRect;
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.isFocused,
    required this.focusDetails,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool isFocused;
  final List<String> focusDetails;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFocused
                  ? primary.withValues(alpha: 0.75)
                  : const Color(0x00000000),
              width: isFocused ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isFocused ? 0.12 : 0.05),
                blurRadius: isFocused ? 20 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isFocused
                          ? primary.withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isFocused ? 'Đang focus' : 'Chạm để focus',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isFocused ? primary : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              if (isFocused && focusDetails.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: focusDetails
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              '• $item',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _TopListBlock extends StatelessWidget {
  const _TopListBlock({required this.title, required this.rows});

  final String title;
  final List<String> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...rows.map(
          (row) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text(row, style: const TextStyle(fontSize: 13)),
          ),
        ),
      ],
    );
  }
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(icon, color: color, size: 24),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
