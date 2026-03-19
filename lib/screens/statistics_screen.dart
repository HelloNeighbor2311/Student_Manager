import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import 'package:universal_io/io.dart' as io;

import 'package:flutter/material.dart';
import 'package:student_manager/models/student.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key, required this.students});

  final List<Student> students;

  @override
  Widget build(BuildContext context) {
    final total = students.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê và báo cáo')),
      body: total == 0
          ? const Center(child: Text('Chưa có dữ liệu sinh viên để thống kê.'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Xuất PDF'),
                        onPressed: () => exportPdf(context, students),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.table_chart),
                        label: const Text('Xuất Excel'),
                        onPressed: () => exportExcel(context, students),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _StatisticsBody(students: students)),
              ],
            ),
    );

  }

  // Helper: Pie chart for PDF
  pw.Widget _buildPieChartPdf(Map<String, int> data) {
      final total = data.values.fold<int>(0, (sum, v) => sum + v);
      final colors = [
        PdfColors.blue,
        PdfColors.red,
        PdfColors.green,
        PdfColors.orange,
        PdfColors.purple,
        PdfColors.cyan,
        PdfColors.amber,
      ];
      double start = 0;
      final sections = <pw.Widget>[];
      int i = 0;
      data.forEach((k, v) {
        final sweep = total == 0 ? 0 : v / total * 360;
        sections.add(
          pw.Row(
            children: [
              pw.Container(
                width: 10,
                height: 10,
                color: colors[i % colors.length],
              ),
              pw.SizedBox(width: 6),
              pw.Text('$k: $v (${(v / total * 100).toStringAsFixed(1)}%)'),
            ],
          ),
        );
        i++;
      });
      // Không thể vẽ Pie chart thực sự với pdf/widgets, chỉ hiển thị bảng màu và số liệu
      return pw.Column(
        children: [
          pw.Text('Chú thích phân bố Khoa:'),
          ...sections,
        ],
      );
    }

  // Helper: Bar chart for PDF
  pw.Widget _buildBarChartPdf(Map<AcademicRank, int> data) {
      final order = [
        AcademicRank.excellent,
        AcademicRank.good,
        AcademicRank.fair,
        AcademicRank.average,
      ];
      final labels = ['XS', 'Giỏi', 'Khá', 'TB'];
      final values = order.map((r) => data[r] ?? 0).toList();
      final maxValue = values.isEmpty
          ? 1
          : (values.reduce((a, b) => a > b ? a : b));
      // Không dùng Stack với positional argument, chỉ hiển thị bảng số liệu
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Học lực:'),
          for (int i = 0; i < labels.length; i++)
            pw.Row(
              children: [
                pw.Container(width: 20, height: 10, color: PdfColors.blue),
                pw.SizedBox(width: 6),
                pw.Text('${labels[i]}: ${values[i]}'),
              ],
            ),
        ],
      );
    }

  // Helper: Line chart for PDF (simple dots/lines)
  pw.Widget _buildLineChartPdf(List<List<String>> data) {
      if (data.length <= 1) return pw.Text('Không có dữ liệu');
      final points = data
          .skip(1)
          .map((e) => double.tryParse(e[1]) ?? 0)
          .toList();
      final maxY = points.isEmpty
          ? 4.0
          : (points.reduce((a, b) => a > b ? a : b)).clamp(0, 4.0);
      final minY = 0.0;
      // Không dùng Stack với positional argument, chỉ hiển thị bảng số liệu
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('GPA trung bình theo Khóa:'),
          for (int i = 1; i < data.length; i++)
            pw.Text('${data[i][0]}: ${data[i][1]}'),
        ],
      );
    }

// Hàm xuất PDF
Future<void> exportPdf(
  BuildContext context,
  List<Student> students,
) async {
  try {
    final pdf = pw.Document();
    // Pie chart data
    final departmentCounts = <String, int>{};
    for (final student in students) {
      departmentCounts.update(
        student.department,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    // Bar chart data
    final rankCounts = {
      AcademicRank.excellent: students.where((s) => s.academicRank == AcademicRank.excellent).length,
      AcademicRank.good: students.where((s) => s.academicRank == AcademicRank.good).length,
      AcademicRank.fair: students.where((s) => s.academicRank == AcademicRank.fair).length,
      AcademicRank.average: students.where((s) => s.academicRank == AcademicRank.average).length,
    };
    // Line chart data
    final gpaByCourse = <String, List<double>>{};
    for (final student in students) {
      gpaByCourse.putIfAbsent(student.course, () => <double>[]).add(student.gpa);
    }
    final sortedCourses = gpaByCourse.keys.toList()
      ..sort((a, b) {
        final digitsA = RegExp(r'\\d+').firstMatch(a)?.group(0);
        final digitsB = RegExp(r'\\d+').firstMatch(b)?.group(0);
        return (int.tryParse(digitsA ?? '') ?? 0).compareTo(int.tryParse(digitsB ?? '') ?? 0);
      });
    final avgGpaByCourse = [
      ['Khóa', 'GPA TB'],
      ...sortedCourses.map((c) {
        final values = gpaByCourse[c] ?? [];
        final avg = values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length;
        return [c, avg.toStringAsFixed(2)];
      }),
    ];

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('Báo cáo Danh sách Sinh viên', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: ['Mã SV', 'Tên', 'Khoa', 'GPA', 'Học lực', 'Giới tính'],
            data: students.map((s) => [s.id, s.name, s.department, s.gpa.toStringAsFixed(2), s.academicRankLabel, s.genderLabel]).toList(),
          ),
          pw.SizedBox(height: 24),
          pw.Text('Biểu đồ thống kê', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.Text('Phân bố sinh viên theo Khoa (Pie Chart):'),
          pw.SizedBox(height: 6),
          _buildPieChartPdf(departmentCounts),
          pw.SizedBox(height: 18),
          pw.Text('Phân bố theo Học lực (Bar Chart):'),
          pw.SizedBox(height: 6),
          _buildBarChartPdf(rankCounts),
          pw.SizedBox(height: 18),
          pw.Text('GPA trung bình theo Khóa (Line Chart):'),
          pw.SizedBox(height: 6),
          _buildLineChartPdf(avgGpaByCourse),
        ],
      ),
    );
    final pdfBytes = await pdf.save();
    
    if (kIsWeb) {
      // Web: download file
      final blob = html.Blob([pdfBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)..setAttribute('download', 'bao_cao_sinh_vien.pdf')..click();
      html.Url.revokeObjectUrl(url);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã tải xuống file PDF')));
    } else {
      // Native: write to file
      final dir = await path_provider.getTemporaryDirectory();
      final file = io.File('${dir.path}/bao_cao_sinh_vien.pdf');
      await file.writeAsBytes(pdfBytes);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã lưu file PDF: ${file.path}')));
    }
  } catch (e, stack) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lỗi xuất PDF: $e')),
    );
    print('Lỗi xuất PDF: $e\n$stack');
  }
}

// Hàm xuất Excel
Future<void> exportExcel(
  BuildContext context,
  List<Student> students,
) async {
  try {
    final excel = Excel.createExcel();
    final sheet = excel['SinhVien'];
    sheet.appendRow([
      TextCellValue('Mã SV'),
      TextCellValue('Tên'),
      TextCellValue('Khoa'),
      TextCellValue('GPA'),
      TextCellValue('Học lực'),
      TextCellValue('Giới tính'),
    ]);
    for (final s in students) {
      sheet.appendRow([
        TextCellValue(s.id),
        TextCellValue(s.name),
        TextCellValue(s.department),
        DoubleCellValue(s.gpa),
        TextCellValue(s.academicRankLabel),
        TextCellValue(s.genderLabel),
      ]);
    }
    // Pie chart data sheet
    final pieSheet = excel['PieChart_Khoa'];
    final departmentCounts = <String, int>{};
    for (final student in students) {
      departmentCounts.update(
        student.department,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    pieSheet.appendRow([
      TextCellValue('Khoa'),
      TextCellValue('Số lượng'),
    ]);
    departmentCounts.forEach((k, v) => pieSheet.appendRow([
      TextCellValue(k),
      IntCellValue(v),
    ]));
    // Bar chart data sheet
    final barSheet = excel['BarChart_HocLuc'];
    barSheet.appendRow([
      TextCellValue('Học lực'),
      TextCellValue('Số lượng'),
    ]);
    final rankLabels = {
      AcademicRank.excellent: 'Xuất sắc',
      AcademicRank.good: 'Giỏi',
      AcademicRank.fair: 'Khá',
      AcademicRank.average: 'Trung bình',
    };
    final rankCounts = {
      AcademicRank.excellent: students.where((s) => s.academicRank == AcademicRank.excellent).length,
      AcademicRank.good: students.where((s) => s.academicRank == AcademicRank.good).length,
      AcademicRank.fair: students.where((s) => s.academicRank == AcademicRank.fair).length,
      AcademicRank.average: students.where((s) => s.academicRank == AcademicRank.average).length,
    };
    rankCounts.forEach((k, v) => barSheet.appendRow([
      TextCellValue(rankLabels[k] ?? ''),
      IntCellValue(v),
    ]));
    // Line chart data sheet
    final lineSheet = excel['LineChart_GPA_Khoa'];
    final gpaByCourse = <String, List<double>>{};
    for (final student in students) {
      gpaByCourse.putIfAbsent(student.course, () => <double>[]).add(student.gpa);
    }
    final sortedCourses = gpaByCourse.keys.toList()
      ..sort((a, b) {
        final digitsA = RegExp(r'\\d+').firstMatch(a)?.group(0);
        final digitsB = RegExp(r'\\d+').firstMatch(b)?.group(0);
        return (int.tryParse(digitsA ?? '') ?? 0).compareTo(int.tryParse(digitsB ?? '') ?? 0);
      });
    lineSheet.appendRow([
      TextCellValue('Khóa'),
      TextCellValue('GPA TB'),
    ]);
    for (final c in sortedCourses) {
      final values = gpaByCourse[c] ?? [];
      final avg = values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length;
      lineSheet.appendRow([
        TextCellValue(c),
        TextCellValue(avg.toStringAsFixed(2)),
      ]);
    }
    final excelBytes = excel.encode();
    
    if (kIsWeb && excelBytes != null) {
      // Web: download file
      final blob = html.Blob([excelBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)..setAttribute('download', 'bao_cao_sinh_vien.xlsx')..click();
      html.Url.revokeObjectUrl(url);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã tải xuống file Excel')));
    } else if (!kIsWeb && excelBytes != null) {
      final dir = await path_provider.getTemporaryDirectory();
      final file = io.File('${dir.path}/bao_cao_sinh_vien.xlsx');
      await file.writeAsBytes(excelBytes);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã lưu file Excel: ${file.path}')));
    }
  } catch (e, stack) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lỗi xuất Excel: $e')),
    );
    print('Lỗi xuất Excel: $e\n$stack');
  }
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
