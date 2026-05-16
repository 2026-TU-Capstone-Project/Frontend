import 'package:json_annotation/json_annotation.dart';

part 'follow_model.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class CursorPagination<T> {
  final List<T> items;
  final String? nextCursor;
  final bool hasMore;

  const CursorPagination({
    required this.items,
    this.nextCursor,
    required this.hasMore,
  });

  static const empty = CursorPagination<Never>(items: [], hasMore: false);

  factory CursorPagination.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$CursorPaginationFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$CursorPaginationToJson(this, toJsonT);
}

@JsonSerializable()
class FollowResponse {
  final int? followId;
  final int? userId;
  final String? username;
  final String? nickname;
  final String? profileImageUrl;

  FollowResponse({
    this.followId,
    this.userId,
    this.username,
    this.nickname,
    this.profileImageUrl,
  });

  factory FollowResponse.fromJson(Map<String, dynamic> json) =>
      _$FollowResponseFromJson(json);
  Map<String, dynamic> toJson() => _$FollowResponseToJson(this);
}

@JsonSerializable()
class FollowRequestResponse {
  final int? followId;
  final int? requesterId;
  final String? username;
  final String? nickname;
  final String? profileImageUrl;
  final String? requestedAt;

  FollowRequestResponse({
    this.followId,
    this.requesterId,
    this.username,
    this.nickname,
    this.profileImageUrl,
    this.requestedAt,
  });

  factory FollowRequestResponse.fromJson(Map<String, dynamic> json) =>
      _$FollowRequestResponseFromJson(json);
  Map<String, dynamic> toJson() => _$FollowRequestResponseToJson(this);
}
