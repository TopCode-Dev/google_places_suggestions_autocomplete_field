class LocationPiece {
  String? longName;
  String? shortName;
  List<String>? types;

  LocationPiece({this.shortName, this.longName,  this.types});

  LocationPiece.fromJson(Map<String, dynamic> json) {
    longName = json['long_name'];
    shortName = json['short_name'];
    types = json['types'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['long_name'] = longName;
    data['short_name'] = shortName;
    data['types'] = types;
    return data;
  }
}
