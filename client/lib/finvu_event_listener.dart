import 'finvu_event.dart';

/// Event listener interface for receiving SDK events
///
/// Events are delivered on the main isolate by default.
/// If you need a different isolate, switch inside onEvent().
abstract class FinvuEventListener {
  /// Called when an event occurs
  /// @param event The event object containing all event data
  void onEvent(FinvuEvent event);
}
