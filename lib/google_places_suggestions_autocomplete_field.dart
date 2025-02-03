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

const Duration fakeAPIDuration = Duration(seconds: 1);
const Duration debounceDuration = Duration(milliseconds: 500);

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

  /// Holds the selected location from the suggestions.
  Place? pickUpLocation;

  /// Session token for managing Google API calls.
  String? pickUpDateSessionToken;

  /// Holds the final selected location.
  Place? selectedLocation;

  /// Google API handler for fetching place details and autocomplete suggestions.
  late GoogleApi _googleApi;


  // The query currently being searched for. If null, there is no pending
  // request.
  String? _currentQuery;

  // The most recent options received from the API.
  late List<PlaceResponse> _lastOptions = [];

  late final _Debounceable<List<PlaceResponse>?, String> _debouncedSearch;
  // A network error was received on the most recent query.
  bool _networkError = false;

  @override
  void initState() {
    super.initState();
    _debouncedSearch = _debounce<List<PlaceResponse>?, String>(_search);
    _googleApi = GoogleApi(widget.googleAPIKey);
    init();
  }

  static String _displayStringForOption(PlaceResponse option) => option.description ?? "";

  /// Builds the widget for the Google Places Autocomplete text field
  /// and suggestion dropdown.
  @override
  Widget build(BuildContext context) {
    return Autocomplete<PlaceResponse>(
      displayStringForOption: _displayStringForOption,
      fieldViewBuilder: (BuildContext context,
          TextEditingController controller,
          FocusNode focusNode,
          VoidCallback onFieldSubmitted) {
        return TextFormField(
          decoration: widget.decoration != null ? widget.decoration?.copyWith(
              errorText: _networkError ? 'Network error, please try again.' : null,)
          : InputDecoration(
            hintText:  widget.hint,
            labelText: widget.hint,
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
          controller: controller,
          focusNode: focusNode,
          onFieldSubmitted: (String value) {
            onFieldSubmitted();
          },
        );
      },
      optionsBuilder: (TextEditingValue textEditingValue) async {
        setState(() {
          _networkError = false;
        });
        final List<PlaceResponse>? options = await _debouncedSearch(textEditingValue.text);
        if (options == null) {
          return _lastOptions;
        }
        _lastOptions = options;
        return options;
      },
      onSelected: (PlaceResponse selection) {
        onPickUpLocationSelectionChange(selection);
        debugPrint('You just selected ${selection.description}');
      },
    );
  }

  /// Initializes the Google API session token and suggestion controller.
  void init() {
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
          streetAddress: streetAddress,
          streetNumber: streetNumber
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
  Future<List<PlaceResponse>?> _search(String query) async {
    _currentQuery = query;

    late final List<PlaceResponse>? options;
    try {
      options = await _googleApi
          .getAutoCompletePlaces(
        input: _currentQuery,
        sessionToken: pickUpDateSessionToken,
        countries: widget.countries,
        types: widget.locationType,
      );
    } catch (error) {
      if (error is _NetworkException) {
        setState(() {
          _networkError = true;
        });
        return null;
      }
      rethrow;
    }

    // If another search happened after this one, throw away these options.
    if (_currentQuery != query) {
      return null;
    }
    _currentQuery = null;

    return options;
  }

}


typedef _Debounceable<S, T> = Future<S?> Function(T parameter);

/// Returns a new function that is a debounced version of the given function.
///
/// This means that the original function will be called only after no calls
/// have been made for the given Duration.
_Debounceable<S, T> _debounce<S, T>(_Debounceable<S?, T> function) {
  _DebounceTimer? debounceTimer;

  return (T parameter) async {
    if (debounceTimer != null && !debounceTimer!.isCompleted) {
      debounceTimer!.cancel();
    }
    debounceTimer = _DebounceTimer();
    try {
      await debounceTimer!.future;
    } catch (error) {
      if (error is _CancelException) {
        return null;
      }
      rethrow;
    }
    return function(parameter);
  };
}

// A wrapper around Timer used for debouncing.
class _DebounceTimer {
  _DebounceTimer() {
    _timer = Timer(debounceDuration, _onComplete);
  }

  late final Timer _timer;
  final Completer<void> _completer = Completer<void>();

  void _onComplete() {
    _completer.complete();
  }

  Future<void> get future => _completer.future;

  bool get isCompleted => _completer.isCompleted;

  void cancel() {
    _timer.cancel();
    _completer.completeError(const _CancelException());
  }
}

// An exception indicating that the timer was canceled.
class _CancelException implements Exception {
  const _CancelException();
}

// An exception indicating that a network request has failed.
class _NetworkException implements Exception {
  const _NetworkException();
}