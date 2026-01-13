import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_places_suggestions_autocomplete_field/google_places_suggestions_autocomplete_field.dart';
import 'package:provider/provider.dart';

import 'core/services/navigation_service.dart';
import 'keyboard_manager.dart';
import 'keyboard_navigation_area.dart';
import 'navigable_textfield.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => NavigationService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Places Autocomplete Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? resultObject;

  final TextEditingController _standardController = TextEditingController();
  final TextEditingController _keyboardController = TextEditingController();

  final KeyboardManager _keyboardManager = KeyboardManager();

  @override
  void initState() {
    super.initState();
    _keyboardManager.init(context);
  }

  /// ------------------------------------------------------------
  /// EXAMPLE 2 WIDGET: KEYBOARD-NAVIGABLE AUTOCOMPLETE
  /// ------------------------------------------------------------
  Widget _buildKeyboardNavigableAutocomplete() {
    return SizedBox(
      width: 400,
      child: NavigableTextField(
        id: 'address_textfield',
        controller: _keyboardController,
        showVirtualKeyboard: true,
        builder: (focusNode) {
          return GooglePlacesSuggestionsAutoCompleteField(
            controller: _keyboardController,
            focusNode: focusNode,
            googleAPIKey: 'YOUR_GOOGLE_API_KEY',
            countries: 'za,de',
            onPlaceSelected: (place) {
              setState(() {
                resultObject = jsonEncode(place.toJson());
              });
            },
            onTapField: (controller, focusNode) {
              _keyboardManager.focusTextField(controller, focusNode);
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardNavigationArea(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (_keyboardManager.showVirtualKeyboard) {
            FocusScope.of(context).unfocus();
          }
        },
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------------------------------------------------------
                // EXAMPLE 1: STANDARD USAGE (NO KEYBOARD NAVIGATION)
                // ------------------------------------------------------------
                const Text(
                  'Standard Autocomplete (No Keyboard Navigation)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: 400,
                  child: GooglePlacesSuggestionsAutoCompleteField(
                    controller: _standardController,
                    googleAPIKey: 'YOUR_GOOGLE_API_KEY',
                    countries: 'za,de',
                    onPlaceSelected: (place) {
                      setState(() {
                        resultObject = jsonEncode(place.toJson());
                      });
                    },
                    /// Uncomment below onTap if you want to test with built in soft keyboard.
                     /*onTapField: (controller, focusNode) {
                  _keyboardManager.focusTextField(controller, focusNode);
                },*/
                  ),
                ),

                const SizedBox(height: 60),

                // ------------------------------------------------------------
                // EXAMPLE 2: WITH KEYBOARD NAVIGATION
                // ------------------------------------------------------------
                const Text(
                  'Autocomplete With Keyboard Navigation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                _buildKeyboardNavigableAutocomplete(),

                const SizedBox(height: 60),

                if (resultObject != null)
                  Text(
                    'Returned Location:\n$resultObject',
                    style: const TextStyle(fontSize: 14),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}