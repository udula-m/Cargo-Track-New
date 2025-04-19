import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/iot_data_provider.dart';
import '../services/thingspeak_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  int _refreshInterval = 15;
  bool _isLoading = false;
  String _testResult = '';
  bool _showingTestResult = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isDarkMode = prefs.getBool('darkMode') ?? false;
        _refreshInterval = Provider.of<IoTDataProvider>(context, listen: false).refreshInterval;
        _isLoading = false;
      });
    } catch (e) {
      
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('darkMode', _isDarkMode);
      
    } catch (e) {
      
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && !_showingTestResult) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('App Settings'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Switch between light and dark theme'),
            value: _isDarkMode,
            onChanged: (value) {
              setState(() {
                _isDarkMode = value;
                _saveSettings();
              });
             
            },
          ),
          _buildDivider(),
          
          _buildSectionHeader('Data Settings'),
          ListTile(
            title: const Text('Refresh Interval'),
            subtitle: Text('$_refreshInterval seconds'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showRefreshIntervalDialog();
            },
          ),
          
          _buildDivider(),
          
          _buildSectionHeader('About'),
          ListTile(
            title: const Text('App Version'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            title: const Text('ThingSpeak API'),
            subtitle: const Text('Learn more about ThingSpeak'),
            onTap: () {
          
            },
          ),
          
          _buildDivider(),
          
          _buildSectionHeader('Debug Options'),
          ListTile(
            title: const Text('Test ThingSpeak API'),
            subtitle: const Text('Verify API connection'),
            trailing: const Icon(Icons.api),
            onTap: _testThingSpeakApi,
          ),
          
          if (_showingTestResult) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _testResult.isEmpty ? 'Testing API...' : 'API Test Result:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_testResult.isEmpty)
                    const CircularProgressIndicator()
                  else
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _testResult.contains('Error') 
                            ? Colors.red.withOpacity(0.1) 
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_testResult),
                    ),
                ],
              ),
            ),
          ],
          
          _buildDivider(),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlinedButton(
              onPressed: () {
                _showClearDataDialog();
              },
              child: const Text('Clear All Data'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(indent: 16, endIndent: 16);
  }

  void _showRefreshIntervalDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int selectedInterval = _refreshInterval;
        
        return AlertDialog(
          title: const Text('Refresh Interval'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select how often to refresh IoT data:'),
                  Slider(
                    value: selectedInterval.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 11,
                    label: '$selectedInterval seconds',
                    onChanged: (double value) {
                      setState(() {
                        selectedInterval = value.round();
                      });
                    },
                  ),
                  Text('$selectedInterval seconds'),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _refreshInterval = selectedInterval;
                });
                Provider.of<IoTDataProvider>(context, listen: false)
                    .setRefreshInterval(selectedInterval);
                _saveSettings();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Data'),
          content: const Text(
            'Are you sure you want to clear all device data? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final provider = Provider.of<IoTDataProvider>(context, listen: false);
                  
                  for (var device in provider.devices.toList()) {
                    provider.removeDevice(device);
                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All data cleared')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error clearing data: $e')),
                  );
                }
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _testThingSpeakApi() async {
    setState(() {
      _showingTestResult = true;
      _testResult = '';
      _isLoading = true;
    });

    try {
      final service = ThingSpeakService();
      final result = await service.testApiConnection();
      
      setState(() {
        _isLoading = false;
        _testResult = 'Success!\n\nChannel: ${result['channel']['name']}\nEntries: ${result['feeds'].length}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _testResult = 'Error: $e';
      });
    }
  }
}
