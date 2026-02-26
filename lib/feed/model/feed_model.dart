import 'package:json_annotation/json_annotation.dart';

part 'feed_model.g.dart';

// --- API 응답 모델 (GET /api/v1/feeds, GET /api/v1/feeds/me) ---
@JsonSerializable()
class FeedListItem {
  final int feedId;
  final String feedTitle;
  final String styleImageUrl;

  FeedListItem({
    required this.feedId,
    required this.feedTitle,
    required this.styleImageUrl,
  });

  factory FeedListItem.fromJson(Map<String, dynamic> json) =>
      _$FeedListItemFromJson(json);
  Map<String, dynamic> toJson() => _$FeedListItemToJson(this);
}

// --- 피드 상세 (GET /api/v1/feeds/{feedId}) ---
@JsonSerializable()
class FeedDetailData {
  final int authorId;
  final String authorNickname;
  final String styleImageUrl;
  final int styleImageId;
  final String? topImageUrl;
  final String? topName;
  final int? topClothesId;
  final String? bottomImageUrl;
  final String? bottomName;
  final int? bottomClothesId;
  final String? feedTitle;
  final String? feedContent;

  FeedDetailData({
    required this.authorId,
    required this.authorNickname,
    required this.styleImageUrl,
    required this.styleImageId,
    this.topImageUrl,
    this.topName,
    this.topClothesId,
    this.bottomImageUrl,
    this.bottomName,
    this.bottomClothesId,
    this.feedTitle,
    this.feedContent,
  });

  factory FeedDetailData.fromJson(Map<String, dynamic> json) =>
      _$FeedDetailDataFromJson(json);
  Map<String, dynamic> toJson() => _$FeedDetailDataToJson(this);
}

// --- 피드 게시 전 미리보기 (GET /api/v1/feeds/preview/{fittingTaskId}) ---
@JsonSerializable()
class FeedPreviewData {
  final String styleImageUrl;
  final String? topImageUrl;
  final String? topName;
  final String? bottomImageUrl;
  final String? bottomName;

  FeedPreviewData({
    required this.styleImageUrl,
    this.topImageUrl,
    this.topName,
    this.bottomImageUrl,
    this.bottomName,
  });

  factory FeedPreviewData.fromJson(Map<String, dynamic> json) =>
      _$FeedPreviewDataFromJson(json);
  Map<String, dynamic> toJson() => _$FeedPreviewDataToJson(this);
}

// --- 기존 더미용 (추후 제거 가능) ---
class SingleFeedModel {
  final String title;
  final String author;
  final int likeCount;
  final String badgeType;
  final String imageUrl;

  SingleFeedModel({
    required this.title,
    required this.author,
    required this.likeCount,
    required this.badgeType,
    required this.imageUrl,
  });
}

// 테스트용 더미 데이터
final List<SingleFeedModel> dummyFeeds = [
  SingleFeedModel(
      title: '빈티지 무드 데일리룩',
      author: '패션왕 박',
      likeCount: 1829,
      badgeType: 'NEW',
      imageUrl: 'asset/img/App.jpg'),
  SingleFeedModel(
      title: '성수동 카페 투어 룩',
      author: '스타일리쉬 김',
      likeCount: 2341,
      badgeType: 'HOT',
      imageUrl: 'asset/img/App1.jpg'),
  SingleFeedModel(
      title: '미니멀리즘 코디',
      author: '미니멀 이',
      likeCount: 542,
      badgeType: 'NEW',
      imageUrl: 'asset/img/App2.jpg'),
  SingleFeedModel(
      title: '데이트 추천 룩',
      author: '러블리 최',
      likeCount: 3100,
      badgeType: 'HOT',
      imageUrl: 'asset/img/App3.jpg'),
  SingleFeedModel(
      title: '비 오는 날 코디',
      author: '레인맨',
      likeCount: 890,
      badgeType: 'NEW',
      imageUrl: 'asset/img/App4.jpg'),
  SingleFeedModel(
      title: '캠퍼스 개강 룩',
      author: '새내기',
      likeCount: 1200,
      badgeType: 'HOT',
      imageUrl: 'asset/img/App5.jpg'),
  SingleFeedModel(
      title: '강남 데이트 룩',
      author: '코디',
      likeCount: 1200,
      badgeType: 'HOT',
      imageUrl: 'asset/img/App6.jpg'),
  SingleFeedModel(
      title: '도서관 룩',
      author: '새내기',
      likeCount: 140,
      badgeType: 'HOT',
      imageUrl: 'asset/img/App7.jpg'),
];