import 'package:flutter/material.dart';

class WeatherCard extends StatelessWidget {
  final Widget weahterIcon; // 오타: weatherIcon이 맞지만 일단 유지했습니다
  final int temp;
  final String region;
  final String weather;
  final String guideText;

  const WeatherCard({
    required this.weahterIcon,
    required this.temp,
    required this.region,
    required this.weather,
    required this.guideText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(

        image: DecorationImage(

          image: AssetImage('asset/img/bg.png'),


          fit: BoxFit.cover,


          colorFilter: ColorFilter.mode(
            Colors.white.withOpacity(0.2),
            BlendMode.lighten,
          ),
        ),

        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0,3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [


              SizedBox(
                width: 40,
                height: 40,
                child: weahterIcon,
              ),

              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${temp}°C',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '${region}, ${weather}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${guideText}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}