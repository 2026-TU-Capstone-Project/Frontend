import 'package:flutter/material.dart';
import '../model/feed_model.dart';

// 간단한 댓글 모델 (내부 사용용)
class Comment {
  final String author;
  final String content;
  final String time;

  Comment({required this.author, required this.content, required this.time});
}

class FeedDetailScreen extends StatefulWidget {
  final SingleFeedModel feed;

  const FeedDetailScreen({super.key, required this.feed});

  @override
  State<FeedDetailScreen> createState() => _FeedDetailScreenState();
}

class _FeedDetailScreenState extends State<FeedDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 더미 댓글 데이터
  final List<Comment> _comments = [
    Comment(author: "패션피플", content: "와 코디 정보 좀 알 수 있을까요? ", time: "5분 전"),
    Comment(author: "지나가던 행인", content: "성수동 어디인가요? 분위기 좋네요!", time: "12분 전"),
    Comment(author: "데일리룩장인", content: "역시 믿고 보는 코디 센스 ", time: "1시간 전"),
  ];

  void _addComment() {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _comments.add(Comment(
        author: "나 (Me)", // 현재 로그인한 사용자라고 가정
        content: _commentController.text,
        time: "방금 전",
      ));
      _commentController.clear();
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });


    FocusScope.of(context).unfocus();
  }



  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [

          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Hero(
                        tag: widget.feed.title,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                          child: Image.asset(
                            widget.feed.imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),


                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.black,
                                  child: Icon(Icons.person, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(widget.feed.author,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const Text("Fashion Influencer",
                                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text("Follow", style: TextStyle(fontWeight: FontWeight.bold)),
                                )
                              ],
                            ),

                            const SizedBox(height: 24),


                            Text(
                              widget.feed.title,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "오늘의 OOTD 포인트는 빈티지와 모던의 조화입니다. 성수동 골목길에서 영감을 받아 코디해보았습니다. 편안하면서도 스타일리시한 룩을 찾으신다면 추천드려요! \n\n#데일리룩 #OOTD #패션 #코디추천",
                              style: TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
                            ),

                            const SizedBox(height: 30),


                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.redAccent.withOpacity(0.4),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4))
                                      ],
                                    ),
                                    child: const Icon(Icons.favorite, color: Colors.white, size: 32),
                                  ),
                                  const SizedBox(height: 8),
                                  Text("${widget.feed.likeCount} Likes",
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),
                            const Divider(thickness: 1, height: 40),


                            Text(
                              "댓글 ${_comments.length}개",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),


                            ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _comments.length,
                              itemBuilder: (context, index) {
                                final comment = _comments[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Colors.grey[300],
                                        child: const Icon(Icons.person, size: 20, color: Colors.white),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(comment.author,
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.bold, fontSize: 13)),
                                                const SizedBox(width: 8),
                                                Text(comment.time,
                                                    style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(comment.content, style: const TextStyle(fontSize: 14)),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.favorite_border, size: 16, color: Colors.grey),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),


                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new,
                                color: Colors.white,
                                shadows: [Shadow(color: Colors.black54, blurRadius: 10)]),
                            onPressed: () => Navigator.pop(context),
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_horiz,
                                color: Colors.white,
                                shadows: [Shadow(color: Colors.black54, blurRadius: 10)]),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),


          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.black,
                    child: Icon(Icons.person, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: "댓글 달기...",
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                          contentPadding: EdgeInsets.symmetric(vertical: 10), // 텍스트 수직 정렬
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _addComment,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text("게시", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}