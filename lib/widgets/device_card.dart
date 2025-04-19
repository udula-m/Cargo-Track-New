import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/thingspeak_data.dart';
import 'mini_chart.dart';

class DeviceCard extends StatelessWidget {
  final ThingSpeakDevice device;
  final List<ThingSpeakFeed> deviceData;
  final ThingSpeakChannel? channelInfo;

  const DeviceCard({
    super.key,
    required this.device,
    required this.deviceData,
    this.channelInfo,
  });

  @override
  Widget build(BuildContext context) {
    bool hasData = deviceData.isNotEmpty;
    ThingSpeakFeed? latestData = hasData ? deviceData.first : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          
          if (!hasData)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text('No data available..'),
              ),
            )
          else ...[
            
            _buildDataPreview(context, latestData!),
            
            
            if (hasData && channelInfo != null && channelInfo!.fieldLabels.isNotEmpty)
              _buildSparklineSection(context),
          ],
            
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.sensors,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                if (device.description.isNotEmpty)
                  Text(
                    device.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataPreview(BuildContext context, ThingSpeakFeed latestData) {

    final fields = latestData.fieldValues.entries.toList();
    

    debugPrint('Device ${device.name} has ${fields.length} fields to display');
    for (var field in fields) {
      debugPrint('Field ${field.key}: ${field.value}');
    }
    

    if (fields.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text('No sensor data available'),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Updated: ${_formatDateTime(latestData.createdAt)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.0,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: fields.length,
            itemBuilder: (context, index) {
              final entry = fields[index];
              final fieldKey = entry.key;
              final value = entry.value;
              

              String label;
              if (channelInfo != null && channelInfo!.fieldLabels.containsKey(fieldKey)) {
                label = channelInfo!.fieldLabels[fieldKey]!;
              } else {

                label = fieldKey.replaceAll('field', 'Sensor ');
              }

              String displayValue;
              if (value == value.toInt()) {

                displayValue = value.toInt().toString();
              } else if (value < 10) {
                displayValue = value.toStringAsFixed(2);
              } else if (value < 100) {

                displayValue = value.toStringAsFixed(1);
              } else {

                displayValue = value.toInt().toString();
              }
              

              IconData icon = _getIconForField(label.toLowerCase());
              final color = _getColorForField(fieldKey, index);
              
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.7), color.withOpacity(0.3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 16, color: Colors.black54),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayValue,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSparklineSection(BuildContext context) {
    
    if (channelInfo == null || deviceData.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trends',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...channelInfo!.fieldLabels.entries.map((entry) {
            final fieldKey = entry.key;
            final fieldLabel = entry.value;
            final color = _getColorForField(fieldKey, int.parse(fieldKey.substring(5)) - 1);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
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
                      const SizedBox(width: 6),
                      Text(
                        fieldLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  MiniChart(
                    data: deviceData,
                    fieldKey: fieldKey,
                    color: color,
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Channel: ${device.channelId}',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          Text(
            '${deviceData.length} entries',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateString) {
    final dateTime = DateTime.parse(dateString);
    return DateFormat('MMM d, yyyy - HH:mm').format(dateTime);
  }

  Color _getColorForField(String fieldKey, int index) {
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
      fieldNum = index;
    }
    
    return colors[fieldNum % colors.length];
  }

  IconData _getIconForField(String fieldName) {
    if (fieldName.contains('humid')) {
      return Icons.water_drop;
    } else if (fieldName.contains('temp')) {
      return Icons.thermostat;
    } else if (fieldName.contains('press')) {
      return Icons.speed;
    } else if (fieldName.contains('light') || fieldName.contains('lux')) {
      return Icons.wb_sunny;
    } else if (fieldName.contains('co2') || fieldName.contains('carbon')) {
      return Icons.cloud;
    } else if (fieldName.contains('battery') || fieldName.contains('power')) {
      return Icons.battery_full;
    } else if (fieldName.contains('motion') || fieldName.contains('pir')) {
      return Icons.sensors;
    } else if (fieldName.contains('door') || fieldName.contains('window')) {
      return Icons.door_front_door;
    } else {
      return Icons.analytics;
    }
  }
}