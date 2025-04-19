import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/thingspeak_data.dart';

class ChartCard extends StatelessWidget {
  final String title;
  final String fieldKey;
  final List<ThingSpeakFeed> data;

  const ChartCard({
    super.key,
    required this.title,
    required this.fieldKey,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
   
    final color = _getColorForField(fieldKey);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              color.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: _buildChart(context, color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context, Color chartColor) {

    final chartData = data.reversed.toList();
    
    if (chartData.isEmpty) {
      return const Center(child: Text('No data available'));
    }

   
    final values = chartData
        .map((feed) => feed.fieldValues[fieldKey] ?? 0.0)
        .toList();
    
    if (values.isEmpty) {
      return const Center(child: Text('No values available for this field'));
    }
    
    double minY = values.reduce((curr, next) => curr < next ? curr : next);
    double maxY = values.reduce((curr, next) => curr > next ? curr : next);
    
   
    if (minY == maxY) {
      
      minY = minY - 1.0;
      maxY = maxY + 1.0;
    } else {
      
      final yPadding = (maxY - minY) * 0.1;
      minY = minY - yPadding;
      maxY = maxY + yPadding;
    }
    
    
    double horizontalInterval = (maxY - minY) / 5;
    
    
    if (horizontalInterval < 0.1) {
      horizontalInterval = 1.0;
    }
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: horizontalInterval,
          verticalInterval: chartData.length > 10 ? 2 : 1,
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: chartData.length > 6 ? (chartData.length / 6).ceil().toDouble() : 1,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value >= chartData.length) {
                  return const SizedBox();
                }
                
               
                final index = value.toInt();
                if (index < 0 || index >= chartData.length) {
                  return const SizedBox();
                }
                
                final dateTime = DateTime.parse(chartData[index].createdAt);
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('HH:mm').format(dateTime),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: horizontalInterval, 
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d), width: 1),
        ),
        minX: 0,
        maxX: chartData.length.toDouble() - 1,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(chartData.length, (index) {
              final value = chartData[index].fieldValues[fieldKey] ?? 0.0;
              return FlSpot(
                index.toDouble(),
                value,
              );
            }),
            isCurved: true,
            color: chartColor, 
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(
              show: false,
            ),
            belowBarData: BarAreaData(
              show: true,
              color: chartColor.withOpacity(0.2), 
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Theme.of(context).colorScheme.surface,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index < 0 || index >= chartData.length) {
                  return null;
                }
                final value = spot.y;
                final dateTime = DateTime.parse(chartData[index].createdAt);
                
                return LineTooltipItem(
                  '${value.toStringAsFixed(2)}\n',
                  const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: DateFormat('MMM d, HH:mm').format(dateTime),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontWeight: FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Color _getColorForField(String fieldKey) {
    final colors = [
      const Color(0xFFFF6B6B), 
      const Color(0xFF48DBFB), 
      const Color(0xFF1DD1A1), 
      const Color(0xFFFECA57), 
      const Color(0xFF5F27CD), 
      const Color(0xFFFF9FF3), 
      const Color(0xFF54A0FF), 
      const Color(0xFFFF9F43), 
    ];
    
   
    int fieldNum;
    try {
      fieldNum = int.parse(fieldKey.substring(5)) - 1;
    } catch (e) {
      fieldNum = 0;
    }
    
    return colors[fieldNum % colors.length];
  }
}
