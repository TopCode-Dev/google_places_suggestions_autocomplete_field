import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/navigation_service.dart';

class KeyboardNavigationArea extends StatelessWidget {
  final Widget child;

  const KeyboardNavigationArea({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      autofocus: true,
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.tab): _TabIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.tab): _ShiftTabIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowDown): _ArrowDownIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowUp): _ArrowUpIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): _ArrowLeftIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): _ArrowRightIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): _ActivateIntent(),
        //LogicalKeySet(LogicalKeyboardKey.space): _ActivateIntent(),
      },
      actions: {
        _TabIntent: CallbackAction(
          onInvoke: (_) {
            NavigationService().moveFocus(Direction.down);
            return null;
          },
        ),
        _ShiftTabIntent: CallbackAction(
          onInvoke: (_) {
            NavigationService().moveFocus(Direction.up);
            return null;
          },
        ),
        _ArrowDownIntent: CallbackAction(
          onInvoke: (_) {
            NavigationService().moveFocus(Direction.down);
            return null;
          },
        ),
        _ArrowUpIntent: CallbackAction(
          onInvoke: (_) {
            NavigationService().moveFocus(Direction.up);
            return null;
          },
        ),
        _ArrowLeftIntent: CallbackAction(
          onInvoke: (_) {
            NavigationService().moveFocus(Direction.left);
            return null;
          },
        ),
        _ArrowRightIntent: CallbackAction(
          onInvoke: (_) {
            NavigationService().moveFocus(Direction.right);
            return null;
          },
        ),
        _ActivateIntent: CallbackAction(
          onInvoke: (_) {
            NavigationService().activateFocusedWidget();
            return null;
          },
        ),
      },
      child: child,
    );
  }
}

// intents
class _TabIntent extends Intent {}
class _ShiftTabIntent extends Intent {}
class _ArrowDownIntent extends Intent {}
class _ArrowUpIntent extends Intent {}
class _ArrowLeftIntent extends Intent {}
class _ArrowRightIntent extends Intent {}
class _ActivateIntent extends Intent {}