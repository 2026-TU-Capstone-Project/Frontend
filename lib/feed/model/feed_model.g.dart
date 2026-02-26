// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeedListItem _$FeedListItemFromJson(Map<String, dynamic> json) => FeedListItem(
  feedId: (json['feedId'] as num).toInt(),
  feedTitle: json['feedTitle'] as String,
  styleImageUrl: json['styleImageUrl'] as String,
);

Map<String, dynamic> _$FeedListItemToJson(FeedListItem instance) =>
    <String, dynamic>{
      'feedId': instance.feedId,
      'feedTitle': instance.feedTitle,
      'styleImageUrl': instance.styleImageUrl,
    };

FeedDetailData _$FeedDetailDataFromJson(Map<String, dynamic> json) =>
    FeedDetailData(
      authorId: (json['authorId'] as num).toInt(),
      authorNickname: json['authorNickname'] as String,
      styleImageUrl: json['styleImageUrl'] as String,
      styleImageId: (json['styleImageId'] as num).toInt(),
      topImageUrl: json['topImageUrl'] as String?,
      topName: json['topName'] as String?,
      topClothesId: (json['topClothesId'] as num?)?.toInt(),
      bottomImageUrl: json['bottomImageUrl'] as String?,
      bottomName: json['bottomName'] as String?,
      bottomClothesId: (json['bottomClothesId'] as num?)?.toInt(),
      feedTitle: json['feedTitle'] as String?,
      feedContent: json['feedContent'] as String?,
    );

Map<String, dynamic> _$FeedDetailDataToJson(FeedDetailData instance) =>
    <String, dynamic>{
      'authorId': instance.authorId,
      'authorNickname': instance.authorNickname,
      'styleImageUrl': instance.styleImageUrl,
      'styleImageId': instance.styleImageId,
      'topImageUrl': instance.topImageUrl,
      'topName': instance.topName,
      'topClothesId': instance.topClothesId,
      'bottomImageUrl': instance.bottomImageUrl,
      'bottomName': instance.bottomName,
      'bottomClothesId': instance.bottomClothesId,
      'feedTitle': instance.feedTitle,
      'feedContent': instance.feedContent,
    };

FeedPreviewData _$FeedPreviewDataFromJson(Map<String, dynamic> json) =>
    FeedPreviewData(
      styleImageUrl: json['styleImageUrl'] as String,
      topImageUrl: json['topImageUrl'] as String?,
      topName: json['topName'] as String?,
      bottomImageUrl: json['bottomImageUrl'] as String?,
      bottomName: json['bottomName'] as String?,
    );

Map<String, dynamic> _$FeedPreviewDataToJson(FeedPreviewData instance) =>
    <String, dynamic>{
      'styleImageUrl': instance.styleImageUrl,
      'topImageUrl': instance.topImageUrl,
      'topName': instance.topName,
      'bottomImageUrl': instance.bottomImageUrl,
      'bottomName': instance.bottomName,
    };
