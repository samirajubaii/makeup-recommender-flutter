class RecommendationItem {
  final String? productId;
  final String? shadeId;
  final String? shadeName;

  RecommendationItem({this.productId, this.shadeId, this.shadeName});

  factory RecommendationItem.fromJson(Map<String, dynamic> json) => RecommendationItem(
    productId: json["productId"],
    shadeId: json["shadeId"],
    shadeName: json["shadeName"],
  );
}

class FaceRecommendation {
  final String? skinTone;
  final String? undertone;
  final RecommendationItem? foundation;
  final RecommendationItem? concealer;

  FaceRecommendation({this.skinTone, this.undertone, this.foundation, this.concealer});

  factory FaceRecommendation.fromJson(Map<String, dynamic> json) => FaceRecommendation(
    skinTone: json["skinTone"],
    undertone: json["undertone"],
    foundation: json["foundation"] == null ? null : RecommendationItem.fromJson(json["foundation"]),
    concealer: json["concealer"] == null ? null : RecommendationItem.fromJson(json["concealer"]),
  );
}
