import 'package:flutter/material.dart';

/// A round fridge magnet: a color dot with a little shade at the bottom.
class Magnet extends StatelessWidget {
  const Magnet({super.key, required this.color, this.size = 10, this.shaded = false});

  final Color color;
  final double size;
  final bool shaded;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          gradient: shaded
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.82, 0.82],
                  colors: [color, Color.lerp(color, const Color(0xFF000000), 0.2)!],
                )
              : null,
        ),
      ),
    );
  }
}
