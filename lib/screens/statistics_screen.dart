import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:student_manager/models/student.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key, required this.studentsListenable});

  final ValueNotifier<List<Student>> studentsListenable;

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late ValueNotifier<List<Student>> _studentsNotifier;

  @override
  void initState() {
    super.initState();
    _studentsNotifier = widget.studentsListenable;
    _studentsNotifier.addListener(_onStudentsChanged);
  }

  @override
  void dispose() {
    _studentsNotifier.removeListener(_onStudentsChanged);
    super.dispose();
  }

  void _onStudentsChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê sinh viên'),
        centerTitle: false,
      ),
      body: ValueListenableBuilder(
        valueListenable: _studentsNotifier,
        builder: (context, students, _) {
          if (students.isEmpty) {
            return const Center(child: Text('Không có dữ liệu thống kê'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatisticsCards(students),
                const SizedBox(height: 24),
                const Text(
                  'Phân bố sinh viên theo ngành',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildPieChart(students),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Phân bố GPA',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildBarChart(students),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Chi tiết theo ngành',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _buildDepartmentTable(students),
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

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _StatisticCard(
          label: 'Tổng sinh viên',
          value: totalStudents.toString(),
          icon: Icons.people_rounded,
          color: Colors.blue,
        ),
        _StatisticCard(
          label: 'GPA trung bình',
          value: avgGpa.toStringAsFixed(2),
          icon: Icons.trending_up_rounded,
          color: Colors.green,
        ),
        _StatisticCard(
          label: 'GPA cao nhất',
          value: maxGpa.toStringAsFixed(2),
          icon: Icons.stars_rounded,
          color: Colors.amber,
        ),
        _StatisticCard(
          label: 'GPA thấp nhất',
          value: minGpa.toStringAsFixed(2),
          icon: Icons.trending_down_rounded,
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildPieChart(List<Student> students) {
    final deptMap = <String, int>{};
    for (final student in students) {
      deptMap[student.department] = (deptMap[student.department] ?? 0) + 1;
    }

    final sections = <PieChartSectionData>[];
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.red];
    int index = 0;

    deptMap.forEach((dept, count) {
      final percentage = (count / students.length) * 100;
      sections.add(
        PieChartSectionData(
          color: colors[index % colors.length],
          value: count.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 80,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      index++;
    });

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PieChart(PieChartData(sections: sections)),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: List.generate(deptMap.length, (i) {
            final dept = deptMap.keys.toList()[i];
            final count = deptMap[dept]!;
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
                Text('$dept ($count)'),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildBarChart(List<Student> students) {
    final gpaRanges = {
      '3.5-4.0': 0,
      '3.0-3.5': 0,
      '2.5-3.0': 0,
      '2.0-2.5': 0,
      '< 2.0': 0,
    };

    for (final student in students) {
      if (student.gpa >= 3.5) {
        gpaRanges['3.5-4.0'] = gpaRanges['3.5-4.0']! + 1;
      } else if (student.gpa >= 3.0) {
        gpaRanges['3.0-3.5'] = gpaRanges['3.0-3.5']! + 1;
      } else if (student.gpa >= 2.5) {
        gpaRanges['2.5-3.0'] = gpaRanges['2.5-3.0']! + 1;
      } else if (student.gpa >= 2.0) {
        gpaRanges['2.0-2.5'] = gpaRanges['2.0-2.5']! + 1;
      } else {
        gpaRanges['< 2.0'] = gpaRanges['< 2.0']! + 1;
      }
    }

    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < gpaRanges.length; i++) {
      final count = gpaRanges.values.toList()[i];
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: Colors.teal,
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
      height: 300,
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final ranges = gpaRanges.keys.toList();
                  return Text(ranges[value.toInt()]);
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 30),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          maxY: (gpaRanges.values.reduce((a, b) => a > b ? a : b) + 2)
              .toDouble(),
        ),
      ),
    );
  }

  Widget _buildDepartmentTable(List<Student> students) {
    final deptMap = <String, List<Student>>{};
    for (final student in students) {
      if (!deptMap.containsKey(student.department)) {
        deptMap[student.department] = [];
      }
      deptMap[student.department]!.add(student);
    }

    return Card(
      child: Column(
        children: List.generate(deptMap.length, (index) {
          final dept = deptMap.keys.toList()[index];
          final deptStudents = deptMap[dept]!;
          final avgGpa =
              deptStudents.fold<double>(0, (sum, s) => sum + s.gpa) /
              deptStudents.length;

          return Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: index < deptMap.length - 1 ? 1 : 0,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dept,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${deptStudents.length} sinh viên',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  Text(
                    'GPA: ${avgGpa.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
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
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
