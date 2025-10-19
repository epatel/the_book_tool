import 'package:flutter/material.dart';

/// A custom add icon with a plus sign inside a circle with a thin border.
/// This replaces the default add_circle_outline icon which has a thick border.
class DSAddIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const DSAddIcon({
    super.key,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? IconTheme.of(context).color;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circle border
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: iconColor ?? Colors.black,
                width: 1.5,
              ),
            ),
          ),
          // Plus icon
          Icon(
            Icons.add,
            size: size * 0.6,
            color: iconColor,
          ),
        ],
      ),
    );
  }
}
