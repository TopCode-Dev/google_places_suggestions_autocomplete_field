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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? resultObject;
  TextEditingController _textController = TextEditingController();
  final KeyboardManager _keyboardManager = KeyboardManager();

  Widget _buildNavigableAddressField() {
    return SizedBox(
      width: 400, // Fixed width
      child: NavigableTextField(
        id: 'address_textfield',
        controller: _textController,
        showVirtualKeyboard: true,
        builder: (focusNode) {
          return GooglePlacesSuggestionsAutoCompleteField(
            controller: _textController,
            focusNode: focusNode,
            googleAPIKey: "AIzaSyA7UcyhKVRaoY5kQOduH1tEZAExChPfbXs",
            countries: "za,de",
            onPlaceSelected: (place) {
              setState(() {
                resultObject = jsonEncode(place.toJson());
              });
              debugPrint("place: ${jsonEncode(place.toJson())}");
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
  void initState() {
    super.initState();
    _keyboardManager.init(context);
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardNavigationArea(
      child: Scaffold(
        body: SingleChildScrollView( // Add this to prevent overflow
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              Center(
                child: _buildNavigableAddressField(),
              ),
              if (resultObject != null)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 100),
                  child: Text(
                    "Returned Location: $resultObject",
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
