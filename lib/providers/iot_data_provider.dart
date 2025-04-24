import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/thingspeak_data.dart';
import '../services/thingspeak_service.dart';
import '../services/notification_service.dart';
import '../config/thingspeak_config.dart';

class IoTDataProvider with ChangeNotifier {
  final ThingSpeakService _service = ThingSpeakService();
  final NotificationService _notificationService = NotificationService();
  
  List<ThingSpeakDevice> _devices = [];
  Map<String, List<ThingSpeakFeed>> _deviceData = {};
  Map<String, ThingSpeakChannel> _channelInfo = {};
  
  bool _isLoading = false;
  String _error = '';
  Timer? _refreshTimer;
  int _refreshInterval = ThingSpeakConfig.defaultRefreshInterval;

  IoTDataProvider() {
    _initServices();
    _loadDevices();
    _startRefreshTimer();
  }

  Future<void> _initServices() async {
    await _notificationService.init();
  }

  List<ThingSpeakDevice> get devices => _devices;
  Map<String, List<ThingSpeakFeed>> get deviceData => _deviceData;
  Map<String, ThingSpeakChannel> get channelInfo => _channelInfo;
  bool get isLoading => _isLoading;
  String get error => _error;
  int get refreshInterval => _refreshInterval;

  Future<void> _loadDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceJsonList = prefs.getStringList('devices') ?? [];
      
      _devices = deviceJsonList.map((jsonString) {
        try {
          return ThingSpeakDevice.fromJson(
            json.decode(jsonString) as Map<String, dynamic>
          );
        } catch (e) {
          debugPrint('Error parsing device JSON: $e');
          return null;
        }
      })
      .where((device) => device != null)
      .cast<ThingSpeakDevice>()
      .toList();
      
      if (_devices.isNotEmpty) {
        await refreshAllDeviceData();
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load devices: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  Future<void> saveDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceJsonList = _devices.map((device) {
        try {
          return json.encode(device.toJson());
        } catch (e) {
          debugPrint('Error encoding device: $e');
          return null;
        }
      })
      .where((jsonString) => jsonString != null)
      .cast<String>()
      .toList();
      
      await prefs.setStringList('devices', deviceJsonList);
    } catch (e) {
      _error = 'Failed to save devices: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  void addDevice(ThingSpeakDevice device) {
   
    if (_devices.any((d) => d.channelId == device.channelId)) {
      _error = 'Device with this Channel ID already exists';
      notifyListeners();
      return;
    }

    _devices.add(device);
    saveDevices();
    refreshDeviceData(device.channelId, device.readApiKey, directUrl: device.directUrl);
    notifyListeners();
  }

  void removeDevice(ThingSpeakDevice device) {
    try {
      _devices.removeWhere((d) => d.channelId == device.channelId);
      _deviceData.remove(device.channelId);
      _channelInfo.remove(device.channelId);
      saveDevices();
      notifyListeners();
    } catch (e) {
      _error = 'Error removing device: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  Future<void> refreshDeviceData(String channelId, String apiKey, {String? directUrl}) async {
    if ((channelId.isEmpty || apiKey.isEmpty) && (directUrl == null || directUrl.isEmpty)) {
      _error = 'Invalid channel ID, API key, or URL';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      channelId = channelId.trim();
      apiKey = apiKey.trim().replaceAll(' ', ''); 
      if (directUrl != null) {
        directUrl = directUrl.trim();
      }
      
      debugPrint('Refreshing data for channel: $channelId' + 
        (directUrl != null ? ' with direct URL: $directUrl' : ''));
      
      // First get or update channel info
      try {
        final channelInfo = await _service.getChannelInfo(channelId, apiKey, directUrl: directUrl);
        _channelInfo[channelId] = channelInfo;
        debugPrint('Got channel info for $channelId with ${channelInfo.fieldLabels.length} fields');
      } catch (e) {
        debugPrint('Error getting channel info: $e');
        // Continue anyway as we might already have channel info cached
      }
      
      // Get the latest data
      final latestData = await _service.getLatestData(channelId, apiKey, directUrl: directUrl);
      
      // Debug the data we received
      debugPrint('Got ${latestData.length} data points for channel $channelId');
      if (latestData.isNotEmpty) {
        debugPrint('First data point has ${latestData.first.fieldValues.length} fields');
        latestData.first.fieldValues.forEach((key, value) {
          debugPrint('  $key: $value');
        });
        
        // Check for notifications on new data
        final device = _devices.firstWhere(
          (d) => d.channelId == channelId,
          orElse: () => ThingSpeakDevice(
            channelId: channelId,
            readApiKey: apiKey,
            name: 'Unknown Device',
          ),
        );
        
        // Process notifications for the latest data point
        await _processNotifications(device, latestData.first, _channelInfo[channelId]);
      }
      
      _deviceData[channelId] = latestData;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      
      // Format error message
      if (e.toString().contains('API Error')) {
        _error = e.toString().replaceAll('Exception: ', '');
      } else if (e.toString().contains('Bad Request')) {
        _error = 'Invalid request. Please check your Channel ID and API Key.';
      } else if (e.toString().contains('Channel not found')) {
        _error = 'Channel not found. Please check your Channel ID.';
      } else if (e.toString().contains('Access denied')) {
        _error = 'Access denied. Please check your API Key.';
      } else if (e.toString().contains('No internet connection')) {
        _error = 'No internet connection. Please check your network.';
      } else if (e.toString().contains('timeout')) {
        _error = 'Connection timeout. ThingSpeak server is not responding.';
      } else {
        _error = 'Failed to refresh data: $e';
      }
      
      debugPrint('Error refreshing device $channelId: $e');
      notifyListeners();
    }
  }

  // Process notifications for new data
  Future<void> _processNotifications(
    ThingSpeakDevice device, 
    ThingSpeakFeed feed,
    ThingSpeakChannel? channelInfo,
  ) async {
    try {
      await _notificationService.checkAndNotify(device, feed, channelInfo);
    } catch (e) {
      debugPrint('Error processing notifications: $e');
    }
  }

  Future<void> refreshAllDeviceData() async {
    if (_devices.isEmpty) return;
    
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    bool hasError = false;
    
    for (var device in _devices) {
      try {
        await refreshDeviceData(
          device.channelId, 
          device.readApiKey, 
          directUrl: device.directUrl
        );
      } catch (e) {
        hasError = true;
        debugPrint('Error refreshing device ${device.name}: $e');
      }
    }
    
    _isLoading = false;
    if (hasError && _error.isEmpty) {
      _error = 'Some devices failed to refresh';
    }
    notifyListeners();
  }

  void setRefreshInterval(int seconds) {
    if (seconds < 5) seconds = 5; 
    if (seconds > 3600) seconds = 3600; 
    
    _refreshInterval = seconds;
    _restartRefreshTimer();
    notifyListeners();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(Duration(seconds: _refreshInterval), (timer) {
      refreshAllDeviceData();
    });
  }

  void _restartRefreshTimer() {
    _refreshTimer?.cancel();
    _startRefreshTimer();
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
