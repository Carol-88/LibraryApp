import 'package:flutter/material.dart';

class Rating extends StatelessWidget {
  const Rating({
    super.key,
    required this.value,
    this.color = Colors.amber,
    this.onValueClicked,
  });

  final double value;
  final Color color;
  final Function(double)? onValueClicked;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        double starValue = index + 1.0;
        bool isFull = value >= starValue;
        bool isHalf = value >= starValue - 0.5 && value < starValue;

        return GestureDetector(
          onTapDown: (details) {
            if (onValueClicked != null) {
              // Detecta si se clickea en la mitad izquierda o derecha
              final tapPosition = details.localPosition.dx;
              final starWidth = 24.0; // Tamaño aproximado de la estrella
              double newValue =
                  (tapPosition < starWidth / 2) ? starValue - 0.5 : starValue;
              onValueClicked!(newValue);
            }
          },
          child: Icon(
            isFull
                ? Icons.star
                : isHalf
                    ? Icons.star_half
                    : Icons.star_border,
            color: color,
          ),
        );
      }),
    );
  }
}
