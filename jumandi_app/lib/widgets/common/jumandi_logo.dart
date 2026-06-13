import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/app_colors.dart';

/// JUMANDI GAS logo with smile curve for the yellow splash screen.
class JumandiBrandLogo extends StatelessWidget {
  const JumandiBrandLogo({super.key, this.size = 1.0});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'JUMANDI',
            style: GoogleFonts.bowlbyOneSc(
              fontSize: 52,
              fontWeight: FontWeight.w400,
              color: AppColors.black,
              height: 1,
              letterSpacing: -1,
            ),
          ),
          SizedBox(
            height: 36,
            width: 220,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 8,
                  right: 52,
                  bottom: 0,
                  child: CustomPaint(
                    size: const Size(160, 28),
                    painter: _SmilePainter(),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 2,
                  child: Text(
                    'GAS',
                    style: GoogleFonts.bowlbyOneSc(
                      fontSize: 22,
                      color: AppColors.black,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmilePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.35);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 1.1,
      size.width,
      size.height * 0.2,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Yellow "Jumandi" wordmark used in app bars.
class JumandiWordmark extends StatelessWidget {
  const JumandiWordmark({super.key, this.fontSize = 26});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Jumandi',
      style: GoogleFonts.bebasNeue(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: AppColors.brandYellow,
        letterSpacing: 1,
      ),
    );
  }
}
