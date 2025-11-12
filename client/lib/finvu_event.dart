/// Event data class - immutable for thread safety
class FinvuEvent {
  final String eventName;
  final String eventCategory;
  final String timestamp;
  final String aaSdkVersion;
  final Map<String, dynamic> params;

  FinvuEvent({
    required this.eventName,
    required this.eventCategory,
    required this.timestamp,
    required this.aaSdkVersion,
    Map<String, dynamic>? params,
  }) : params = params ?? {};

  /// Helper to get param value with type safety
  T? getParam<T>(String key) {
    final value = params[key];
    return value is T ? value : null;
  }

  @override
  String toString() {
    return 'FinvuEvent(eventName: $eventName, category: $eventCategory, timestamp: $timestamp, params: $params)';
  }
}
