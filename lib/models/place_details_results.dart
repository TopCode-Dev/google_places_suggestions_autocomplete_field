
import 'place_details.dart';

class PlaceDetailsResult{
  String? status;
  PlaceDetails? result;

  PlaceDetailsResult(this.status, this.result);

  PlaceDetailsResult.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    result = json.containsKey('result') && json['result'] != null
        ? PlaceDetails.fromJson(json['result'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (status != null) {
      data['status'] = status;
    }
    if (result != null) {
      data['result'] = result?.toJson();
    }

    return data;
  }
}