// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  userId: (json['userId'] as num?)?.toInt(),
  email: json['email'] as String?,
  username: json['username'] as String?,
  nickname: json['nickname'] as String?,
  profileImageUrl: json['profileImageUrl'] as String?,
  height: (json['height'] as num?)?.toDouble(),
  weight: (json['weight'] as num?)?.toDouble(),
  gender: json['gender'] as String?,
  followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
  followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'userId': instance.userId,
  'email': instance.email,
  'username': instance.username,
  'nickname': instance.nickname,
  'profileImageUrl': instance.profileImageUrl,
  'height': instance.height,
  'weight': instance.weight,
  'gender': instance.gender,
  'followerCount': instance.followerCount,
  'followingCount': instance.followingCount,
};

PublicUserInfo _$PublicUserInfoFromJson(Map<String, dynamic> json) =>
    PublicUserInfo(
      userId: (json['userId'] as num?)?.toInt(),
      username: json['username'] as String?,
      nickname: json['nickname'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
      followStatus: json['followStatus'] as String?,
      followsMeBack: json['followsMeBack'] as bool?,
      me: json['me'] as bool?,
    );

Map<String, dynamic> _$PublicUserInfoToJson(PublicUserInfo instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'username': instance.username,
      'nickname': instance.nickname,
      'profileImageUrl': instance.profileImageUrl,
      'followerCount': instance.followerCount,
      'followingCount': instance.followingCount,
      'followStatus': instance.followStatus,
      'followsMeBack': instance.followsMeBack,
      'me': instance.me,
    };

UserSearchItem _$UserSearchItemFromJson(Map<String, dynamic> json) =>
    UserSearchItem(
      userId: (json['userId'] as num?)?.toInt(),
      username: json['username'] as String?,
      nickname: json['nickname'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      followStatus: json['followStatus'] as String?,
    );

Map<String, dynamic> _$UserSearchItemToJson(UserSearchItem instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'username': instance.username,
      'nickname': instance.nickname,
      'profileImageUrl': instance.profileImageUrl,
      'followStatus': instance.followStatus,
    };
