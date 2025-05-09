import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui';

class CircleIcon extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final double size;
  final Color borderColor;
  final double transparency;

  const CircleIcon({
    super.key,
    required this.icon,
    this.backgroundColor = const Color(0xFFF2F2F2),
    this.iconColor = const Color(0xFF006CFF),
    required this.size,
    this.borderColor = const Color(0xFFD6D6D6),
    this.transparency = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: backgroundColor.withValues(alpha: transparency),
                  border: Border.all(
                    color: borderColor,
                    width: 1.0,
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: FaIcon(
              icon,
              color: iconColor,
              size: size * 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
