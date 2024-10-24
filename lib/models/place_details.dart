import 'geometry.dart';
import 'location_piece.dart';

class PlaceDetails {
  String? formatted_address;
  Geometry? geometry;
  String? place_id;
  List<LocationPiece>? address_components;

  PlaceDetails(this.formatted_address, this.geometry, this.place_id);

  PlaceDetails.fromJson(Map<String, dynamic> json) {
    formatted_address = json['formatted_address'];
    geometry = json.containsKey('geometry') && json['geometry'] != null
        ? Geometry.fromJson(json['geometry'])
        : null;
    place_id = json['place_id'];
    address_components = json.containsKey('address_components') && json['address_components'] != null
        ? (json['address_components'] as List)
        .map((data) => LocationPiece.fromJson(data))
        .toList()
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (formatted_address != null) {
      data['formatted_address'] = formatted_address;
    }
    if (geometry != null) {
      data['geometry'] = geometry?.toJson();
    }
    if (place_id != null) {
      data['place_id'] = place_id;
    }
    if (address_components != null) {
      data['address_components'] = address_components?.map((e) => e.toJson()).toList();
    }

    return data;
  }
}