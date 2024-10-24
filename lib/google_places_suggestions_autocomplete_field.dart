/// This library provides a Google Places Autocomplete TextField with suggestions.
/// It supports searching locations and displaying suggestions based on Google Places API.
library google_places_suggestions_autocomplete_field;

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'models/location_piece.dart';
import 'models/place.dart';
import 'models/place_response.dart';
import 'models/point.dart';
import 'services/google_api.dart';
import 'widgets/auto_complete_text_field.dart';

/// A StatefulWidget that provides an autocomplete text field
/// with suggestions fetched from Google Places API.
/// This widget supports location type-based filtering and country restrictions.
class GooglePlacesSuggestionsAutoCompleteField extends StatefulWidget {
  /// Controller for managing the text field input.
  final TextEditingController controller;

  /// Hint text to be shown in the text field.
  final String hint;

  /// Optional decoration for the input field.
  final InputDecoration? decoration;

  /// Background color for the suggestion list.
  final Color suggestionBackgroundColor;

  /// Divider color used between suggestions.
  final Color suggestionDividerColor;

  /// Text style for the suggestions.
  final TextStyle? suggestionTextStyle;

  /// Google API Key used to fetch suggestions and details.
  final String googleAPIKey;

  /// Callback function triggered when a place is selected from the suggestions.
  final Function(Place) onPlaceSelected;

  /// Location type for filtering results (e.g., address, geocode).
  final String locationType;

  /// A comma-separated list of country codes to restrict the search results.
  final String countries;

  /// Constructor for GooglePlacesSuggestionsAutoCompleteField.
  /// Takes required parameters for [controller], [googleAPIKey], and [onPlaceSelected].
  const GooglePlacesSuggestionsAutoCompleteField({
    super.key,
    required this.controller,
    this.hint = "Address",
    this.decoration,
    this.suggestionBackgroundColor = Colors.white,
    this.suggestionDividerColor = Colors.black87,
    this.suggestionTextStyle,
    required this.googleAPIKey,
    required this.onPlaceSelected,
    this.locationType = "address",
    this.countries = "za",
  });

  @override
  _GooglePlacesSuggestionsAutoCompleteFieldState createState() =>
      _GooglePlacesSuggestionsAutoCompleteFieldState();
}

class _GooglePlacesSuggestionsAutoCompleteFieldState
    extends State<GooglePlacesSuggestionsAutoCompleteField> {
  /// StreamController to handle the suggestion list updates.
  StreamController<List<PlaceResponse>> placeSuggestionController =
  StreamController<List<PlaceResponse>>();

  /// Holds the selected location from the suggestions.
  Place? pickUpLocation;

  /// Session token for managing Google API calls.
  String? pickUpDateSessionToken;

  /// Holds the final selected location.
  Place? selectedLocation;

  /// Google API handler for fetching place details and autocomplete suggestions.
  late GoogleApi _googleApi;

  /// Key used for the autocomplete text field.
  GlobalObjectKey<AutoCompleteTextFieldState<PlaceResponse>> pickUpPlaceKey =
  const GlobalObjectKey("__pickUpPlaceKey__");

  @override
  void initState() {
    super.initState();
    _googleApi = GoogleApi(widget.googleAPIKey);
    init();
  }

  /// Builds the widget for the Google Places Autocomplete text field
  /// and suggestion dropdown.
  @override
  Widget build(BuildContext context) {
    return getCustomAutoCompleteTextField(
      controller: widget.controller,
      hint: widget.hint,
      key: pickUpPlaceKey,
      decoration: widget.decoration,
      suggestionBackgroundColor: widget.suggestionBackgroundColor,
      suggestionDividerColor: widget.suggestionDividerColor,
      itemBuilder: (context, placeResponse) {
        return Container(
          color: widget.suggestionBackgroundColor,
          child: Text(
            placeResponse.description,
            style: widget.suggestionTextStyle ??
                TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black87),
          ),
        );
      },
      placeSuggestionController: placeSuggestionController,
      onItemSubmitted: (placeSelected) async {

        onPickUpLocationSelectionChange(placeSelected);
        pickUpPlaceKey.currentState?.updateSuggestions([]);
        FocusScope.of(context).unfocus();
      },
      itemFilter: (suggestion, input) {
        return true;
      },
      onTextChange: (input) {
        if (input.length > 2) {
          updateLocationPredictions(input);
        } else {
          pickUpPlaceKey.currentState?.updateSuggestions([]);
        }
      },
    );
  }

  /// Initializes the Google API session token and suggestion controller.
  void init() {
    placeSuggestionController.add([]);
    pickUpDateSessionToken = Uuid().v4().toString();
  }

  /// Handles the selection of a location and retrieves detailed place information.
  /// Updates the state with the selected location.
  void onPickUpLocationSelectionChange(PlaceResponse placeResponse) {
    pickUpLocation = null;
    setState(() {});

    _googleApi
        .getPlaceDetails(
      placeId: placeResponse.place_id,
      sessionToken: pickUpDateSessionToken,
    )
        .then((placeDetails) {
      if (placeDetails.result != null) {
        // Create a Point object with latitude and longitude.
        Point? point = Point(
            placeDetails.result?.geometry?.location?.lng ?? -1,
            placeDetails.result?.geometry?.location?.lat ?? -1);

        // Update the selected location.
        pickUpLocation = Place.newInstance(placeResponse.description, point.x, point.y);

        // Generate a new session token for subsequent requests.
        pickUpDateSessionToken = Uuid().v4().toString();

        // Parse address components from the place details.
        String? streetNumber = placeDetails.result?.address_components
            ?.firstWhereOrNull((LocationPiece element) =>
            element.types!.contains("street_number"))
            ?.longName ??
            "";
        String? streetAddress = placeDetails.result?.address_components
            ?.firstWhereOrNull((element) => element.types!.contains("route"))
            ?.longName ??
            "";
        String? suburb = placeDetails.result?.address_components
            ?.firstWhereOrNull((element) =>
            element.types!.contains("sublocality_level_1"))
            ?.longName ??
            "";
        String? city = placeDetails.result?.address_components
            ?.firstWhereOrNull((element) => element.types!.contains("locality"))
            ?.longName ?? "";
        String? province = placeDetails.result?.address_components
            ?.firstWhereOrNull((element) =>
            element.types!.contains("administrative_area_level_1"))
            ?.longName ??
            "";
        String? country = placeDetails.result?.address_components
            ?.firstWhereOrNull((element) => element.types!.contains("country"))
            ?.longName ??
            "";
        String? postalCode = placeDetails.result?.address_components
            ?.firstWhereOrNull((element) => element.types!.contains("postal_code"))
            ?.longName ??
            "";

        // Format the full address.
        String? address = "${streetNumber.isNotEmpty ? "$streetNumber, " : ""}"
            "${streetAddress.isNotEmpty ? "$streetAddress, " : ""}"
            "${suburb.isNotEmpty ? "$suburb, " : ""}"
            "${city.isNotEmpty ? "$city, " : ""}"
            "${province.isNotEmpty ? "$province, " : ""}"
            "${country.isNotEmpty ? "$country, " : ""}"
            "${postalCode.isNotEmpty ? "$postalCode, " : ""}";

        setState(() {
          widget.controller.text = address;
        });

        // Update the selected location object and trigger the callback.
        Place? selectedLocation = Place(
          address: address,
          code: int.tryParse(postalCode),
          latitude: pickUpLocation?.latitude,
          longitude: pickUpLocation?.longitude,
          city: city,
          province: province,
          suburb: suburb,
          country: country,
        );
        setState(() {
          this.selectedLocation = selectedLocation;
          widget.onPlaceSelected(selectedLocation);
        });
      }
    }).catchError((error, trace) {
      debugPrint(error.toString());
      debugPrintStack(stackTrace: trace, label: "Google getPlaceDetails");
    });
  }

  /// Updates the suggestion list by fetching predictions from Google Places API.
  void updateLocationPredictions(String input) {
    try {
      placeSuggestionController.add([]);
    } catch (e) {
      debugPrint(e.toString());
    }
    _googleApi
        .getAutoCompletePlaces(
      input: input,
      sessionToken: pickUpDateSessionToken,
      countries: widget.countries,
      types: widget.locationType,
    )
        .then((placesPredictions) {
      setState(() {
        placeSuggestionController.add(placesPredictions.predictions ?? []);
      });
    }).catchError((error, trace) {
      debugPrint(error.toString());
      debugPrintStack(stackTrace: trace, label: "Google getAutoCompletePlaces");
    });
  }

  Widget getCustomAutoCompleteTextField(
      {String hint = "Location",
        itemBuilder,
        required Function(PlaceResponse) onItemSubmitted,
        GlobalObjectKey<AutoCompleteTextFieldState<PlaceResponse>>? key,
        itemFilter,
        controller,
        onTextChange,
        placeSuggestionController,
        InputDecoration? decoration,
        required Color suggestionBackgroundColor,
        required Color suggestionDividerColor,
      }) {
    return IntrinsicHeight(
      child: AutoCompleteTextField<PlaceResponse>(

        clearOnSubmit: false,
        submitOnSuggestionTap: true,
        onFocusChanged: (val) {
          if (!val) {
            //key?.currentState?.updateSuggestions([]);
          }
        },
        controller: controller,
        keyboardType: TextInputType.text,
        decoration: decoration?? InputDecoration(
          hintText:  hint,
          labelText: hint,
          icon: Icon(
            Icons.location_on,
            color: Color(0xffcc2f25),
          ),
          contentPadding: EdgeInsets.symmetric(
              horizontal: 16, vertical: 4),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.7),
              width: 2.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.7),
              width: 2.0,
            ),
          ),
        ),
        placeSuggestionController: placeSuggestionController,
        itemBuilder: itemBuilder,
        itemSorter: (a, b) => 1,
        itemFilter: itemFilter,
        itemSubmitted: onItemSubmitted,
        textChanged: onTextChange,
        key: key,
        suggestionBackgroundColor: suggestionBackgroundColor,
        suggestionDividerColor: suggestionDividerColor,
      ),
    );
  }

}
