import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

enum AppNavigationMode { mouse, keyboard }
enum Direction { up, down, left, right }

class NavigationService with ChangeNotifier {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  String? _currentHoveredId;
  String? get currentHoveredId => _currentHoveredId;

  String? _currentFocusedId;
  String? get currentFocusedId => _currentFocusedId;

  AppNavigationMode _mode = AppNavigationMode.mouse;
  AppNavigationMode get mode => _mode;

  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, bool> _ownsFocusNode = {};

  final Map<String, VoidCallback> _onEnterCallbacks = {};
  final Map<String, VoidCallback> _onActivateCallbacks = {};
  final Map<String, Map<Direction, String>> _directionOverrides = {};

  // ordered list for keyboard traversal
  final List<String> _focusOrder = [];
  List<String> get orderedIds => List.unmodifiable(_focusOrder);

  DateTime _lastKeyboardInteraction = DateTime.now();

  // stack to manage modal dialogs
  final List<_NavigationSnapshot> _navigationStack = [];

  // ---------------------
  // Widget registration
  // ---------------------
  void registerWidget({
    required String id,
    FocusNode? focusNode,
    VoidCallback? onEnter,
    VoidCallback? onActivate,
  }) {
    if (!_focusOrder.contains(id)) {
      _focusOrder.add(id);
    }

    if (focusNode != null) {
      _focusNodes[id] = focusNode;
      _ownsFocusNode[id] = false;
    } else {
      _focusNodes[id] ??= FocusNode();
      _ownsFocusNode[id] = true;
    }

    if (onEnter != null) _onEnterCallbacks[id] = onEnter;
    if (onActivate != null) _onActivateCallbacks[id] = onActivate;
  }

  void unregisterWidget(String id) {
    if (_focusNodes.containsKey(id) && (_ownsFocusNode[id] ?? false)) {
      _focusNodes[id]?.dispose();
    }

    _focusNodes.remove(id);
    _ownsFocusNode.remove(id);
    _onEnterCallbacks.remove(id);
    _onActivateCallbacks.remove(id);
    _directionOverrides.remove(id);
    _focusOrder.remove(id);

    if (_currentFocusedId == id) {
      _currentFocusedId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    }
  }

  void registerDirectionalOverride({
    required String fromId,
    required Direction direction,
    required String toId,
  }) {
    _directionOverrides[fromId] ??= {};
    _directionOverrides[fromId]![direction] = toId;
  }

  void moveIdToEnd(String id) {
    if (_focusOrder.contains(id)) {
      _focusOrder.remove(id);
      _focusOrder.add(id);
      notifyListeners();
    }
  }

  // ---------------------
  // Hover & activate
  // ---------------------
  void setHoverState(String? id) {
    if (_currentHoveredId == id) return;
    _currentHoveredId = id;
    notifyListeners();
  }

  void activateFocusedWidget() {
    if (_currentFocusedId != null) {
      _onActivateCallbacks[_currentFocusedId]?.call();
    }
  }

  // ---------------------
  // Focus control
  // ---------------------
  void setFocus(String? id, {bool notify = true}) {
    if (_currentFocusedId == id) return;

    _currentFocusedId = id;
    _mode = AppNavigationMode.keyboard;
    _lastKeyboardInteraction = DateTime.now();

    if (notify) notifyListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (id != null) {
        final node = _focusNodes[id];
        if (node != null && !node.hasFocus) {
          try {
            node.requestFocus();
          } catch (_) {}
        }
      }
    });
  }

  void moveFocus(Direction direction) {
    if (_focusOrder.isEmpty) return;

    final currentIndex = _currentFocusedId != null
        ? _focusOrder.indexOf(_currentFocusedId!)
        : -1;

    int nextIndex;

    switch (direction) {
      case Direction.down:
      case Direction.right:
        nextIndex = (currentIndex + 1) % _focusOrder.length;
        break;
      case Direction.up:
      case Direction.left:
        nextIndex = (currentIndex - 1 + _focusOrder.length) % _focusOrder.length;
        break;
    }

    _mode = AppNavigationMode.keyboard;
    _lastKeyboardInteraction = DateTime.now();

    if (_currentFocusedId != null) {
      _focusNodes[_currentFocusedId!]?.unfocus();
    }

    setFocus(_focusOrder[nextIndex]);
  }

  void handleMouseMovement() {
    final diff = DateTime.now().difference(_lastKeyboardInteraction);
    if (diff.inMilliseconds > 500) {
      _mode = AppNavigationMode.mouse;
      notifyListeners();
    }
  }

  FocusNode? focusNodeFor(String id) => _focusNodes[id];
  bool isHovered(String id) => _currentHoveredId == id;

  // ---------------------
  // Clear / modal handling
  // ---------------------
  void clearAll() {
    _focusNodes.forEach((id, node) {
      if (_ownsFocusNode[id] == true) node.dispose();
    });

    _focusNodes.clear();
    _ownsFocusNode.clear();
    _onEnterCallbacks.clear();
    _onActivateCallbacks.clear();
    _directionOverrides.clear();
    _focusOrder.clear();

    _currentFocusedId = null;
    _currentHoveredId = null;

    notifyListeners();
  }

  /// Push modal: temporarily suspend current navigation
  void pushModal() {
    _navigationStack.add(
      _NavigationSnapshot(
        focusOrder: List.from(_focusOrder),
        currentFocusedId: _currentFocusedId,
      ),
    );

    // Clear current navigation for modal
    clearAll();
  }

  /// Pop modal: restore previous navigation state
  void popModal() {
    if (_navigationStack.isEmpty) return;

    final snapshot = _navigationStack.removeLast();

    _focusOrder
      ..clear()
      ..addAll(snapshot.focusOrder);

    _currentFocusedId = snapshot.currentFocusedId;

    notifyListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentFocusedId != null) {
        _focusNodes[_currentFocusedId!]?.requestFocus();
      }
    });
  }
}

class _NavigationSnapshot {
  final List<String> focusOrder;
  final String? currentFocusedId;

  _NavigationSnapshot({
    required this.focusOrder,
    required this.currentFocusedId,
  });
}
