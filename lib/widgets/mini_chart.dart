import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/thingspeak_data.dart';

class MiniChart extends StatelessWidget {
  final List<ThingSpeakFeed> data;
  final String fieldKey;
  final Color color;

  const MiniChart({
    super.key, 
    required this.data, 
    required this.fieldKey,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(height: 40);
    }

    final chartData = data.reversed.toList();
    
    
    final values = chartData
        .map((feed) => feed.fieldValues[fieldKey] ?? 0.0)
        .toList();
    
    if (values.isEmpty) {
      return const SizedBox(height: 40);
    }
    
    
    double minY = values.reduce((curr, next) => curr < next ? curr : next);
    double maxY = values.reduce((curr, next) => curr > next ? curr : next);
    
    
    if ((maxY - minY).abs() < 0.1) {
      minY = minY - 1;
      maxY = maxY + 1;
    } else {
      final padding = (maxY - minY) * 0.1;
      minY -= padding;
      maxY += padding;
    }

    return SizedBox(
      height: 40,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          minX: 0,
          maxX: chartData.length.toDouble() - 1,
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(chartData.length, (index) {
                final value = chartData[index].fieldValues[fieldKey] ?? 0.0;
                return FlSpot(index.toDouble(), value);
              }),
              isCurved: true,
              color: color,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
