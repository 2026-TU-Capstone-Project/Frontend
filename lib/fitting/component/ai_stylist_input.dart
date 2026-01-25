import 'package:flutter/material.dart';
import '../theme/fitting_room_theme.dart';

class AiStylistInput extends StatefulWidget {
  final TextEditingController controller;
  final List<Map<String, dynamic>> chips;

  const AiStylistInput({
    required this.controller,
    required this.chips,
    super.key,
  });

  @override
  State<AiStylistInput> createState() => _AiStylistInputState();
}

class _AiStylistInputState extends State<AiStylistInput> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: FittingRoomTheme.kPrimaryColor.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [FittingRoomTheme.kPrimaryLight, FittingRoomTheme.kPrimaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: FittingRoomTheme.kPrimaryColor, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'AI Stylist',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: FittingRoomTheme.kTextColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: FittingRoomTheme.kSecondarySoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: FittingRoomTheme.kPrimaryColor),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '무엇이든 물어보세요',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // TextField
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(18),
            ),
            child: TextField(
              controller: widget.controller,
              style: const TextStyle(color: FittingRoomTheme.kTextColor, fontWeight: FontWeight.w500),
              maxLines: null,
              decoration: InputDecoration(
                hintText: '이번 주말 데이트 룩 추천해줘',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_circle_up_rounded, size: 32, color: FittingRoomTheme.kPrimaryColor),
                  onPressed: () {
                    print("사용자 입력: ${widget.controller.text}");
                    FocusScope.of(context).unfocus();
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: widget.chips.map((chip) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      widget.controller.text = chip['label'];
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(chip['icon'], size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            chip['label'].toString().split(' ')[0],
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )).toList(),
            ),
          )
        ],
      ),
    );
  }
}