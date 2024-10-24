import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/place_details_results.dart';
import '../models/place_predictions.dart';

class GoogleApi {
  static const TAG = 'GoogleApi';
  static const endpoint = 'maps.googleapis.com';
  final String apiKey;

  var client = new http.Client();

  GoogleApi(this.apiKey,);

  String convertCountryListToString(String countryCodes) {
    if (countryCodes.isEmpty) return "";

    // Map the list into the required format
    String result = countryCodes.split(",").map((code) => 'country:$code').join('|');

    return result;
  }

  Future<PlacesPredictions> getAutoCompletePlaces(
      {String? sessionToken,
        String? input,
        required String types,
      required String countries}) async {
    Map<String, String> requestHeaders = {
      HttpHeaders.contentTypeHeader: "application/json",
      HttpHeaders.acceptHeader: "application/json",
    };
    Map<String, String> queryParameters = {
      'sessiontoken': "$sessionToken",
      'input': "$input",
      'key': "$apiKey",
      //'types': "$types",
      'components': "${convertCountryListToString(countries)}",
    };
    Uri uri = Uri.https(
        endpoint, "maps/api/place/autocomplete/json", queryParameters);
    final response = await client.get(uri, headers: requestHeaders);
    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 203 ||
        response.statusCode == 204) {
      return PlacesPredictions.fromJson(json.decode(response.body));
    } else if (response.body.isNotEmpty) {
      throw Exception(response.body);
    } else {
      throw Exception('${response.toString()}');
    }
  }

  Future<PlaceDetailsResult> getPlaceDetails(
      {String? sessionToken,
        String? placeId,
        String fields = "formatted_address,geometry,place_id,address_components"}) async {
    Map<String, String> requestHeaders = {
      HttpHeaders.contentTypeHeader: "application/json",
      HttpHeaders.acceptHeader: "application/json",
    };
    Map<String, String> queryParameters = {
      'sessiontoken': "$sessionToken",
      'place_id': "$placeId",
      'key': "$apiKey",
      'fields': "$fields"
    };
    Uri uri =
    Uri.https(endpoint, "maps/api/place/details/json", queryParameters);
    final response = await client.get(uri, headers: requestHeaders);
    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 203 ||
        response.statusCode == 204) {
      return PlaceDetailsResult.fromJson(json.decode(response.body));
    } else if (response.body != null) {
      throw Exception(response.body);
    } else {
      throw Exception('${response.toString()}');
    }
  }
}
