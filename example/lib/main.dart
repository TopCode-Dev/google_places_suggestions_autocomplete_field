import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_places_suggestions_autocomplete_field/google_places_suggestions_autocomplete_field.dart';
import 'keyboard_manager.dart';

void main() {
  runApp(const MyApp());
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
  @override
  void initState() {
    super.initState();
    KeyboardManager().init(context);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 100, horizontal: 100),
            height: 50,
            width: 400,
            child: GooglePlacesSuggestionsAutoCompleteField(
              controller: _textController,
              googleAPIKey: "xyz",/// Replace with your Google Places API Key
              countries: "za,de", ///The countries for the predictions.
              onPlaceSelected: (place) {
                setState(() {
                  resultObject = jsonEncode(place.toJson());
                });
                debugPrint("place: ${jsonEncode(place.toJson())}");
              },
              onTapField: (controller, focusNode) {
                debugPrint("_textController: ${_textController}");
                debugPrint("Keyboard should pop up");
                KeyboardManager().focusTextField(controller, focusNode);
              },
            ),
          ),
          resultObject != null ? Container(
              margin: EdgeInsets.symmetric(vertical: 100, horizontal: 100),
              child: Text("Returned Location: $resultObject")
          ) : Container()
        ],
      ),
    );
  }
}
