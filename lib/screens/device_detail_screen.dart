import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/thingspeak_data.dart';
import '../providers/iot_data_provider.dart';
import '../widgets/chart_card.dart';

class DeviceDetailScreen extends StatefulWidget {
  final ThingSpeakDevice device;
  
  const DeviceDetailScreen({super.key, required this.device});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() => Provider.of<IoTDataProvider>(context, listen: false)
        .refreshDeviceData(widget.device.channelId, widget.device.readApiKey));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<IoTDataProvider>(context, listen: false)
                  .refreshDeviceData(widget.device.channelId, widget.device.readApiKey);
            },
          ),
        ],
      ),
      body: Consumer<IoTDataProvider>(
        builder: (context, provider, child) {
          final channelInfo = provider.channelInfo[widget.device.channelId];
          final deviceData = provider.deviceData[widget.device.channelId] ?? [];
          
          if (provider.isLoading && deviceData.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (deviceData.isEmpty) {
            return const Center(
              child: Text('No data available for this device'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDeviceInfoCard(widget.device, channelInfo),
                const SizedBox(height: 16),
                
                if (channelInfo != null) ...[
                  Text(
                    'Channel Fields',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  
                  
                  ...channelInfo.fieldLabels.entries.map((entry) {
                    final fieldKey = entry.key;
                    final fieldLabel = entry.value;
                    
                    
                    final fieldNumber = int.parse(fieldKey.substring(5));
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ChartCard(
                        title: fieldLabel,
                        fieldKey: fieldKey,
                        data: deviceData,
                      ),
                    );
                  }).toList(),
                ],
                
                const SizedBox(height: 16),
                _buildLatestDataTable(deviceData, channelInfo),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeviceInfoCard(ThingSpeakDevice device, ThingSpeakChannel? channelInfo) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.sensors,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    device.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            if (device.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(device.description),
            ],
            const SizedBox(height: 16),
            Text('Channel ID: ${device.channelId}'),
            if (channelInfo != null) ...[
              const SizedBox(height: 4),
              Text('Last Entry ID: ${channelInfo.lastEntryId}'),
              const SizedBox(height: 4),
              Text('Created: ${_formatDate(channelInfo.createdAt)}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLatestDataTable(List<ThingSpeakFeed> data, ThingSpeakChannel? channelInfo) {
    if (data.isEmpty) return const SizedBox.shrink();
    
    final latestData = data.first;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Latest Reading',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'Time: ${_formatDateTime(latestData.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            

            ...latestData.fieldValues.entries.map((entry) {
              final fieldKey = entry.key;
              final fieldValue = entry.value;
              final fieldLabel = channelInfo?.fieldLabels[fieldKey] ?? fieldKey;
              

              IconData icon = _getIconForField(fieldLabel.toLowerCase());
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(fieldLabel),
                      ],
                    ),
                    Text(
                      fieldValue.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // Add helper method to identify sensor types
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

  String _formatDate(String dateString) {
    final dateTime = DateTime.parse(dateString);
    return DateFormat('MMM d, yyyy').format(dateTime);
  }
  
  String _formatDateTime(String dateString) {
    final dateTime = DateTime.parse(dateString);
    return DateFormat('MMM d, yyyy - HH:mm:ss').format(dateTime);
  }
}
