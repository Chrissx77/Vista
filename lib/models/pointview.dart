class Pointview {
  int? id;
  String? name;
  String? region;
  String? city;
  String? description;
  double? latitude;
  double? longitude;
  String? createdBy;
  String? creatorDisplayName;

  Pointview();

  factory Pointview.fromJson(Map<String, dynamic> json) {
    var pointview = Pointview();
    final rawId = json['id'];
    if (rawId is int) {
      pointview.id = rawId;
    } else if (rawId is num) {
      pointview.id = rawId.toInt();
    }
    pointview.name = json['name']?.toString();
    pointview.region = json['region']?.toString();
    pointview.city = json['city']?.toString();
    pointview.description = json['description']?.toString();
    final lat = json['latitude'];
    if (lat is num) pointview.latitude = lat.toDouble();
    final lng = json['longitude'];
    if (lng is num) pointview.longitude = lng.toDouble();
    final cb = json['created_by'];
    if (cb != null) pointview.createdBy = cb.toString();
    final cdn = json['creator_display_name'];
    if (cdn != null) {
      pointview.creatorDisplayName = cdn.toString();
    }

    return pointview;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'region': region,
      'city': city,
      if (description != null) 'description': description,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}
