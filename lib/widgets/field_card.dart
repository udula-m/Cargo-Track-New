import 'package:flutter/material.dart';
import '../models/thingspeak_data.dart';
import 'mini_chart.dart';

class FieldCard extends StatelessWidget {
  final String fieldKey;
  final String fieldName;
  final double value;
  final List<ThingSpeakFeed> historicalData;
  final Color color;

  const FieldCard({
    super.key,
    required this.fieldKey,
    required this.fieldName,
    required this.value,
    required this.historicalData,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              color.withOpacity(0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconForField(fieldName),
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      fieldName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getUnitForField(fieldName),
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              
              SizedBox(
                height: 40,
                child: MiniChart(
                  data: historicalData,
                  fieldKey: fieldKey,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForField(String fieldName) {
    final name = fieldName.toLowerCase();
    if (name.contains('temp')) return Icons.thermostat;
    if (name.contains('humid')) return Icons.water_drop;
    if (name.contains('pressure')) return Icons.speed;
    if (name.contains('light') || name.contains('lux')) return Icons.light_mode;
    if (name.contains('rain') || name.contains('precip')) return Icons.umbrella;
    if (name.contains('wind')) return Icons.air;
    if (name.contains('co2') || name.contains('carbon')) return Icons.cloud;
    if (name.contains('volt') || name.contains('battery')) return Icons.battery_full;
    if (name.contains('level') || name.contains('height')) return Icons.straighten;
    if (name.contains('motion') || name.contains('move')) return Icons.running_with_errors;
    return Icons.sensors;
  }

  String _getUnitForField(String fieldName) {
    final name = fieldName.toLowerCase();
    if (name.contains('temp')) return '°C';
    if (name.contains('humid')) return '%';
    if (name.contains('pressure')) return 'hPa';
    if (name.contains('light') || name.contains('lux')) return 'lux';
    if (name.contains('rain') || name.contains('precip')) return 'mm';
    if (name.contains('wind')) return 'km/h';
    if (name.contains('co2')) return 'ppm';
    if (name.contains('volt') || name.contains('battery')) return 'V';
    if (name.contains('level') || name.contains('height')) return 'cm';
    return '';
  }
}
