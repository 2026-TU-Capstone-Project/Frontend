// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CursorPagination<T> _$CursorPaginationFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => CursorPagination<T>(
  items: (json['items'] as List<dynamic>).map(fromJsonT).toList(),
  nextCursor: json['nextCursor'] as String?,
  hasMore: json['hasMore'] as bool,
);

Map<String, dynamic> _$CursorPaginationToJson<T>(
  CursorPagination<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'items': instance.items.map(toJsonT).toList(),
  'nextCursor': instance.nextCursor,
  'hasMore': instance.hasMore,
};

FollowResponse _$FollowResponseFromJson(Map<String, dynamic> json) =>
    FollowResponse(
      followId: (json['followId'] as num?)?.toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      username: json['username'] as String?,
      nickname: json['nickname'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
    );

Map<String, dynamic> _$FollowResponseToJson(FollowResponse instance) =>
    <String, dynamic>{
      'followId': instance.followId,
      'userId': instance.userId,
      'username': instance.username,
      'nickname': instance.nickname,
      'profileImageUrl': instance.profileImageUrl,
    };

FollowRequestResponse _$FollowRequestResponseFromJson(
  Map<String, dynamic> json,
) => FollowRequestResponse(
  followId: (json['followId'] as num?)?.toInt(),
  requesterId: (json['requesterId'] as num?)?.toInt(),
  username: json['username'] as String?,
  nickname: json['nickname'] as String?,
  profileImageUrl: json['profileImageUrl'] as String?,
  requestedAt: json['requestedAt'] as String?,
);

Map<String, dynamic> _$FollowRequestResponseToJson(
  FollowRequestResponse instance,
) => <String, dynamic>{
  'followId': instance.followId,
  'requesterId': instance.requesterId,
  'username': instance.username,
  'nickname': instance.nickname,
  'profileImageUrl': instance.profileImageUrl,
  'requestedAt': instance.requestedAt,
};
