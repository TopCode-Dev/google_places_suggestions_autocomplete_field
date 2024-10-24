import 'place_response.dart';
class PlacesPredictions {
  String? status;
  List<PlaceResponse>? predictions;

  PlacesPredictions({this.status, this.predictions});

  PlacesPredictions.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    predictions = json.containsKey('predictions') && json['predictions'] != null
        ? (json['predictions'] as List).map((data) => PlaceResponse.fromJson(data)).toList(): null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (status != null) {
      data['status'] = status;
    }
    if (predictions != null) {
      data['predictions'] = predictions?.map((data) => data.toJson()).toList();
    }

    return data;
  }
}