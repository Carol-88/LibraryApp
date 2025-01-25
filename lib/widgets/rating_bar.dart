import 'package:flutter/material.dart';

class RatingBar extends StatelessWidget {
  final double rating;
  final int count;

  const RatingBar({required this.rating, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
          5,
          (index) => Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 24,
              )),
    );
  }
}
