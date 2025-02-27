

class Place{
  String? address;
  String? city;
  int? code;
  String? country;
  double? latitude;
  double? longitude;
  String? province;
  String? suburb;
  String? streetNumber;
  String? streetAddress;

  Place({this.address,this.code, this.country,this.city,this.province,this.suburb, this.latitude, this.longitude, this.streetAddress, this.streetNumber});


  Place.newInstance(this.address, this.longitude, this.latitude);

  Place.fromJson(Map<String, dynamic> json) {
    address = json['address'];
    city = json['city'];
    code = json['code'];
    country = json['country'];
    province = json['province'];
    suburb = json['suburb'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    streetNumber = json['streetNumber'];
    streetAddress = json['streetAddress'];

  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (address != null) {
      data['address'] = address;
    }
    if (city != null) {
      data['city'] = city;
    }
    if (code != null) {
      data['code'] = code;
    }
    if (country != null) {
      data['country'] = country;
    }
    if (longitude != null) {
      data['longitude'] = longitude;
    }
    if (latitude != null) {
      data['latitude'] = latitude;
    }
    if (province != null) {
      data['province'] = province;
    }
    if (suburb != null) {
      data['suburb'] = suburb;
    }
    if (streetNumber != null) {
      data['streetNumber'] = streetNumber;
    }
    if (streetAddress != null) {
      data['streetAddress'] = streetAddress;
    }
    return data;
  }

}