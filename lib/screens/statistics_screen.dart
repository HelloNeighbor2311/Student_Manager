import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:student_manager/models/student.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key, required this.studentsListenable});

  final ValueNotifier<List<Student>> studentsListenable;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard thống kê')),
      body: ValueListenableBuilder<List<Student>>(
        valueListenable: studentsListenable,
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatisticsCards(students),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Phân bổ theo khoa/ngành (Pie)',
                  subtitle: 'Tỷ trọng sinh viên giữa các khoa',
                  child: _buildDepartmentPieChart(departmentCount),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'So sánh GPA trung bình theo khoa (Cột)',
                  subtitle: 'Top khoa có quy mô lớn nhất',
                  child: _buildAvgGpaByDepartmentBar(students, avgByDepartment),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Phân bố GPA toàn trường (Biểu đồ miền)',
                  subtitle: 'Mức độ tập trung theo dải điểm',
                  child: _buildGpaAreaChart(students),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Số lượng theo lớp (Cột)',
                  subtitle: 'Top lớp có sĩ số cao',
                  child: _buildTopGroupCountBar(classCount, top: 8),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Số lượng theo ngành (Cột)',
                  subtitle: 'So sánh nhanh giữa các ngành',
                  child: _buildTopGroupCountBar(majorCount, top: 8),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'GPA trung bình theo khóa (Biểu đồ miền)',
                  subtitle: 'Xu hướng chất lượng theo từng khóa',
                  child: _buildAvgByCourseAreaChart(avgByCourse),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Tổng quan dữ liệu học vụ',
                  subtitle: 'Bảng chi tiết theo khoa/ngành/lớp/khóa',
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
          );
        },
      ),
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
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= topKeys.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _shortLabel(topKeys[i], 10),
                      style: const TextStyle(fontSize: 10),
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
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= sorted.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _shortLabel(sorted[i].key, 10),
                      style: const TextStyle(fontSize: 10),
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
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= sorted.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _shortLabel(sorted[i].key, 8),
                      style: const TextStyle(fontSize: 10),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            child,
          ],
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
