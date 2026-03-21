import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:student_manager/models/student.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key, required this.studentsListenable});

  final ValueListenable<List<Student>> studentsListenable;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics & Reports')),
      body: ValueListenableBuilder<List<Student>>(
        valueListenable: studentsListenable,
        builder: (context, students, _) {
          final total = students.length;
          if (total == 0) {
            return const Center(
              child: Text('Chưa có dữ liệu sinh viên để thống kê.'),
            );
          }
          return _StatisticsBody(students: students);
        },
      ),
    );
  }
}

class _StatisticsBody extends StatelessWidget {
  const _StatisticsBody({required this.students});

  final List<Student> students;

  @override
  Widget build(BuildContext context) {
    final total = students.length;
    final avgGpa =
        students.fold<double>(0, (sum, s) => sum + s.gpa) / students.length;
    final excellentGood = students
        .where(
          (s) =>
              s.academicRank == AcademicRank.excellent ||
              s.academicRank == AcademicRank.good,
        )
        .length;

    final male = students.where((s) => s.gender == Gender.male).length;
    final female = students.where((s) => s.gender == Gender.female).length;
    final maleFemaleTotal = male + female;
    final malePct = maleFemaleTotal == 0
        ? 0
        : (male / maleFemaleTotal * 100).round();
    final femalePct = maleFemaleTotal == 0
        ? 0
        : (female / maleFemaleTotal * 100).round();

    final departmentCounts = <String, int>{};
    for (final student in students) {
      departmentCounts.update(
        student.department,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    final rankCounts = {
      AcademicRank.excellent: students
          .where((s) => s.academicRank == AcademicRank.excellent)
          .length,
      AcademicRank.good: students
          .where((s) => s.academicRank == AcademicRank.good)
          .length,
      AcademicRank.fair: students
          .where((s) => s.academicRank == AcademicRank.fair)
          .length,
      AcademicRank.average: students
          .where((s) => s.academicRank == AcademicRank.average)
          .length,
    };

    final gpaByCourse = <String, List<double>>{};
    for (final student in students) {
      gpaByCourse
          .putIfAbsent(student.course, () => <double>[])
          .add(student.gpa);
    }

    final sortedCourses = gpaByCourse.keys.toList()
      ..sort(
        (a, b) => _extractCourseOrder(a).compareTo(_extractCourseOrder(b)),
      );

    final lineSpots = <FlSpot>[];
    for (var i = 0; i < sortedCourses.length; i++) {
      final course = sortedCourses[i];
      final values = gpaByCourse[course] ?? <double>[];
      final avg =
          values.fold<double>(0, (sum, item) => sum + item) /
          (values.isEmpty ? 1 : values.length);
      lineSpots.add(FlSpot(i.toDouble(), avg));
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _SummaryGrid(
              cards: [
                _MetricData(
                  title: 'Tổng sinh viên',
                  value: '$total',
                  subtitle: 'Đang quản lý',
                ),
                _MetricData(
                  title: 'GPA trung bình',
                  value: avgGpa.toStringAsFixed(2),
                  subtitle: 'Trên thang 4.0',
                ),
                _MetricData(
                  title: 'Xuất sắc/Giỏi',
                  value: '$excellentGood',
                  subtitle:
                      '${(excellentGood / total * 100).toStringAsFixed(1)}%',
                ),
                _MetricData(
                  title: 'Tỷ lệ Nam/Nữ',
                  value: '$malePct% / $femalePct%',
                  subtitle: '$male Nam - $female Nữ',
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _ChartCard(
            title: 'Phân bố theo Khoa',
            child: SizedBox(
              height: 260,
              child: _DepartmentPieChart(departmentCounts: departmentCounts),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _ChartCard(
            title: 'Phân bố theo Học lực',
            child: SizedBox(
              height: 260,
              child: _AcademicRankBarChart(rankCounts: rankCounts),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _ChartCard(
            title: 'GPA trung bình theo Khóa',
            child: SizedBox(
              height: 260,
              child: _GpaLineChart(lineSpots: lineSpots, labels: sortedCourses),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  int _extractCourseOrder(String course) {
    final digits = RegExp(r'\d+').firstMatch(course)?.group(0);
    return int.tryParse(digits ?? '') ?? 0;
  }
}

class _MetricData {
  const _MetricData({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.cards});

  final List<_MetricData> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 980 ? 4 : (width >= 620 ? 2 : 1);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 116,
          ),
          itemBuilder: (context, index) {
            final data = cards[index];
            return DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x11000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      data.value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _DepartmentPieChart extends StatelessWidget {
  const _DepartmentPieChart({required this.departmentCounts});

  final Map<String, int> departmentCounts;

  @override
  Widget build(BuildContext context) {
    final entries = departmentCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<int>(0, (sum, e) => sum + e.value);
    final colors = <Color>[
      const Color(0xFF4E79A7),
      const Color(0xFFE15759),
      const Color(0xFF76B7B2),
      const Color(0xFFF28E2B),
      const Color(0xFF59A14F),
    ];

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              sections: [
                for (var i = 0; i < entries.length; i++)
                  PieChartSectionData(
                    value: entries[i].value.toDouble(),
                    color: colors[i % colors.length],
                    title:
                        '${(entries[i].value / total * 100).toStringAsFixed(0)}%',
                    radius: 76,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: ListView(
            children: [
              for (var i = 0; i < entries.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors[i % colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${entries[i].key}: ${entries[i].value}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AcademicRankBarChart extends StatelessWidget {
  const _AcademicRankBarChart({required this.rankCounts});

  final Map<AcademicRank, int> rankCounts;

  @override
  Widget build(BuildContext context) {
    const order = [
      AcademicRank.excellent,
      AcademicRank.good,
      AcademicRank.fair,
      AcademicRank.average,
    ];

    final values = order.map((rank) => rankCounts[rank] ?? 0).toList();
    final maxValue = values.isEmpty
        ? 1.0
        : (values.reduce((a, b) => a > b ? a : b) + 1).toDouble();

    String label(AcademicRank rank) {
      switch (rank) {
        case AcademicRank.excellent:
          return 'XS';
        case AcademicRank.good:
          return 'Giỏi';
        case AcademicRank.fair:
          return 'Khá';
        case AcademicRank.average:
          return 'TB';
      }
    }

    return BarChart(
      BarChartData(
        maxY: maxValue,
        barTouchData: BarTouchData(enabled: true),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
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
              reservedSize: 28,
              interval: 1.0,
              getTitlesWidget: (value, _) => Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= order.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    label(order[index]),
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < values.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i].toDouble(),
                  width: 26,
                  borderRadius: BorderRadius.circular(6),
                  color: const Color(0xFF2A9D8F),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _GpaLineChart extends StatelessWidget {
  const _GpaLineChart({required this.lineSpots, required this.labels});

  final List<FlSpot> lineSpots;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final maxX = labels.isEmpty ? 0 : labels.length - 1;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 4,
        minX: 0,
        maxX: maxX.toDouble(),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(enabled: true),
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
              reservedSize: 28,
              interval: 1.0,
              getTitlesWidget: (value, _) => Text(
                value.toStringAsFixed(0),
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= labels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels[index],
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: lineSpots,
            color: const Color(0xFF3D5A80),
            isCurved: true,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF3D5A80).withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
