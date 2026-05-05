// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeedListResponseDto _$FeedListResponseDtoFromJson(Map<String, dynamic> json) =>
    FeedListResponseDto(
      feedId: (json['feedId'] as num).toInt(),
      feedTitle: json['feedTitle'] as String,
      styleImageUrl: json['styleImageUrl'] as String,
      authorNickname: json['authorNickname'] as String?,
      authorProfileImageUrl: json['authorProfileImageUrl'] as String?,
      likeCount: (json['likeCount'] as num?)?.toInt(),
      visibility: json['visibility'] as String?,
      liked: json['liked'] as bool?,
    );

Map<String, dynamic> _$FeedListResponseDtoToJson(
  FeedListResponseDto instance,
) => <String, dynamic>{
  'feedId': instance.feedId,
  'feedTitle': instance.feedTitle,
  'styleImageUrl': instance.styleImageUrl,
  'authorNickname': instance.authorNickname,
  'authorProfileImageUrl': instance.authorProfileImageUrl,
  'likeCount': instance.likeCount,
  'visibility': instance.visibility,
  'liked': instance.liked,
};

PageFeedListResponseDto _$PageFeedListResponseDtoFromJson(
  Map<String, dynamic> json,
) => PageFeedListResponseDto(
  content: (json['content'] as List<dynamic>)
      .map((e) => FeedListResponseDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalPages: (json['totalPages'] as num).toInt(),
  totalElements: (json['totalElements'] as num).toInt(),
  size: (json['size'] as num).toInt(),
  number: (json['number'] as num).toInt(),
  numberOfElements: (json['numberOfElements'] as num).toInt(),
  first: json['first'] as bool,
  last: json['last'] as bool,
  empty: json['empty'] as bool,
  pageable: json['pageable'] == null
      ? null
      : PageableObject.fromJson(json['pageable'] as Map<String, dynamic>),
  sort: json['sort'] == null
      ? null
      : SortObject.fromJson(json['sort'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PageFeedListResponseDtoToJson(
  PageFeedListResponseDto instance,
) => <String, dynamic>{
  'content': instance.content,
  'totalPages': instance.totalPages,
  'totalElements': instance.totalElements,
  'size': instance.size,
  'number': instance.number,
  'numberOfElements': instance.numberOfElements,
  'first': instance.first,
  'last': instance.last,
  'empty': instance.empty,
  'pageable': instance.pageable,
  'sort': instance.sort,
};

PageableObject _$PageableObjectFromJson(Map<String, dynamic> json) =>
    PageableObject(
      offset: (json['offset'] as num?)?.toInt(),
      pageNumber: (json['pageNumber'] as num?)?.toInt(),
      pageSize: (json['pageSize'] as num?)?.toInt(),
      paged: json['paged'] as bool?,
      unpaged: json['unpaged'] as bool?,
      sort: json['sort'] == null
          ? null
          : SortObject.fromJson(json['sort'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PageableObjectToJson(PageableObject instance) =>
    <String, dynamic>{
      'offset': instance.offset,
      'pageNumber': instance.pageNumber,
      'pageSize': instance.pageSize,
      'paged': instance.paged,
      'unpaged': instance.unpaged,
      'sort': instance.sort,
    };

SortObject _$SortObjectFromJson(Map<String, dynamic> json) => SortObject(
  empty: json['empty'] as bool?,
  sorted: json['sorted'] as bool?,
  unsorted: json['unsorted'] as bool?,
);

Map<String, dynamic> _$SortObjectToJson(SortObject instance) =>
    <String, dynamic>{
      'empty': instance.empty,
      'sorted': instance.sorted,
      'unsorted': instance.unsorted,
    };

FeedDetailResponseDto _$FeedDetailResponseDtoFromJson(
  Map<String, dynamic> json,
) => FeedDetailResponseDto(
  authorId: (json['authorId'] as num).toInt(),
  authorNickname: json['authorNickname'] as String,
  authorProfileImageUrl: json['authorProfileImageUrl'] as String?,
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
  likeCount: (json['likeCount'] as num?)?.toInt(),
  liked: json['liked'] as bool?,
);

Map<String, dynamic> _$FeedDetailResponseDtoToJson(
  FeedDetailResponseDto instance,
) => <String, dynamic>{
  'authorId': instance.authorId,
  'authorNickname': instance.authorNickname,
  'authorProfileImageUrl': instance.authorProfileImageUrl,
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
  'likeCount': instance.likeCount,
  'liked': instance.liked,
};

FeedPreviewResponseDto _$FeedPreviewResponseDtoFromJson(
  Map<String, dynamic> json,
) => FeedPreviewResponseDto(
  styleImageUrl: json['styleImageUrl'] as String,
  topImageUrl: json['topImageUrl'] as String?,
  topName: json['topName'] as String?,
  bottomImageUrl: json['bottomImageUrl'] as String?,
  bottomName: json['bottomName'] as String?,
);

Map<String, dynamic> _$FeedPreviewResponseDtoToJson(
  FeedPreviewResponseDto instance,
) => <String, dynamic>{
  'styleImageUrl': instance.styleImageUrl,
  'topImageUrl': instance.topImageUrl,
  'topName': instance.topName,
  'bottomImageUrl': instance.bottomImageUrl,
  'bottomName': instance.bottomName,
};
