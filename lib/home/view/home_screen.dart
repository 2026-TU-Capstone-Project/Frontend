import 'package:capstone_fe/home/component/category_selector.dart';
import 'package:capstone_fe/home/component/weather_card.dart';
import 'package:capstone_fe/home/component/single_feedCard.dart';
import 'package:flutter/material.dart';

import '../../common/const/data.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [

            WeatherCard(
                weatherIcon: Image.asset('asset/img/sun.png'),
                temp: 18,
                region: '서울',
                weather: '맑음',
                guideText: '오늘은 가벼운 아우터만 입어도 괜찮아요! ☁️\n점심시간엔 따뜻하니 얇은 가디건 추천드려요.'),

            const SizedBox(height: 20),


            const CategorySelector(),

            const SizedBox(height: 20),

            Row(
              children: [

                SizedBox(
                    width: 24,
                    height: 24,
                    child: Image.asset('asset/img/fire.png')
                ),
                const SizedBox(width: 8),
                const Text(
                  '오늘의 추천 코디',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700
                  ),
                )
              ],
            ),

            const SizedBox(height: 16),


            GridView.builder(

              shrinkWrap: true,

              physics: const NeverScrollableScrollPhysics(),

              itemCount: dummyFeeds.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16.0,
                crossAxisSpacing: 16.0,
                childAspectRatio: 0.5,
              ),
              itemBuilder: (context, index) {
                return SingleFeedcard(model: dummyFeeds[index]);
              },
            ),
          ],
        ),
      ),
    );
  }
}