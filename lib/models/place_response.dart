class PlaceResponse {
  String? description;
  String? id;
  String? place_id;

  PlaceResponse({this.description, this.id, this.place_id});

  PlaceResponse.fromJson(Map<String, dynamic> json) {
    description = json['description'];
    id = json['id'];
    place_id = json['place_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (description != null) {
      data['description'] = description;
    }
    if (id != null) {
      data['id'] = id;
    }
    if (place_id != null) {
      data['place_id'] = place_id;
    }

    return data;
  }
}