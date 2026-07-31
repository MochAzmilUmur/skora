import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Distribusi nilai ujian dalam 4 bucket: <50, 50-69, 70-84, 85-100.
class ExamScoreDistributionChart extends StatefulWidget {
  final List<double> scores;
  const ExamScoreDistributionChart({super.key, required this.scores});

  @override
  State<ExamScoreDistributionChart> createState() =>
      _ExamScoreDistributionChartState();
}

class _ExamScoreDistributionChartState
    extends State<ExamScoreDistributionChart> {
  int _touched = -1;

  static const _labels = ['<50', '50-69', '70-84', '85-100'];
  static const _colors = [Colors.red, Colors.orange, Colors.blue, Colors.green];

  List<int> get _buckets {
    final b = [0, 0, 0, 0];
    for (final s in widget.scores) {
      if (s < 50) { b[0]++; }
      else if (s < 70) { b[1]++; }
      else if (s < 85) { b[2]++; }
      else { b[3]++; }
    }
    return b;
  }

  @override
  Widget build(BuildContext context) {
    final buckets = _buckets;
    final total = widget.scores.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2942),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribusi Nilai',
            style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                backgroundColor: Colors.transparent,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF0F172A),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final count = buckets[group.x];
                      final pct = total == 0
                          ? '0%'
                          : '${(count / total * 100).toStringAsFixed(0)}%';
                      return BarTooltipItem(
                        '$count peserta\n$pct',
                        const TextStyle(color: Colors.white, fontSize: 11),
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    setState(() {
                      _touched = (event.isInterestedForInteractions &&
                              response?.spot != null)
                          ? response!.spot!.touchedBarGroupIndex
                          : -1;
                    });
                  },
                  handleBuiltInTouches: true,
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(_labels[v.toInt()],
                            style: const TextStyle(
                                color: Color(0xFF64748B), fontSize: 10)),
                      ),
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: Color(0xFF1E293B),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(4, (i) {
                  final isTouched = _touched == i;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: buckets[i].toDouble(),
                        color: _colors[i]
                            .withValues(alpha: isTouched ? 1.0 : 0.75),
                        width: 32,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
