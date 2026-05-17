import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

/// GET /api/v1/users/me 응답 데이터 (UserProfileResponseDto)
@JsonSerializable()
class UserModel {
  final int? userId;
  final String? email;
  final String? username;
  final String? nickname;
  final String? profileImageUrl;
  final double? height;
  final double? weight;
  final String? gender;
  @JsonKey(defaultValue: 0)
  final int followerCount;
  @JsonKey(defaultValue: 0)
  final int followingCount;

  UserModel({
    this.userId,
    this.email,
    this.username,
    this.nickname,
    this.profileImageUrl,
    this.height,
    this.weight,
    this.gender,
    this.followerCount = 0,
    this.followingCount = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}

/// GET /api/v1/users/{userId} 응답 데이터 (UserPublicProfileResponseDto)
@JsonSerializable()
class PublicUserInfo {
  final int? userId;
  final String? username;
  final String? nickname;
  final String? profileImageUrl;
  @JsonKey(defaultValue: 0)
  final int followerCount;
  @JsonKey(defaultValue: 0)
  final int followingCount;
  final String? followStatus;
  final bool? followsMeBack;
  final bool? me;

  PublicUserInfo({
    this.userId,
    this.username,
    this.nickname,
    this.profileImageUrl,
    this.followerCount = 0,
    this.followingCount = 0,
    this.followStatus,
    this.followsMeBack,
    this.me,
  });

  factory PublicUserInfo.fromJson(Map<String, dynamic> json) =>
      _$PublicUserInfoFromJson(json);
  Map<String, dynamic> toJson() => _$PublicUserInfoToJson(this);

  bool get isFollowing => followStatus == 'ACCEPTED';
  bool get isRequested => followStatus == 'PENDING';
}

/// GET /api/v1/users/search 응답 item (UserSearchResponseDto)
@JsonSerializable()
class UserSearchItem {
  final int? userId;
  final String? username;
  final String? nickname;
  final String? profileImageUrl;
  final String? followStatus;

  UserSearchItem({
    this.userId,
    this.username,
    this.nickname,
    this.profileImageUrl,
    this.followStatus,
  });

  factory UserSearchItem.fromJson(Map<String, dynamic> json) =>
      _$UserSearchItemFromJson(json);
  Map<String, dynamic> toJson() => _$UserSearchItemToJson(this);
}
