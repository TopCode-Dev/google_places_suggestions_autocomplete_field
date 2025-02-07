import 'package:flutter/material.dart';
import 'custom_keyboard.dart';

class KeyboardManager extends ChangeNotifier {
  static final KeyboardManager _instance = KeyboardManager._internal();
  OverlayEntry? _keyboardOverlay;
  bool _isShiftActive = false;
  TextEditingController? _activeController;
  FocusNode? _focusNode;
  BuildContext? _context;
  bool showVirtualKeyboard = true;

  factory KeyboardManager() {
    return _instance;
  }

  KeyboardManager._internal();

  void init(BuildContext context) {
    _context = context;
  }

  void focusTextField(TextEditingController controller, FocusNode focusNode) {
    debugPrint("Focusing on controller: ${controller}");

    _activeController = controller;
    _focusNode = focusNode;

    // Ensure selection is valid
    TextSelection existingSelection = controller.selection;
    debugPrint(" existing selection: ${existingSelection}");
    if (!existingSelection.isValid || existingSelection.baseOffset < 0) {
      existingSelection = TextSelection.collapsed(offset: controller.text.length);
    }

    // Request focus AND restore selection immediately
   /* _focusNode!.requestFocus();*/
    debugPrint("focus1: ${_focusNode?.hasFocus}");
    if (_focusNode != null && !_focusNode!.hasFocus) {
      FocusScope.of(_context!).requestFocus(_focusNode);
    }
    debugPrint("focus2: ${_focusNode?.hasFocus}");
    controller.selection = existingSelection;
    debugPrint("Focus requested on ${controller}, Cursor restored at: ${controller.selection.start}");

    if (showVirtualKeyboard) {
      _showKeyboardOverlay();
    }
  }

  void unfocusTextField() {
    _removeKeyboardOverlay();
    _activeController = null;
  }

  void _showKeyboardOverlay() {
    _removeKeyboardOverlay();
    if (_focusNode != null && !_focusNode!.hasFocus) {
      FocusScope.of(_context!).requestFocus(_focusNode);
    }
    debugPrint("focus5: ${_focusNode?.hasFocus}");
    _keyboardOverlay = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.blueGrey,
            child : Column(
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
                Focus(
                  canRequestFocus: false,
                  child: CustomKeyboard(
                    focusNode: _focusNode,
                    controller: _activeController!,
                    onKeyTap: (key) => _handleCustomKeyPress(key),
                    onBackspace: _handleBackspace,
                    onShiftToggle: _toggleShift,
                    isShiftActive: _isShiftActive,
                  ),
                ),
              ],
            ),
        ),
      )
    );
    Overlay.of(_context!).insert(_keyboardOverlay!);
    if (_focusNode != null && !_focusNode!.hasFocus) {
      FocusScope.of(_context!).requestFocus(_focusNode);
    }
    debugPrint("focus6: ${_focusNode?.hasFocus}");
  }

  void _removeKeyboardOverlay() {
    if (_keyboardOverlay != null) {
      _keyboardOverlay!.remove();
      _keyboardOverlay = null;
       notifyListeners();
    }
  }

  void _handleCustomKeyPress(String key) {
    debugPrint("focus3: ${_focusNode?.hasFocus}");
    if (_activeController != null) {
      final controller = _activeController!;
      String text = controller.text;
      TextSelection selection = controller.selection;

      int cursorPos = selection.baseOffset;

      // Ensure cursor is within bounds
      if (cursorPos < 0 || cursorPos > text.length) {
        cursorPos = text.length;
      }

      debugPrint("Cursor Position Before Insertion: $cursorPos, Text Length: ${text.length}");

      String newKey = _isShiftActive ? key.toUpperCase() : key;
      String newText = text.substring(0, cursorPos) + newKey + text.substring(cursorPos);

      int newCursorPos = cursorPos + 1; // Move cursor forward after inserting

      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursorPos),
      );

      debugPrint("Inserted: '$newKey' at position $cursorPos, New Cursor Position: $newCursorPos");
      debugPrint("focus4: ${_focusNode?.hasFocus}");

      // Ensure keyboard suggestions show up by keeping focus active
      /*if (_focusNode != null && !_focusNode!.hasFocus) {
        FocusScope.of(_context!).requestFocus(_focusNode);
*//*
*//*
      }*/
    }
  }

  void _handleBackspace() {
    if (_activeController != null) {
      final controller = _activeController!;
      final text = controller.text;
      final selection = controller.selection;
      final cursorPos = selection.start;

      if (cursorPos > 0) {
        final newText = text.substring(0, cursorPos - 1) + text.substring(cursorPos);
        int newCursorPos = cursorPos - 1;

        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newCursorPos),
        );

        debugPrint("Backspace at position $cursorPos, New Cursor Position: $newCursorPos");

      /*  // Keep focus on the text field for keyboard suggestions
        if (_focusNode != null && !_focusNode!.hasFocus) {
          FocusScope.of(_context!).requestFocus(_focusNode);
        }*/
      }
    }
  }

  void _toggleShift() {
    _isShiftActive = !_isShiftActive;
    notifyListeners();
  }

  bool get isShiftActive => _isShiftActive;
}