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
  _GooglePlacesSuggestionsAutoCompleteFieldState createState() =>
      _GooglePlacesSuggestionsAutoCompleteFieldState();
}

class _GooglePlacesSuggestionsAutoCompleteFieldState
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
    pickUpDateSessionToken = Uuid().v4().toString();

    // ✅ WORKING LOGIC: Controller listener for both keyboards
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
        debugPrint("🔍 Found ${results?.length ?? 0} suggestions for '$text'");
        _suggestions.value = results ?? [];
        _networkError = false;
      } catch (error) {
        debugPrint("🔍 Search error: $error");
        _suggestions.value = [];
        _networkError = true;
      }
    });
  }

  static String _displayStringForOption(PlaceResponse option) => option.description ?? "";

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ EXACT Autocomplete TextFormField styling
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          decoration: widget.decoration?.copyWith(
            errorText: _networkError ? 'Network error, please try again.' : null,
          ) ?? InputDecoration(
            hintText: widget.hint,
            labelText: widget.hint,
            icon: Icon(Icons.location_on, color: const Color(0xffcc2f25)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.7), width: 2.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.7), width: 2.0),
            ),
          ),
          onTap: () {
            debugPrint('📱 Field tapped');
            widget.onTapField?.call(widget.controller, _focusNode);
          },
        ),
        // ✅ EXACT Autocomplete ListTile UI - FIXED RENDERFLEX
        ValueListenableBuilder<List<PlaceResponse>>(
          valueListenable: _suggestions,
          builder: (context, suggestions, child) {
            if (suggestions.isEmpty) return const SizedBox.shrink();

            debugPrint('🎨 Rendering ${suggestions.length} suggestions');

            // Calculate max height based on number of suggestions
            final maxItemHeight = 48.0; // Approximate height per item
            final separatorHeight = 1.0;
            final totalHeight = (suggestions.length * maxItemHeight) +
                ((suggestions.length - 1) * separatorHeight);
            final maxAllowedHeight = MediaQuery.of(context).size.height * 0.4; // Max 40% of screen

            return ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                maxHeight: totalHeight > maxAllowedHeight ? maxAllowedHeight : totalHeight,
                minWidth: 400, // Match your TextField width
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
                        constraints: BoxConstraints(
                          minHeight: maxItemHeight,
                          maxHeight: maxItemHeight,
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          leading: Icon(Icons.location_on,
                              color: const Color(0xffcc2f25), size: 20),
                          title: Text(
                            option.description ?? '',
                            style: widget.suggestionTextStyle ?? const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          onTap: () {
                            debugPrint('👆 TAPPED: ${option.description}');
                            _onSuggestionSelected(option);
                          },
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
    debugPrint('🎯 SUGGESTION SELECTED: ${placeResponse.description}');
    _suggestions.value = []; // Hide suggestions

    try {
      final placeDetails = await _googleApi.getPlaceDetails(
        placeId: placeResponse.place_id,
        sessionToken: pickUpDateSessionToken,
      );

      if (placeDetails.result != null) {
        Point point = Point(
          placeDetails.result?.geometry?.location?.lng ?? -1,
          placeDetails.result?.geometry?.location?.lat ?? -1,
        );

        pickUpLocation = Place.newInstance(placeResponse.description ?? '', point.x, point.y);
        pickUpDateSessionToken = Uuid().v4().toString();

        // ✅ WORKING address parsing logic
        String? streetNumber = placeDetails.result?.address_components
            ?.firstWhereOrNull((e) => e.types!.contains("street_number"))?.longName ?? "";
        String? streetAddress = placeDetails.result?.address_components
            ?.firstWhereOrNull((e) => e.types!.contains("route"))?.longName ?? "";
        String? suburb = placeDetails.result?.address_components
            ?.firstWhereOrNull((e) => e.types!.contains("sublocality_level_1"))?.longName ?? "";
        String? city = placeDetails.result?.address_components
            ?.firstWhereOrNull((e) => e.types!.contains("locality"))?.longName ?? "";
        String? province = placeDetails.result?.address_components
            ?.firstWhereOrNull((e) => e.types!.contains("administrative_area_level_1"))?.longName ?? "";
        String? country = placeDetails.result?.address_components
            ?.firstWhereOrNull((e) => e.types!.contains("country"))?.longName ?? "";
        String? postalCode = placeDetails.result?.address_components
            ?.firstWhereOrNull((e) => e.types!.contains("postal_code"))?.longName ?? "";

        String address = [
          if (streetNumber.isNotEmpty) streetNumber,
          if (streetAddress.isNotEmpty) streetAddress,
          if (suburb.isNotEmpty) suburb,
          if (city.isNotEmpty) city,
          if (province.isNotEmpty) province,
          if (country.isNotEmpty) country,
          if (postalCode.isNotEmpty) postalCode,
        ].where((e) => e.isNotEmpty).join(', ');

        // Update controller
        widget.controller.text = address;
        widget.controller.selection = TextSelection.fromPosition(
          TextPosition(offset: address.length),
        );

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
      }
    } catch (error, stackTrace) {
      debugPrint("❌ Error fetching place details: $error");
      debugPrintStack(stackTrace: stackTrace, label: "Google getPlaceDetails");
      setState(() => _networkError = true);
    } finally {
      await Future.delayed(const Duration(milliseconds: 300));
      _isSelectingPlace = false;
    }
  }
}