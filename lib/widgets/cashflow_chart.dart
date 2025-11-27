// widgets/cashflow_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../db/db_helper.dart';
import 'package:intl/intl.dart';

class CashflowChart extends StatefulWidget {
  final int days;
  const CashflowChart({super.key, this.days = 30});

  @override
  State<CashflowChart> createState() => _CashflowChartState();
}

class _CashflowChartState extends State<CashflowChart> {
  List<FlSpot> spots = [];
  List<String> labels = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final rows = await DBHelper.instance.cashflowGroupedByDay(days: widget.days);
    // Build map date->total for each day in range
    final now = DateTime.now();
    final from = now.subtract(Duration(days: widget.days - 1));
    Map<String, double> map = {};
    for (var r in rows) {
      final d = (r['d'] as String).substring(0, 10);
      map[d] = (r['total'] as num?)?.toDouble() ?? 0.0;
    }
    List<double> values = [];
    List<String> l = [];
    for (int i = 0; i < widget.days; i++) {
      final d = from.add(Duration(days: i));
      final key = d.toIso8601String().substring(0, 10);
      values.add(map[key] ?? 0.0);
      l.add(DateFormat.Md().format(d));
    }
    // create spots
    final s = <FlSpot>[];
    for (int i = 0; i < values.length; i++) {
      s.add(FlSpot(i.toDouble(), values[i]));
    }
    setState(() {
      spots = s;
      labels = l;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) {
      return SizedBox(height: 150, child: Center(child: Text('Belum ada data untuk chart')));
    }
    final maxY = spots.map((e) => e.y).fold(0.0, (p, e) => e.abs() > p ? e.abs() : p);
    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minY: -maxY * 1.2,
          maxY: maxY * 1.2,
          lineBarsData: [
            LineChartBarData(spots: spots, isCurved: true, color: Theme.of(context).colorScheme.primary, barWidth: 2, belowBarData: BarAreaData(show: true, color: Theme.of(context).colorScheme.primary.withOpacity(0.2))),
          ],
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: (spots.length / 4).floorToDouble(), getTitlesWidget: (v, meta) {
              final idx = v.toInt();
              if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
              return Text(labels[idx], style: const TextStyle(fontSize: 10));
            })),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}