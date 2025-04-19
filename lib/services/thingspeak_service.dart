import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/thingspeak_data.dart';
import '../config/thingspeak_config.dart';

class ThingSpeakService {
  
  Future<Map<String, dynamic>> testApiConnection() async {
    try {
      
      final url = ThingSpeakConfig.getFeedsUrl(
        ThingSpeakConfig.defaultChannelId, 
        ThingSpeakConfig.defaultReadApiKey, 
        2
      );
      
      debugPrint('Testing API with URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 15));

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('API Test Error: $e');
      throw Exception('API Test Failed: $e');
    }
  }

 
  Future<Map<String, dynamic>> getDataFromDirectUrl(String url) async {
    try {
      debugPrint('Fetching data from direct URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 15));

      debugPrint('Response status code: ${response.statusCode}');
      
      if (response.body.length > 200) {
        debugPrint('Response preview: ${response.body.substring(0, 200)}...');
      } else {
        debugPrint('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 400) {
        
        try {
          final errorData = json.decode(response.body);
          if (errorData.containsKey('error') && errorData['error'] is Map) {
            final errorMsg = errorData['error']['message'] ?? 'Bad Request';
            final details = errorData['error']['details'] ?? '';
            throw Exception('API Error: $errorMsg - $details');
          } else {
            throw Exception('Bad Request: Invalid URL or parameters');
          }
        } catch (e) {
          if (e is FormatException) {
            throw Exception('Bad Request: Invalid URL or parameters');
          }
          rethrow;
        }
      } else if (response.statusCode == 404) {
        throw Exception('URL not found. Please check your API URL.');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Access denied. Please check your API URL and keys.');
      } else {
        throw Exception('Server error: ${response.statusCode}. Try again later.');
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your network and try again.');
    } on FormatException {
      throw Exception('Error parsing response. The API response format has changed.');
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on TimeoutException {
      throw Exception('Request timeout. ThingSpeak server is not responding.');
    } catch (e) {
      debugPrint('Error getting data from direct URL: $e');
      rethrow;
    }
  }

  
  Future<ThingSpeakChannel> getChannelInfo(String channelId, String apiKey, {String? directUrl}) async {
    try {
     
      if (directUrl != null && directUrl.isNotEmpty) {
        final data = await getDataFromDirectUrl(directUrl);
        if (data.containsKey('channel')) {
          return ThingSpeakChannel.fromJson(data['channel']);
        } else {
          throw Exception('Invalid response format, missing "channel" key');
        }
      }

      
      final cleanChannelId = channelId.trim();
      final cleanApiKey = apiKey.trim();
      
      debugPrint('Fetching channel info for channel: $cleanChannelId with API key: $cleanApiKey');
      
      
      final url = ThingSpeakConfig.getChannelUrl(cleanChannelId, cleanApiKey);
      debugPrint('Request URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 15));

      debugPrint('Response status code: ${response.statusCode}');
      
      
      if (response.body.length > 200) {
        debugPrint('Response preview: ${response.body.substring(0, 200)}...');
      } else {
        debugPrint('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data.containsKey('channel')) {
          return ThingSpeakChannel.fromJson(data['channel']);
        } else {
          throw Exception('Invalid response format, missing "channel" key');
        }
      } else if (response.statusCode == 400) {
        
        try {
          final errorData = json.decode(response.body);
          if (errorData.containsKey('error') && errorData['error'] is Map) {
            final errorMsg = errorData['error']['message'] ?? 'Bad Request';
            final details = errorData['error']['details'] ?? '';
            throw Exception('API Error: $errorMsg - $details');
          } else {
            throw Exception('Bad Request: Check your Channel ID and API Key');
          }
        } catch (e) {
          if (e is FormatException) {
            throw Exception('Bad Request: Check your Channel ID and API Key');
          }
          rethrow;
        }
      } else if (response.statusCode == 404) {
        throw Exception('Channel not found. Please check your Channel ID.');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Access denied. Please check your API Key.');
      } else {
        throw Exception('Server error: ${response.statusCode}. Try again later.');
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your network and try again.');
    } on FormatException {
      throw Exception('Error parsing response. The API response format has changed.');
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on TimeoutException {
      throw Exception('Request timeout. ThingSpeak server is not responding.');
    } catch (e) {
      debugPrint('Error getting channel info: $e');
      rethrow; 
    }
  }

  
  Future<List<ThingSpeakFeed>> getLatestData(String channelId, String apiKey, {int results = ThingSpeakConfig.defaultResultCount, String? directUrl}) async {
    try {
      
      if (directUrl != null && directUrl.isNotEmpty) {
        final data = await getDataFromDirectUrl(directUrl);
        if (data.containsKey('feeds')) {
          List<dynamic> feeds = data['feeds'];
          return feeds.map((feed) => ThingSpeakFeed.fromJson(feed)).toList();
        } else {
          throw Exception('Invalid response format, missing "feeds" key');
        }
      }

      final cleanChannelId = channelId.trim();
      final cleanApiKey = apiKey.trim();
      
      
      final url = ThingSpeakConfig.getFeedsUrl(cleanChannelId, cleanApiKey, results);
      debugPrint('Request URL for data: $url');
      
      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 15));

      debugPrint('Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (!data.containsKey('feeds')) {
          throw Exception('Invalid response format, missing "feeds" key');
        }
        
        List<dynamic> feeds = data['feeds'];
        return feeds.map((feed) => ThingSpeakFeed.fromJson(feed)).toList();
      } else if (response.statusCode == 400) {
        try {
          final errorData = json.decode(response.body);
          if (errorData.containsKey('error')) {
            final errorMsg = errorData['error']['message'] ?? 'Bad Request';
            throw Exception('API Error: $errorMsg');
          } else {
            throw Exception('Bad Request: Check your Channel ID and API Key');
          }
        } catch (e) {
          if (e is FormatException) {
            throw Exception('Bad Request: Check your Channel ID and API Key');
          }
          rethrow;
        }
      } else {
        throw Exception('Failed to load feeds: ${response.statusCode}');
      }
    } on Exception catch (e) {
      debugPrint('Error getting latest data: $e');
      rethrow;
    }
  }

  
  Future<List<ThingSpeakFeed>> getFieldData(String channelId, String apiKey, int fieldNumber, {int results = 10}) async {
    try {
      final cleanChannelId = channelId.trim();
      final cleanApiKey = apiKey.trim();
      
      
      final url = ThingSpeakConfig.getFieldUrl(cleanChannelId, cleanApiKey, fieldNumber, results);
      debugPrint('Request URL for field: $url');
      
      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (!data.containsKey('feeds')) {
          throw Exception('Invalid response format, missing "feeds" key');
        }
        
        List<dynamic> feeds = data['feeds'];
        return feeds.map((feed) => ThingSpeakFeed.fromJson(feed)).toList();
      } else {
        throw Exception('Failed to load field data: ${response.statusCode}');
      }
    } on Exception catch (e) {
      debugPrint('Error getting field data: $e');
      throw Exception('Failed to load field data: $e');
    }
  }

  
  Future<bool> updateField(String channelId, String apiKey, int fieldNumber, dynamic value) async {
    try {
      final response = await http.post(
        Uri.parse('${ThingSpeakConfig.baseUrl}/update'),
        body: {
          'api_key': apiKey,
          'field$fieldNumber': value.toString(),
        },
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } on Exception catch (e) {
      debugPrint('Error updating field: $e');
      return false;
    }
  }
  
  int min(int a, int b) {
    return a < b ? a : b;
  }
}
