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
  String? source;
  DateTime? createdAt;
  int favoriteCount = 0;
  double? avgRating;
  int ratingVotesCount = 0;
  List<PointService> services = [];
  List<PointReview> reviews = [];

  /// URL pubblici delle immagini (max 3), ordine = carosello.
  List<String> imageUrls = [];

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
    pointview.source = json['source']?.toString();
    final createdAtRaw = json['created_at']?.toString();
    if (createdAtRaw != null && createdAtRaw.isNotEmpty) {
      pointview.createdAt = DateTime.tryParse(createdAtRaw);
    }
    final fav = json['favorite_count'];
    if (fav is num) pointview.favoriteCount = fav.toInt();
    final avg = json['avg_rating'];
    if (avg is num) pointview.avgRating = avg.toDouble();
    final votes = json['rating_votes_count'];
    if (votes is num) pointview.ratingVotesCount = votes.toInt();

    final rawImages = json['image_urls'];
    if (rawImages is List) {
      pointview.imageUrls = rawImages
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    final rawServices = json['point_view_services'];
    if (rawServices is List) {
      pointview.services = rawServices
          .whereType<Map<String, dynamic>>()
          .map(PointService.fromPointJoinJson)
          .toList();
    }
    final rawReviews = json['point_reviews'];
    if (rawReviews is List) {
      pointview.reviews = rawReviews
          .whereType<Map<String, dynamic>>()
          .map(PointReview.fromJson)
          .toList();
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
      'image_urls': imageUrls,
    };
  }
}

class PointService {
  PointService({
    required this.slug,
    required this.name,
    required this.icon,
    required this.status,
  });

  final String slug;
  final String name;
  final String icon;
  final String status;

  factory PointService.fromPointJoinJson(Map<String, dynamic> json) {
    final catalogRaw = json['point_services_catalog'];
    Map<String, dynamic> catalog = {};
    if (catalogRaw is List &&
        catalogRaw.isNotEmpty &&
        catalogRaw.first is Map) {
      catalog = (catalogRaw.first as Map).cast<String, dynamic>();
    } else if (catalogRaw is Map) {
      catalog = catalogRaw.cast<String, dynamic>();
    }
    return PointService(
      slug: catalog['slug']?.toString() ?? '',
      name: catalog['name']?.toString() ?? '',
      icon: catalog['icon']?.toString() ?? 'misc',
      status: json['status']?.toString() ?? 'active',
    );
  }
}

class PointReview {
  PointReview({
    required this.id,
    required this.userId,
    required this.rating,
    this.reviewText,
    required this.createdAt,
  });

  final int id;
  final String userId;
  final int rating;
  final String? reviewText;
  final DateTime? createdAt;

  factory PointReview.fromJson(Map<String, dynamic> json) {
    return PointReview(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: json['user_id']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      reviewText: json['review_text']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

class NearbyAmenity {
  NearbyAmenity({
    required this.name,
    required this.kind,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
  });

  final String name;
  final String kind;
  final double latitude;
  final double longitude;
  final double distanceMeters;
}
