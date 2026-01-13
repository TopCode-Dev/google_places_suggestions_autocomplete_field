import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../core/services/navigation_service.dart';
import 'keyboard_manager.dart'; // Add this import

class NavigableTextField extends StatefulWidget {
  final String id;
  final TextEditingController controller;
  final Widget Function(FocusNode focusNode) builder;
  final bool showVirtualKeyboard;

  const NavigableTextField({
    Key? key,
    required this.id,
    required this.controller,
    required this.builder,
    this.showVirtualKeyboard = false,
  }) : super(key: key);

  @override
  State<NavigableTextField> createState() => _NavigableTextFieldState();
}

class _NavigableTextFieldState extends State<NavigableTextField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    NavigationService().registerWidget(
      id: widget.id,
      focusNode: _focusNode,
      onActivate: () {
        if (!_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
        // ADD THIS: Trigger virtual keyboard when activated via keyboard navigation
        if (widget.showVirtualKeyboard) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            KeyboardManager().focusTextField(widget.controller, _focusNode);
          });
        }
      },
    );

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        // Immediate notification when focus is gained
        NavigationService().setFocus(widget.id, notify: true);

        // ADD THIS: Trigger virtual keyboard when focus is gained
        if (widget.showVirtualKeyboard) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            KeyboardManager().focusTextField(widget.controller, _focusNode);
          });
        }
      } else {
        // Clear focus when lost
        if (NavigationService().currentFocusedId == widget.id) {
          NavigationService().setFocus(null, notify: true);
        }
      }
    });
  }

  @override
  void dispose() {
    NavigationService().unregisterWidget(widget.id);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationService>(
      builder: (context, navigation, child) {
        final isFocused = navigation.currentFocusedId == widget.id;

        // Request focus immediately when service instructs
        if (isFocused && !_focusNode.hasFocus) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_focusNode.hasFocus) {
              _focusNode.requestFocus();

              // ADD THIS: Trigger virtual keyboard when focus is requested
              if (widget.showVirtualKeyboard) {
                KeyboardManager().focusTextField(widget.controller, _focusNode);
              }
            }
          });
        }

        return widget.builder(_focusNode);
      },
    );
  }
}