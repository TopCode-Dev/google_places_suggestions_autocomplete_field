class Point{
  double? x;
  double? y;
  Point(this.x,this.y);

  Point.fromJson(Map<String, dynamic> json) {
    x = double.tryParse(json['x'].toString()) ?? 0.00;
    y = double.tryParse(json['y'].toString()) ?? 0.00;
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (x != null) {
      data['x'] = x;
    }
    if (y != null) {
      data['y'] = y;
    }
    return data;
  }

}