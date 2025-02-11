import 'package:flutter/material.dart';
import 'custom_keyboard.dart';

class KeyboardManager extends ChangeNotifier {
  static final KeyboardManager _instance = KeyboardManager._internal();
  OverlayEntry? _keyboardOverlay;
  bool _isShiftActive = false;
  TextEditingController? _activeController;
  TextEditingController? _textController;
  FocusNode? _focusNode;
  BuildContext? _context;
  bool showVirtualKeyboard = true;

  factory KeyboardManager() {
    return _instance;
  }

  KeyboardManager._internal();

  void init(BuildContext context) {
    _context = context;
    _focusNode = FocusNode();
    _focusNode!.addListener(() {
    });
  }

  void _focusListener() {
    if (_focusNode == null) return;

    // Prevent unnecessary refocus
    if (!_focusNode!.hasFocus) {

      // If keyboard is closed, do NOT restore focus
      if (_keyboardOverlay == null) {
        return;
      }

      // Allow normal focus behavior when tapping inside field
      Future.delayed(Duration(milliseconds: 100), () {
        if (_activeController != null && !_focusNode!.hasFocus) {
        }
      });
    }
  }

  void focusTextField(TextEditingController controller, FocusNode focusNode) {

    _activeController = controller;
    _textController = controller;

    if (_focusNode != focusNode) {
      _focusNode?.removeListener(_focusListener); // Remove old listener
      _focusNode = focusNode;
      _focusNode!.addListener(_focusListener); // Reattach listener
    }
    if (showVirtualKeyboard) {
      _showKeyboardOverlay();
    }

    // Requesting focus on the text field
    if (!_focusNode!.hasFocus) {
      debugPrint("Restoring focus immediately.");
      FocusScope.of(_context!).requestFocus(_focusNode);
    }
  }

  void unfocusTextField() {
    _removeKeyboardOverlay();
    if (_focusNode != null) {
      _focusNode!.removeListener(_focusListener);
      _focusNode!.unfocus();
    }
    _activeController = null;
    _textController = null;
  }

  void _showKeyboardOverlay() {
    if (_keyboardOverlay != null && Overlay.of(_context!)?.mounted == true) return;

    _keyboardOverlay = OverlayEntry(
        builder: (context) => Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Material(
            color: Colors.blueGrey,
            child : FocusScope(
              canRequestFocus: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.black, size: 28),
                      onPressed: () {
                        _removeKeyboardOverlay();
                      },
                      padding: EdgeInsets.all(12),
                      constraints: BoxConstraints(),
                      splashRadius: 28,
                    ),
                  ),
                  CustomKeyboard(
                    focusNode: _focusNode,
                    controller: _activeController!,
                    onKeyTap: (key) => _handleCustomKeyPress(key),
                    onBackspace: _handleBackspace,
                    onShiftToggle: _toggleShift,
                    isShiftActive: _isShiftActive,
                  ),
                ],
              ),
            ),
          ),
        )
    );
      Overlay.of(_context!).insert(_keyboardOverlay!);
  }

  void _removeKeyboardOverlay() {
    if (_keyboardOverlay != null) {
      _keyboardOverlay!.remove();
      _keyboardOverlay = null;
    }
    if (_focusNode != null) {
      _focusNode!.unfocus();
    }
  }

  void _handleCustomKeyPress(String key) {
    if (_focusNode != null && _activeController != null) {
      if (!_focusNode!.hasFocus) {
        FocusScope.of(_context!).requestFocus(_focusNode);
      }

      final controller = _activeController!;
      String text = controller.text;

      // Always move the cursor to the end before inserting
      int cursorPos = text.length;
      String newKey = _isShiftActive ? key.toUpperCase() : key;
      String newText = text + newKey; // Append at the end

      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length), // Move cursor to end
      );
    }
  }

  void _handleBackspace() {
    if (_focusNode != null && _activeController != null) {
      if (!_focusNode!.hasFocus) {
        FocusScope.of(_context!).requestFocus(_focusNode);
      }
      final controller = _activeController!;
      String text = controller.text;

      if (text.isNotEmpty) {
        // Always delete the last character (ensuring we operate at the end)
        String newText = text.substring(0, text.length - 1);

        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length), // Keep cursor at the end
        );

        if (newText.isEmpty) {
          controller.clear();
          notifyListeners();
        }

        // Ensuring widget.controller is also updated
        if (_textController != null) {
          _textController!.text = newText;
          _textController!.selection = TextSelection.collapsed(offset: newText.length);
        }
      }
    }
  }

  void _toggleShift() {
    _isShiftActive = !_isShiftActive;
    notifyListeners();

    if (_focusNode != null && !_focusNode!.hasFocus) {
      FocusScope.of(_context!).requestFocus(_focusNode);
    }
  }

  bool get isShiftActive => _isShiftActive;
}