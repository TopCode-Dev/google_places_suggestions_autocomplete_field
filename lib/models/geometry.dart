import 'location.dart';

class Geometry {
  Location? location;

  Geometry(this.location,);

  Geometry.fromJson(Map<String, dynamic> json) {
    location = json.containsKey('location') && json['location'] != null
        ? Location.fromJson(json['location'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (location != null) {
      data['location'] = location?.toJson();
    }

    return data;
  }
}