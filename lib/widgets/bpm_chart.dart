import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class BpmChart extends StatelessWidget {
  final List<FlSpot> bpmData;

  const BpmChart({super.key, required this.bpmData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SizedBox(
        height: 150,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: bpmData,
                isCurved: true,
                dotData: FlDotData(show: false),
                color: Colors.red,
                barWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}