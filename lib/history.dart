import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class ConfigHistoryController extends ChangeNotifier {
  ConfigHistoryController({this.maxEntries = 100});

  final int maxEntries;
  final List<String> _undoStack = <String>[];
  final List<String> _redoStack = <String>[];
  String? _current;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void initialize(String snapshot) {
    _current = snapshot;
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }

  void capture(String snapshot) {
    if (_current == snapshot) {
      return;
    }
    if (_current != null) {
      _undoStack.add(_current!);
      if (_undoStack.length > maxEntries) {
        _undoStack.removeAt(0);
      }
    }
    _current = snapshot;
    _redoStack.clear();
    notifyListeners();
  }

  String? undo() {
    if (!canUndo) {
      return null;
    }
    final previous = _undoStack.removeLast();
    if (_current != null) {
      _redoStack.add(_current!);
      if (_redoStack.length > maxEntries) {
        _redoStack.removeAt(0);
      }
    }
    _current = previous;
    notifyListeners();
    return _current;
  }

  String? redo() {
    if (!canRedo) {
      return null;
    }
    final next = _redoStack.removeLast();
    if (_current != null) {
      _undoStack.add(_current!);
      if (_undoStack.length > maxEntries) {
        _undoStack.removeAt(0);
      }
    }
    _current = next;
    notifyListeners();
    return _current;
  }

  void replaceCurrent(String snapshot) {
    _current = snapshot;
    notifyListeners();
  }
}

class HistoryBinding {
  static VoidCallback? _scheduleCapture;

  static void register(VoidCallback callback) {
    _scheduleCapture = callback;
  }

  static void unregister(VoidCallback callback) {
    if (_scheduleCapture == callback) {
      _scheduleCapture = null;
    }
  }

  static void requestCapture() {
    final callback = _scheduleCapture;
    if (callback != null) {
      callback();
    }
  }
}

mixin HistoryAwareState<T extends StatefulWidget> on State<T> {
  @protected
  void markHistoryCaptureNeeded() {
    HistoryBinding.requestCapture();
  }
}
