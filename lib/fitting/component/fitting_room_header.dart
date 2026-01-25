import 'package:flutter/material.dart';
import '../theme/fitting_room_theme.dart';

class FittingRoomHeader extends StatelessWidget {
  const FittingRoomHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'VIRTUAL STUDIO',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: FittingRoomTheme.kPrimaryColor,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '나의 피팅룸',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: FittingRoomTheme.kTextColor,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                '170cm · M size',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}