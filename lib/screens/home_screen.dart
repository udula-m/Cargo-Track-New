import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/iot_data_provider.dart';
import '../models/thingspeak_data.dart';
import 'device_detail_screen.dart';
import 'add_device_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IoT Devices'),
      ),
      body: Consumer<IoTDataProvider>(
        builder: (context, provider, child) {
          if (provider.devices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.devices, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No devices added yet',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Device'),
                    onPressed: () {
                      _navigateToAddDevice(context);
                    },
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: provider.devices.length,
            itemBuilder: (context, index) {
              final device = provider.devices[index];
              final hasData = provider.deviceData.containsKey(device.channelId) && 
                             provider.deviceData[device.channelId]!.isNotEmpty;
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(Icons.sensors, color: Colors.white),
                  ),
                  title: Text(device.name),
                  subtitle: Text(
                    hasData 
                        ? 'Last updated: ${_formatDate(provider.deviceData[device.channelId]!.first.createdAt)}'
                        : 'Channel ID: ${device.channelId}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          provider.refreshDeviceData(device.channelId, device.readApiKey);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          _confirmDeleteDevice(context, provider, device);
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DeviceDetailScreen(device: device),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _navigateToAddDevice(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToAddDevice(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddDeviceScreen()),
    );
  }

  void _confirmDeleteDevice(BuildContext context, IoTDataProvider provider, ThingSpeakDevice device) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Device'),
          content: Text('Are you sure you want to remove ${device.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                provider.removeDevice(device);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${device.name} removed')),
                );
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(String dateString) {
    final dateTime = DateTime.parse(dateString);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }
}
