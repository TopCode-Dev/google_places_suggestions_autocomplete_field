class Location {
  double? lat;
  double? lng;

  Location(this.lat, this.lng);

  Location.fromJson(Map<String, dynamic> json) {
    lat = json['lat'];
    lng = json['lng'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (lat != null) {
      data['lat'] = lat;
    }
    if (lng != null) {
      data['lng'] = lng;
    }

    return data;
  }
}