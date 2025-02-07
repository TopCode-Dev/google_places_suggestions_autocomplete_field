import 'package:flutter/material.dart';

class CustomKeyboard extends StatefulWidget {
  final Function(String) onKeyTap;
  final Function() onBackspace;
  final Function() onShiftToggle;
  final bool isShiftActive;
  final TextEditingController controller;
  final FocusNode? focusNode;

  CustomKeyboard({
    required this.onKeyTap,
    required this.onBackspace,
    required this.onShiftToggle,
    required this.isShiftActive,
    required this.controller,
    this.focusNode,
  });

  @override
  _CustomKeyboardState createState() => _CustomKeyboardState();
}

class _CustomKeyboardState extends State<CustomKeyboard> {
  final List<String> _topRow = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '0',
    '-',
    '=',
    '@',
    '#'
  ];
  final List<String> _qwertyRow = [
    'q',
    'w',
    'e',
    'r',
    't',
    'y',
    'u',
    'i',
    'o',
    'p',
    '[',
    ']'
  ];
  final List<String> _homeRow = [
    'a',
    's',
    'd',
    'f',
    'g',
    'h',
    'j',
    'k',
    'l',
    ';',
    "'",
    '\\'
  ];
  final List<String> _bottomRow = [
    'z',
    'x',
    'c',
    'v',
    'b',
    'n',
    'm',
    ',',
    '.',
    '/',
    '(',
    ')'
  ];

  bool isShiftActive = false;
  String activeKey = '';

  @override
  void initState() {
    super.initState();
    debugPrint("init focus: ${widget.focusNode?.hasFocus}");
    widget.focusNode!.requestFocus();
    isShiftActive = widget.isShiftActive;
  }

  void toggleShift() {
    setState(() {
      isShiftActive = !isShiftActive;
      widget.onShiftToggle();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey,
      padding: EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(_topRow),
          _buildRow(_qwertyRow),
          _buildRow(_homeRow),
          _buildBottomRow(),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) => _buildKey(key)).toList(),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildFunctionKey('⇧', toggleShift),
        ..._bottomRow.map((key) => _buildKey(key)).toList(),
        _buildFunctionKey('␣', () => widget.onKeyTap(' '), width: 250),
        _buildFunctionKey('⌫', widget.onBackspace),
      ],
    );
  }

  Widget _buildKey(String label, {double width = 70}) {
    String displayLabel = isShiftActive ? label.toUpperCase() : label
        .toLowerCase();
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          activeKey = label;
        });
      },
      onTapUp: (_) {
        setState(() {
          activeKey = '';
        });
      },
      onTapCancel: () {
        setState(() {
          activeKey = '';
        });
      },
      onTap: () {
        widget.onKeyTap(displayLabel);
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 100),
        margin: EdgeInsets.all(5),
        width: width,
        height: 70,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: activeKey == label ? Colors.grey : Colors.grey,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black),
        ),
        child: Text(
          displayLabel,
          style: TextStyle(fontSize: 22, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildFunctionKey(String label, Function() onPressed,
      {double width = 100}) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          activeKey = label;
        });
      },
      onTapUp: (_) {
        setState(() {
          activeKey = '';
        });
      },
      onTapCancel: () {
        setState(() {
          activeKey = '';
        });
      },
      onTap: () {
        onPressed();
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 100),
        margin: EdgeInsets.all(5),
        width: width,
        height: 70,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: activeKey == label || (isShiftActive && label == '⇧')
              ? Colors.blueGrey
              : Colors.blueGrey,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
            label, style: TextStyle(fontSize: 22, color: Colors.white)),
      ),
    );
  }
}
