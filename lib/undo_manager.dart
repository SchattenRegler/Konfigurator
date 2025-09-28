class UndoRedoManager {
  final List<String> _history = <String>[];
  int _currentIndex = -1;
  bool _isApplying = false;

  bool get isApplying => _isApplying;

  set isApplying(bool value) => _isApplying = value;

  bool get canUndo => _currentIndex > 0;
  bool get canRedo => _currentIndex >= 0 && _currentIndex < _history.length - 1;
  bool get hasEntries => _history.isNotEmpty;

  void clear() {
    _history.clear();
    _currentIndex = -1;
  }

  void initialize(String initialState) {
    clear();
    _history.add(initialState);
    _currentIndex = 0;
  }

  void capture(String state) {
    if (_isApplying) return;
    if (_history.isNotEmpty && _history[_currentIndex] == state) {
      return;
    }
    if (_currentIndex < _history.length - 1) {
      _history.removeRange(_currentIndex + 1, _history.length);
    }
    _history.add(state);
    _currentIndex = _history.length - 1;
  }

  String? undo() {
    if (!canUndo) return null;
    _currentIndex -= 1;
    return _history[_currentIndex];
  }

  String? redo() {
    if (!canRedo) return null;
    _currentIndex += 1;
    return _history[_currentIndex];
  }
}
