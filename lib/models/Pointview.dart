class Pointview {
  int? id;
  String? name;
  String? region;
  String? city;

  Pointview();

  factory Pointview.fromJson(Map<String, dynamic> json) {
    var pointview = Pointview();
    pointview.id = json['id'];
    pointview.name = json['name'];
    pointview.region = json['region'];
    pointview.city = json['city'];

    return pointview;
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'region': region, 'city': city};
  }
}
