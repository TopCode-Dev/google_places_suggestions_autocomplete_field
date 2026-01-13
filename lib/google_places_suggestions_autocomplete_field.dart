/// This library provides a Google Places Autocomplete TextField with suggestions.
/// It supports searching locations and displaying real-time address suggestions
/// using the Google Places API. The widget includes debouncing, customizable
/// suggestion UI, country and location-type filtering, and detailed place
/// resolution upon selection.
library google_places_suggestions_autocomplete_field;

import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'models/place.dart';
import 'models/place_response.dart';
import 'models/point.dart';
import 'services/google_api.dart';

const Duration debounceDuration = Duration(milliseconds: 500);

class GooglePlacesSuggestionsAutoCompleteField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final InputDecoration? decoration;
  final Color suggestionBackgroundColor;
  final Color suggestionDividerColor;
  final TextStyle? suggestionTextStyle;
  final String googleAPIKey;
  final Function(Place) onPlaceSelected;
  final String locationType;
  final String countries;
  final void Function(TextEditingController, FocusNode)? onTapField;

  const GooglePlacesSuggestionsAutoCompleteField({
    super.key,
    required this.controller,
    this.focusNode,
    this.hint = "Address",
    this.decoration,
    this.suggestionBackgroundColor = Colors.white,
    this.suggestionDividerColor = Colors.black87,
    this.suggestionTextStyle,
    required this.googleAPIKey,
    required this.onPlaceSelected,
    this.locationType = "address",
    this.countries = "za",
    this.onTapField,
  });

  @override
  GooglePlacesSuggestionsAutoCompleteFieldState createState() =>
      GooglePlacesSuggestionsAutoCompleteFieldState();
}

/// Public state class for GooglePlacesSuggestionsAutoCompleteField
class GooglePlacesSuggestionsAutoCompleteFieldState
    extends State<GooglePlacesSuggestionsAutoCompleteField> {
  late FocusNode _focusNode;
  late GoogleApi _googleApi;

  String? pickUpDateSessionToken;
  Place? pickUpLocation;
  Place? selectedLocation;

  bool _networkError = false;
  bool _isSelectingPlace = false;
  Timer? _debounceTimer;

  final ValueNotifier<List<PlaceResponse>> _suggestions = ValueNotifier([]);

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _googleApi = GoogleApi(widget.googleAPIKey);
    pickUpDateSessionToken = const Uuid().v4();

    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    if (widget.focusNode == null) _focusNode.dispose();
    _suggestions.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (_isSelectingPlace) return;

    final text = widget.controller.text.trim();
    _debounceTimer?.cancel();

    _debounceTimer = Timer(debounceDuration, () async {
      if (text.length < 2) {
        _suggestions.value = [];
        return;
      }

      try {
        final results = await _googleApi.getAutoCompletePlaces(
          input: text,
          sessionToken: pickUpDateSessionToken,
          countries: widget.countries,
          types: widget.locationType,
        );
        _suggestions.value = results ?? [];
        _networkError = false;
      } catch (_) {
        _suggestions.value = [];
        _networkError = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          decoration: widget.decoration?.copyWith(
            errorText: _networkError ? 'Network error, please try again.' : null,
          ) ?? InputDecoration(
            hintText: widget.hint,
            labelText: widget.hint,
            icon: const Icon(Icons.location_on, color: Color(0xffcc2f25)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.7), width: 2.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.7), width: 2.0),
            ),
          ),
          onTap: () {
            widget.onTapField?.call(widget.controller, _focusNode);
            if (!_focusNode.hasFocus) {
              FocusScope.of(context).requestFocus(_focusNode);
            }
          },
        ),
        ValueListenableBuilder<List<PlaceResponse>>(
          valueListenable: _suggestions,
          builder: (context, suggestions, _) {
            if (suggestions.isEmpty) return const SizedBox.shrink();

            final maxItemHeight = 48.0;
            final separatorHeight = 1.0;
            final totalHeight = (suggestions.length * maxItemHeight) +
                ((suggestions.length - 1) * separatorHeight);
            final maxAllowedHeight = MediaQuery.of(context).size.height * 0.4;

            return ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                maxHeight: totalHeight > maxAllowedHeight
                    ? maxAllowedHeight
                    : totalHeight,
                minWidth: 400,
              ),
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  color: widget.suggestionBackgroundColor,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: suggestions.length,
                    separatorBuilder: (_, __) => Divider(
                      height: separatorHeight,
                      thickness: separatorHeight,
                      color: widget.suggestionDividerColor,
                    ),
                    itemBuilder: (context, index) {
                      final option = suggestions[index];
                      return ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: 48,
                          maxHeight: 48,
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          leading: const Icon(Icons.location_on,
                              color: Color(0xffcc2f25), size: 20),
                          title: Text(
                            option.description ?? '',
                            style: widget.suggestionTextStyle ??
                                const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          onTap: () => _onSuggestionSelected(option),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _onSuggestionSelected(PlaceResponse placeResponse) async {
    _isSelectingPlace = true;
    _suggestions.value = [];

    try {
      final placeDetails = await _googleApi.getPlaceDetails(
        placeId: placeResponse.place_id,
        sessionToken: pickUpDateSessionToken,
      );

      if (placeDetails.result == null) return;

      final point = Point(
        placeDetails.result!.geometry!.location!.lng,
        placeDetails.result!.geometry!.location!.lat,
      );

      pickUpLocation = Place.newInstance(
        placeResponse.description ?? '',
        point.x,
        point.y,
      );

      pickUpDateSessionToken = const Uuid().v4();

      String getComponent(String type) =>
          placeDetails.result!.address_components
              ?.firstWhereOrNull(
                  (e) => e.types != null && e.types!.contains(type))
              ?.longName ??
              '';

      final streetNumber = getComponent('street_number');
      final streetAddress = getComponent('route');
      final suburb = getComponent('sublocality_level_1');
      final city = getComponent('locality');
      final province = getComponent('administrative_area_level_1');
      final country = getComponent('country');
      final postalCode = getComponent('postal_code');

      final address = [
        streetNumber,
        streetAddress,
        suburb,
        city,
        province,
        country,
        postalCode,
      ].where((e) => e.isNotEmpty).join(', ');

      widget.controller.text = address;
      widget.controller.selection =
          TextSelection.collapsed(offset: address.length);

      selectedLocation = Place(
        address: address,
        code: int.tryParse(postalCode),
        latitude: pickUpLocation?.latitude,
        longitude: pickUpLocation?.longitude,
        city: city,
        province: province,
        suburb: suburb,
        country: country,
        streetAddress: streetAddress,
        streetNumber: streetNumber,
      );

      widget.onPlaceSelected(selectedLocation!);
      _focusNode.unfocus();
    } catch (_) {
      setState(() => _networkError = true);
    } finally {
      await Future.delayed(const Duration(milliseconds: 300));
      _isSelectingPlace = false;
    }
  }
}
