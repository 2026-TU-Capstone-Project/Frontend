import 'package:capstone_fe/home/component/category_selector.dart';
import 'package:capstone_fe/home/component/weather_card.dart';
import 'package:flutter/material.dart';

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
                  weahterIcon: Image.asset('asset/img/sun.png'),
                  temp:18,
                  region: '서울',
                  weather: '맑음',
                  guideText: '오늘은 가벼운 아우터만 입어도 괜찮아요! ☁️\n점심시간엔 따뜻하니 얇은 가디건 추천드려요.'),
            SizedBox(height: 20,),
            CategorySelector(),
            SizedBox(height: 20,),
            Row(
              children: [
                Image.asset('asset/img/fire.png'),
                Text('오늘의 추천 코디', 
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700
                  ),
                )
              ],
            ),
            
          ],
        ),
      ),
    );

  }
}
