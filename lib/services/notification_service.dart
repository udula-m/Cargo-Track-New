import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/thingspeak_data.dart';
import 'dart:io' show Platform;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() {
    return _instance;
  }
  
  NotificationService._internal();
  
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;
  int _notificationId = 0; // To generate unique IDs for notifications
  
  // Cached threshold values
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
  
  // Last alert time to avoid notification spam
  final Map<String, DateTime> _lastAlertTime = {};
  final Duration _alertCooldown = const Duration(minutes: 15);
  
  Future<void> init() async {
    if (_initialized) return;
    
    // Setup notification channel for Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    // Setup notification settings for iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    // Initialize the plugin
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
        // Handle notification tap here
      },
    );
    
    // Request permission for Android 13+
    if (Platform.isAndroid) {
      try {
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
            flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
                
        if (androidPlugin != null) {
          await androidPlugin.requestNotificationsPermission();
        }
      } catch (e) {
        debugPrint('Error requesting Android notification permissions: $e');
      }
    }
    
    // Load notification thresholds from preferences
    await loadThresholdSettings();
    
    _initialized = true;
    debugPrint('Notification service initialized successfully');
  }
  
  Future<void> loadThresholdSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
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
      
      debugPrint('Notification settings loaded: enabled=$_notificationsEnabled');
    } catch (e) {
      debugPrint('Error loading notification thresholds: $e');
    }
  }
  
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await init();
    
    try {
      // Get a unique notification ID
      final int notificationId = _getUniqueNotificationId();
      
      // Configure Android notification details
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'cargo_track_channel',
        'Cargo Tracking',
        channelDescription: 'Notifications for cargo tracking alerts',
        importance: Importance.high,
        priority: Priority.high,
        enableLights: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );
      
      // Configure iOS notification details
      const DarwinNotificationDetails iosNotificationDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );
      
      // Show the notification
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      
      debugPrint('Notification sent: $title');
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }
  
  // Generate a unique notification ID
  int _getUniqueNotificationId() {
    // Increment and return, wrapping around at 32-bit int max
    _notificationId = (_notificationId + 1) % 2147483647;
    return _notificationId;
  }
  
  // Check data values and send notifications if thresholds are crossed
  Future<void> checkAndNotify(
    ThingSpeakDevice device,
    ThingSpeakFeed feed,
    ThingSpeakChannel? channelInfo,
  ) async {
    if (!_initialized) await init();
    if (!_notificationsEnabled) return;
    
    try {
      // Reload settings to ensure we have latest threshold values
      await loadThresholdSettings();
      
      // Check each sensor type
      for (var fieldEntry in feed.fieldValues.entries) {
        final String fieldKey = fieldEntry.key;
        final double value = fieldEntry.value;
        
        String? fieldLabel = channelInfo?.getDisplayLabel(fieldKey).toLowerCase();
        
        // Check temperature thresholds
        if (_temperatureNotificationsEnabled && 
            (fieldLabel?.contains('temp') ?? false || 
            fieldKey.toLowerCase().contains('temp'))) {
          if (value < _temperatureThresholdMin || value > _temperatureThresholdMax) {
            await _sendAlertIfNotCoolingDown(
              device.name,
              'temperature',
              'Temperature Alert: ${value.toStringAsFixed(1)}°C',
              'Temperature out of range (${_temperatureThresholdMin.toStringAsFixed(1)}°C - ${_temperatureThresholdMax.toStringAsFixed(1)}°C)',
            );
          }
        }
        
        // Check humidity thresholds
        if (_humidityNotificationsEnabled && 
            (fieldLabel?.contains('humid') ?? false || 
            fieldKey.toLowerCase().contains('humid'))) {
          if (value < _humidityThresholdMin || value > _humidityThresholdMax) {
            await _sendAlertIfNotCoolingDown(
              device.name,
              'humidity',
              'Humidity Alert: ${value.toStringAsFixed(1)}%',
              'Humidity out of range (${_humidityThresholdMin.toStringAsFixed(1)}% - ${_humidityThresholdMax.toStringAsFixed(1)}%)',
            );
          }
        }
        
        // Check light level threshold
        if (_lightLevelNotificationsEnabled && 
            (fieldLabel?.contains('light') ?? false || 
            fieldKey.toLowerCase().contains('light'))) {
          if (value > _lightLevelThreshold) {
            await _sendAlertIfNotCoolingDown(
              device.name,
              'light',
              'Light Level Alert: ${value.toStringAsFixed(1)} lux',
              'Light level exceeded threshold (${_lightLevelThreshold.toStringAsFixed(1)} lux)',
            );
          }
        }
        
        // Check vibration threshold
        if (_vibrationNotificationsEnabled && 
            ((fieldLabel != null && fieldLabel.contains('vibration')) || 
             (fieldLabel != null && fieldLabel.contains('accel')) ||
             fieldKey.toLowerCase().contains('vibration') || 
             fieldKey.toLowerCase().contains('accel'))) {
          if (value > _vibrationThreshold) {
            await _sendAlertIfNotCoolingDown(
              device.name,
              'vibration',
              'Vibration Alert: ${value.toStringAsFixed(1)} g',
              'Vibration exceeded threshold (${_vibrationThreshold.toStringAsFixed(1)} g)',
            );
          }
        }
        
        // Check pressure thresholds
        if (_pressureNotificationsEnabled && 
            (fieldLabel?.contains('pressure') ?? false || 
            fieldKey.toLowerCase().contains('press'))) {
          if (value < _pressureThresholdMin || value > _pressureThresholdMax) {
            await _sendAlertIfNotCoolingDown(
              device.name,
              'pressure',
              'Pressure Alert: ${value.toStringAsFixed(1)} hPa',
              'Pressure out of range (${_pressureThresholdMin.toStringAsFixed(1)} hPa - ${_pressureThresholdMax.toStringAsFixed(1)} hPa)',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking notifications: $e');
    }
  }
  
  // Fixed: Changed from void to Future<void> as this method uses await
  Future<void> _sendAlertIfNotCoolingDown(
    String deviceName,
    String alertType,
    String title,
    String message,
  ) async {
    final String alertKey = '$deviceName-$alertType';
    final now = DateTime.now();
    
    // Check if we've sent an alert recently for this device and type
    if (_lastAlertTime.containsKey(alertKey)) {
      final lastAlert = _lastAlertTime[alertKey]!;
      if (now.difference(lastAlert) < _alertCooldown) {
        // Still in cooldown period, don't send another notification
        debugPrint('Alert for $alertKey is in cooldown, skipping notification');
        return;
      }
    }
    
    // Update the last alert time
    _lastAlertTime[alertKey] = now;
    
    // Send the notification
    await showNotification(
      title: '$deviceName - $title',
      body: message,
      payload: alertKey,
    );
  }
}