import 'package:capstone_fe/common/const/data.dart';
import 'package:flutter/material.dart';

class SingleFeedcard extends StatelessWidget {
  final SingleFeedModel model;

  const SingleFeedcard({
    required this.model,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Material + InkWell 패턴: 터치 시 물결 효과를 주기 위한 실무 표준 패턴
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16.0),
      elevation: 0, // 그림자는 이미지가 복잡하므로 제거하거나 최소화
      child: InkWell(
        onTap: () {
          // TODO: 상세 페이지 이동
          print('Card Tapped: ${model.title}');
        },
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            // 이미지가 로딩되기 전 배경색
            color: Colors.grey[200],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: Stack(
              children: [
                // 1. 배경 이미지
                Positioned.fill(
                  child: Image.asset(
                    model.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),

                // 2. 그라데이션 오버레이 (텍스트 가독성용)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.5, 1.0], // 이미지 중간부터 어두워지기 시작
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. 텍스트 정보
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        model.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.0,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        maxLines: 2, // 두 줄까지 허용
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        children: [
                          const Icon(
                              Icons.favorite,
                              size: 14,
                              color: Color(0xFFFF5F6D) // 브랜드 컬러 포인트
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${model.likeCount}',
                            style: const TextStyle(
                              fontSize: 13.0,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}