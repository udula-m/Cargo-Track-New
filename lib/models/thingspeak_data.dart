import 'package:flutter/foundation.dart';

class ThingSpeakChannel {
  final int id;
  final String name;
  final String description;
  final Map<String, String> fieldLabels;
  final String createdAt;
  final String updatedAt;
  final int lastEntryId;

  ThingSpeakChannel({
    required this.id,
    required this.name,
    required this.description,
    required this.fieldLabels,
    required this.createdAt,
    required this.updatedAt,
    required this.lastEntryId,
  });

  factory ThingSpeakChannel.fromJson(Map<String, dynamic> json) {
    try {
      
      Map<String, String> fields = {};
      for (int i = 1; i <= 8; i++) {
        String fieldKey = 'field$i';
        if (json[fieldKey] != null && json[fieldKey].toString().isNotEmpty) {
          fields[fieldKey] = json[fieldKey].toString();
        }
      }

      return ThingSpeakChannel(
        id: json['id'] ?? 0,
        name: json['name'] ?? 'Unnamed Channel',
        description: json['description'] ?? '',
        fieldLabels: fields,
        createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
        updatedAt: json['updated_at'] ?? DateTime.now().toIso8601String(),
        lastEntryId: json['last_entry_id'] ?? 0,
      );
    } catch (e) {
      debugPrint('Error parsing ThingSpeakChannel: $e');
      debugPrint('JSON data: $json');
      rethrow;
    }
  }

  // Get a more user-friendly label for the field if available
  String getDisplayLabel(String fieldKey) {
    if (!fieldLabels.containsKey(fieldKey)) {
      return fieldKey;
    }
    
    final label = fieldLabels[fieldKey]!;
    
    // If the label is already good, return it
    if (!label.startsWith('field')) {
      return label;
    }
    
    // Try to make a user-friendly label based on content
    final lowerLabel = label.toLowerCase();
    if (lowerLabel.contains('temp')) return 'Temperature';
    if (lowerLabel.contains('humid')) return 'Humidity';
    if (lowerLabel.contains('press')) return 'Pressure';
    if (lowerLabel.contains('light')) return 'Light';
    if (lowerLabel.contains('co2')) return 'CO2';
    if (lowerLabel.contains('motion')) return 'Motion';
    
    // Default fallback
    return label;
  }
}

class ThingSpeakFeed {
  final String createdAt;
  final int entryId;
  final Map<String, double> fieldValues;

  ThingSpeakFeed({
    required this.createdAt,
    required this.entryId,
    required this.fieldValues,
  });

  factory ThingSpeakFeed.fromJson(Map<String, dynamic> json) {
    try {
      Map<String, double> fields = {};
      
      debugPrint('Parsing feed: ${json['entry_id']}');
      
      for (int i = 1; i <= 8; i++) {
        String fieldKey = 'field$i';
        
        if (json[fieldKey] != null) {
          // Print raw field data for debugging
          debugPrint('Field $fieldKey raw value: ${json[fieldKey]} (${json[fieldKey].runtimeType})');
          
          // Handle different data types more robustly
          var rawValue = json[fieldKey];
          String valueStr;
          
          if (rawValue is int) {
            valueStr = rawValue.toString();
          } else if (rawValue is double) {
            valueStr = rawValue.toString();
          } else if (rawValue is bool) {
            valueStr = rawValue ? "1" : "0";
          } else {
            valueStr = rawValue.toString();
          }
          
          if (valueStr.isNotEmpty) {
            // Try parsing as double with more robust error handling
            double? parsedValue = double.tryParse(valueStr);
            if (parsedValue != null) {
              fields[fieldKey] = parsedValue;
              debugPrint('Successfully parsed $fieldKey: $parsedValue');
            } else {
              // If parsing fails, try to clean the string and try again
              valueStr = valueStr.replaceAll(RegExp(r'[^\d\.-]'), '');
              parsedValue = double.tryParse(valueStr);
              if (parsedValue != null) {
                fields[fieldKey] = parsedValue;
                debugPrint('Parsed after cleaning $fieldKey: $parsedValue');
              } else {
                debugPrint('Failed to parse $fieldKey: "$valueStr"');
              }
            }
          }
        }
      }

      debugPrint('Parsed ${fields.length} fields: ${fields.toString()}');
      
      return ThingSpeakFeed(
        createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
        entryId: json['entry_id'] is int ? json['entry_id'] : int.tryParse(json['entry_id'].toString()) ?? 0,
        fieldValues: fields,
      );
    } catch (e) {
      debugPrint('Error parsing ThingSpeakFeed: $e');
      debugPrint('JSON data: $json');
      // Return empty feed rather than rethrowing
      return ThingSpeakFeed(
        createdAt: DateTime.now().toIso8601String(),
        entryId: 0,
        fieldValues: {},
      );
    }
  }
}

class ThingSpeakDevice {
  final String channelId;
  final String readApiKey;
  final String writeApiKey;
  final String name;
  final String description;
  final String? directUrl; 

  ThingSpeakDevice({
    required this.channelId,
    required this.readApiKey,
    this.writeApiKey = '',
    required this.name,
    this.description = '',
    this.directUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'channelId': channelId,
      'readApiKey': readApiKey,
      'writeApiKey': writeApiKey,
      'name': name,
      'description': description,
      'directUrl': directUrl,
    };
  }

  factory ThingSpeakDevice.fromJson(Map<String, dynamic> json) {
    try {
      return ThingSpeakDevice(
        channelId: json['channelId'] ?? '',
        readApiKey: json['readApiKey'] ?? '',
        writeApiKey: json['writeApiKey'] ?? '',
        name: json['name'] ?? 'Unnamed Device',
        description: json['description'] ?? '',
        directUrl: json['directUrl'],
      );
    } catch (e) {
      debugPrint('Error parsing ThingSpeakDevice: $e');
      debugPrint('JSON data: $json');
      rethrow;
    }
  }
}
