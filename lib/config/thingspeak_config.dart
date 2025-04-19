class ThingSpeakConfig {

  static const String defaultChannelId = '2906008';
  static const String defaultReadApiKey = '';  
  

  static const String baseUrl = 'https://api.thingspeak.com';
  

  static const int defaultResultCount = 10;
  static const int defaultRefreshInterval = 15;
  
 
  static String getPublicChannelUrl(String channelId) {
    return '$baseUrl/channels/$channelId/feed.json';
  }
  
  static String getPublicFeedsUrl(String channelId, int results) {
    return '$baseUrl/channels/$channelId/feeds.json?results=$results';
  }
  
  static String getPublicFieldUrl(String channelId, int fieldNumber, int results) {
    return '$baseUrl/channels/$channelId/fields/$fieldNumber.json?results=$results';
  }
  

  static String getChannelUrl(String channelId, String apiKey) {

    if (apiKey.isEmpty) {
      return getPublicChannelUrl(channelId);
    }
    return '$baseUrl/channels/$channelId.json?api_key=$apiKey';
  }
  
  static String getFeedsUrl(String channelId, String apiKey, int results) {

    if (apiKey.isEmpty) {
      return getPublicFeedsUrl(channelId, results);
    }
    return '$baseUrl/channels/$channelId/feeds.json?api_key=$apiKey&results=$results';
  }
  
  static String getFieldUrl(String channelId, String apiKey, int fieldNumber, int results) {

    if (apiKey.isEmpty) {
      return getPublicFieldUrl(channelId, fieldNumber, results);
    }
    return '$baseUrl/channels/$channelId/fields/$fieldNumber.json?api_key=$apiKey&results=$results';
  }
  

  static bool isFullApiUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }
}