/// Event definition for custom events
///
/// Used to define custom events that can be tracked.
/// Custom events follow the same structure as standard events.
class FinvuEventDefinition {
  /// Event category (e.g., "ui", "api", "websocket")
  final String category;

  /// Optional stage identifier
  final String? stage;

  /// Optional FIP ID
  final String? fipId;

  /// Optional list of FIP IDs
  final List<String>? fips;

  /// Optional list of FI types
  final List<String>? fiTypes;

  FinvuEventDefinition({
    required this.category,
    this.stage,
    this.fipId,
    this.fips,
    this.fiTypes,
  });

  @override
  String toString() {
    return 'FinvuEventDefinition(category: $category, stage: $stage, fipId: $fipId, fips: $fips, fiTypes: $fiTypes)';
  }
}
