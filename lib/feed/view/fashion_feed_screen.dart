import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart'; // 패키지 import
import '../model/feed_model.dart';
import '../component/feed_card.dart';
import 'feed_detail_screen.dart'; // 상세 페이지 import

class FashionFeedScreen extends StatelessWidget {
  const FashionFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(width: 16),
                            Icon(Icons.search, color: Colors.grey),
                            SizedBox(width: 8),
                            Text("스타일 검색", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.notifications_none, size: 28),
                  ],
                ),
              ),


              Expanded(
                child: MasonryGridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  itemCount: dummyFeeds.length,
                  itemBuilder: (context, index) {
                    final feed = dummyFeeds[index];


                    final double aspectRatio = index.isEven ? 0.7 : 0.85;

                    return FeedCard(
                      feed: feed,
                      aspectRatio: aspectRatio,
                      onTap: () {

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FeedDetailScreen(feed: feed),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}