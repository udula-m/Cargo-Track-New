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
      for (int i = 1; i <= 8; i++) {
        String fieldKey = 'field$i';
        if (json[fieldKey] != null) {
         
          String valueStr = json[fieldKey].toString();
          if (valueStr.isNotEmpty) {
            fields[fieldKey] = double.tryParse(valueStr) ?? 0.0;
          }
        }
      }

      return ThingSpeakFeed(
        createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
        entryId: json['entry_id'] ?? 0,
        fieldValues: fields,
      );
    } catch (e) {
      debugPrint('Error parsing ThingSpeakFeed: $e');
      debugPrint('JSON data: $json');
      rethrow;
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
