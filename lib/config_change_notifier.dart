import 'package:flutter/foundation.dart';

/// Global callback used to notify the configuration screen that a change
/// occurred outside of a typical [setState] call (e.g. via [ValueNotifier]).
VoidCallback? configurationChangeListener;

/// Notify the registered listener that configuration data changed.
void notifyConfigurationChanged() {
  final listener = configurationChangeListener;
  if (listener != null) {
    listener();
  }
}
