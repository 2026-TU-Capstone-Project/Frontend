import 'package:flutter/material.dart';
import '../theme/fitting_room_theme.dart';

class FittingMainStage extends StatelessWidget {
  final String imagePath;

  const FittingMainStage({
    required this.imagePath,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: FittingRoomTheme.kPrimaryColor.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: AspectRatio(
              aspectRatio: 3 / 3.8,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off, size: 40, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text('이미지 로드 실패', style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                      );
                    },
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.0),
                            Colors.black.withOpacity(0.3),
                          ],
                          stops: const [0.0, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: Row(
            children: [
              _buildGlassIconButton(Icons.refresh),
              const SizedBox(width: 12),
              _buildGlassIconButton(Icons.fullscreen),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassIconButton(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}