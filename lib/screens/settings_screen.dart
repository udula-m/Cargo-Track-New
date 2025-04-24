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
  
  bool _notificationsEnabled = false;
  bool _temperatureNotificationsEnabled = false;
  double _temperatureThresholdMin = 0.0;
  double _temperatureThresholdMax = 30.0;
  bool _humidityNotificationsEnabled = false;
  double _humidityThresholdMin = 30.0;
  double _humidityThresholdMax = 70.0;
  bool _lightLevelNotificationsEnabled = false;
  double _lightLevelThreshold = 500.0;
  bool _vibrationNotificationsEnabled = false;
  double _vibrationThreshold = 2.0;
  bool _pressureNotificationsEnabled = false;
  double _pressureThresholdMin = 900.0;
  double _pressureThresholdMax = 1100.0;

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
        
        _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;
        _temperatureNotificationsEnabled = prefs.getBool('temperatureNotificationsEnabled') ?? false;
        _temperatureThresholdMin = prefs.getDouble('temperatureThresholdMin') ?? 0.0;
        _temperatureThresholdMax = prefs.getDouble('temperatureThresholdMax') ?? 30.0;
        _humidityNotificationsEnabled = prefs.getBool('humidityNotificationsEnabled') ?? false;
        _humidityThresholdMin = prefs.getDouble('humidityThresholdMin') ?? 30.0;
        _humidityThresholdMax = prefs.getDouble('humidityThresholdMax') ?? 70.0;
        _lightLevelNotificationsEnabled = prefs.getBool('lightLevelNotificationsEnabled') ?? false;
        _lightLevelThreshold = prefs.getDouble('lightLevelThreshold') ?? 500.0;
        _vibrationNotificationsEnabled = prefs.getBool('vibrationNotificationsEnabled') ?? false;
        _vibrationThreshold = prefs.getDouble('vibrationThreshold') ?? 2.0;
        _pressureNotificationsEnabled = prefs.getBool('pressureNotificationsEnabled') ?? false;
        _pressureThresholdMin = prefs.getDouble('pressureThresholdMin') ?? 900.0;
        _pressureThresholdMax = prefs.getDouble('pressureThresholdMax') ?? 1100.0;
        
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
      
      await prefs.setBool('notificationsEnabled', _notificationsEnabled);
      await prefs.setBool('temperatureNotificationsEnabled', _temperatureNotificationsEnabled);
      await prefs.setDouble('temperatureThresholdMin', _temperatureThresholdMin);
      await prefs.setDouble('temperatureThresholdMax', _temperatureThresholdMax);
      await prefs.setBool('humidityNotificationsEnabled', _humidityNotificationsEnabled);
      await prefs.setDouble('humidityThresholdMin', _humidityThresholdMin);
      await prefs.setDouble('humidityThresholdMax', _humidityThresholdMax);
      await prefs.setBool('lightLevelNotificationsEnabled', _lightLevelNotificationsEnabled);
      await prefs.setDouble('lightLevelThreshold', _lightLevelThreshold);
      await prefs.setBool('vibrationNotificationsEnabled', _vibrationNotificationsEnabled);
      await prefs.setDouble('vibrationThreshold', _vibrationThreshold);
      await prefs.setBool('pressureNotificationsEnabled', _pressureNotificationsEnabled);
      await prefs.setDouble('pressureThresholdMin', _pressureThresholdMin);
      await prefs.setDouble('pressureThresholdMax', _pressureThresholdMax);
      
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
          
          _buildSectionHeader('Notification Settings'),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Turn on/off all cargo tracking notifications'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
                _saveSettings();
              });
            },
          ),
          
          if (_notificationsEnabled) ...[
            SwitchListTile(
              title: const Text('Temperature Alerts'),
              subtitle: const Text('Get notified when temperature is out of range'),
              value: _temperatureNotificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _temperatureNotificationsEnabled = value;
                  _saveSettings();
                });
              },
            ),
            if (_temperatureNotificationsEnabled)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Temperature Range (°C):', 
                      style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Min: ${_temperatureThresholdMin.toStringAsFixed(1)}°C'),
                        Text('Max: ${_temperatureThresholdMax.toStringAsFixed(1)}°C'),
                      ],
                    ),
                    RangeSlider(
                      values: RangeValues(_temperatureThresholdMin, _temperatureThresholdMax),
                      min: -20.0,
                      max: 50.0,
                      divisions: 70,
                      labels: RangeLabels(
                        '${_temperatureThresholdMin.toStringAsFixed(1)}°C',
                        '${_temperatureThresholdMax.toStringAsFixed(1)}°C',
                      ),
                      onChanged: (RangeValues values) {
                        setState(() {
                          _temperatureThresholdMin = values.start;
                          _temperatureThresholdMax = values.end;
                          _saveSettings();
                        });
                      },
                    ),
                  ],
                ),
              ),
              
            SwitchListTile(
              title: const Text('Humidity Alerts'),
              subtitle: const Text('Get notified when humidity is out of range'),
              value: _humidityNotificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _humidityNotificationsEnabled = value;
                  _saveSettings();
                });
              },
            ),
            if (_humidityNotificationsEnabled)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Humidity Range (%):', 
                      style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Min: ${_humidityThresholdMin.toStringAsFixed(1)}%'),
                        Text('Max: ${_humidityThresholdMax.toStringAsFixed(1)}%'),
                      ],
                    ),
                    RangeSlider(
                      values: RangeValues(_humidityThresholdMin, _humidityThresholdMax),
                      min: 0.0,
                      max: 100.0,
                      divisions: 100,
                      labels: RangeLabels(
                        '${_humidityThresholdMin.toStringAsFixed(1)}%',
                        '${_humidityThresholdMax.toStringAsFixed(1)}%',
                      ),
                      onChanged: (RangeValues values) {
                        setState(() {
                          _humidityThresholdMin = values.start;
                          _humidityThresholdMax = values.end;
                          _saveSettings();
                        });
                      },
                    ),
                  ],
                ),
              ),
              
            SwitchListTile(
              title: const Text('Light Level Alerts'),
              subtitle: const Text('Get notified when light level exceeds threshold'),
              value: _lightLevelNotificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _lightLevelNotificationsEnabled = value;
                  _saveSettings();
                });
              },
            ),
            if (_lightLevelNotificationsEnabled)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Light Level Threshold (lux): ${_lightLevelThreshold.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                    Slider(
                      value: _lightLevelThreshold,
                      min: 0.0,
                      max: 1000.0,
                      divisions: 20,
                      label: '${_lightLevelThreshold.toStringAsFixed(0)} lux',
                      onChanged: (double value) {
                        setState(() {
                          _lightLevelThreshold = value;
                          _saveSettings();
                        });
                      },
                    ),
                  ],
                ),
              ),

            SwitchListTile(
              title: const Text('Vibration Alerts'),
              subtitle: const Text('Get notified when vibration exceeds threshold'),
              value: _vibrationNotificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _vibrationNotificationsEnabled = value;
                  _saveSettings();
                });
              },
            ),
            if (_vibrationNotificationsEnabled)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vibration Threshold (g): ${_vibrationThreshold.toStringAsFixed(1)}',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                    Slider(
                      value: _vibrationThreshold,
                      min: 0.1,
                      max: 10.0,
                      divisions: 99,
                      label: '${_vibrationThreshold.toStringAsFixed(1)} g',
                      onChanged: (double value) {
                        setState(() {
                          _vibrationThreshold = value;
                          _saveSettings();
                        });
                      },
                    ),
                  ],
                ),
              ),

            SwitchListTile(
              title: const Text('Pressure Alerts'),
              subtitle: const Text('Get notified when pressure is out of range'),
              value: _pressureNotificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _pressureNotificationsEnabled = value;
                  _saveSettings();
                });
              },
            ),
            if (_pressureNotificationsEnabled)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pressure Range (hPa):', 
                      style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Min: ${_pressureThresholdMin.toStringAsFixed(1)} hPa'),
                        Text('Max: ${_pressureThresholdMax.toStringAsFixed(1)} hPa'),
                      ],
                    ),
                    RangeSlider(
                      values: RangeValues(_pressureThresholdMin, _pressureThresholdMax),
                      min: 800.0,
                      max: 1200.0,
                      divisions: 80,
                      labels: RangeLabels(
                        '${_pressureThresholdMin.toStringAsFixed(1)} hPa',
                        '${_pressureThresholdMax.toStringAsFixed(1)} hPa',
                      ),
                      onChanged: (RangeValues values) {
                        setState(() {
                          _pressureThresholdMin = values.start;
                          _pressureThresholdMax = values.end;
                          _saveSettings();
                        });
                      },
                    ),
                  ],
                ),
              ),
          ],
          
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
