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

const ip = 'lookpick.kro.kr';

// http 프로토콜 포함
const baseUrl = 'https://$ip';

/// 소셜 로그인: 서버 OAuth2 진입 URL (브라우저로 열기 → 로그인 후 redirect_url?key= 임시키로 앱 복귀)
const String oauth2GoogleUrl = 'https://$ip/oauth2/authorization/google';
const String oauth2KakaoUrl = 'https://$ip/oauth2/authorization/kakao';

/// 서버가 리다이렉트할 딥링크 스킴. redirect_url = lookpick://auth → 리다이렉트 시 lookpick://auth?key=UUID
/// iOS Info.plist, Android intent-filter에 이 스킴 등록 필요.
const String deepLinkScheme = 'lookpick';
const String deepLinkHost = 'auth';


final List<SingleFeedModel> dummyFeeds = [
  SingleFeedModel(
    title: '빈티지 무드 데일리룩',
    author: '패션왕 박',
    likeCount: 1829,
    badgeType: 'NEW',
    imageUrl: 'asset/img/App.jpg'
  ),
  SingleFeedModel(
    title: '성수동 카페 투어 룩',
    author: '스타일리쉬 김',
    likeCount: 2341,
    badgeType: 'HOT',
    imageUrl:'asset/img/App1.jpg'
  ),
  SingleFeedModel(
    title: '미니멀리즘 코디',
    author: '미니멀 이',
    likeCount: 542,
    badgeType: 'NEW',
    imageUrl:'asset/img/App2.jpg'
  ),
  SingleFeedModel(
    title: '데이트 추천 룩',
    author: '러블리 최',
    likeCount: 3100,
    badgeType: 'HOT',
    imageUrl:'asset/img/App3.jpg'
  ),
  SingleFeedModel(
    title: '비 오는 날 코디',
    author: '레인맨',
    likeCount: 890,
    badgeType: 'NEW',
    imageUrl:'asset/img/App4.jpg'
  ),
  SingleFeedModel(
    title: '캠퍼스 개강 룩',
    author: '새내기',
    likeCount: 1200,
    badgeType: 'HOT',
    imageUrl:'asset/img/App5.jpg'
  ),
  SingleFeedModel(
      title: '강남 데이트 룩',
      author: '코디',
      likeCount: 1200,
      badgeType: 'HOT',
      imageUrl:'asset/img/App6.jpg'
  ),
  SingleFeedModel(
      title: '캠퍼스 개강 룩',
      author: '새내기',
      likeCount: 140,
      badgeType: 'HOT',
      imageUrl:'asset/img/App7.jpg'
  ),
];