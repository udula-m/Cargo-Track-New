import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/iot_data_provider.dart';
import '../models/thingspeak_data.dart';
import '../widgets/device_card.dart';
import 'add_device_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.dashboard_customize, size: 24),
            const SizedBox(width: 8),
            const Text('IoT Dashboard'),
          ],
        ),
        elevation: 2,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<IoTDataProvider>(context, listen: false)
                  .refreshAllDeviceData();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Consumer<IoTDataProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.deviceData.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading IoT devices...'),
                  ],
                ),
              );
            }

            if (provider.error.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      provider.error, 
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      onPressed: () {
                        provider.clearError();
                        provider.refreshAllDeviceData();
                      },
                    ),
                  ],
                ),
              );
            }

            if (provider.devices.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.sensors_off, size: 64, color: Colors.blue),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No IoT devices connected',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add your first ThingSpeak device to monitor data',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Device'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddDeviceScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => provider.refreshAllDeviceData(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  
                  _buildDashboardHeader(context, provider),
                  const SizedBox(height: 16),
                  
                  
                  const Text(
                    'Your Devices',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  
                  ...provider.devices.map((device) => DeviceCard(
                    device: device,
                    deviceData: provider.deviceData[device.channelId] ?? [],
                    channelInfo: provider.channelInfo[device.channelId],
                  )).toList(),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddDeviceScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Device'),
      ),
    );
  }
  
  Widget _buildDashboardHeader(BuildContext context, IoTDataProvider provider) {
    final deviceCount = provider.devices.length;
    final totalReadings = provider.deviceData.values
        .fold(0, (total, feeds) => total + feeds.length);
    final lastUpdated = provider.deviceData.isEmpty
        ? 'Never'
        : _getLatestUpdateTime(provider);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.tertiary,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text(
              'IoT Dashboard Overview',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  context,
                  Icons.devices,
                  '$deviceCount',
                  'Devices',
                ),
                _buildStatCard(
                  context,
                  Icons.data_usage,
                  '$totalReadings',
                  'Readings',
                ),
                _buildStatCard(
                  context,
                  Icons.access_time,
                  lastUpdated,
                  'Last Update',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  String _getLatestUpdateTime(IoTDataProvider provider) {
    DateTime? latest;
    
    for (final feeds in provider.deviceData.values) {
      if (feeds.isNotEmpty) {
        final feedTime = DateTime.parse(feeds.first.createdAt);
        if (latest == null || feedTime.isAfter(latest)) {
          latest = feedTime;
        }
      }
    }
    
    if (latest == null) return 'Never';
    
    final now = DateTime.now();
    final difference = now.difference(latest);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
