import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final Color? color;
  final bool showLabel;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 18,
    this.color,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? Colors.amber.shade600;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          if (index < rating.floor()) {
            return Icon(Icons.star_rounded, size: size, color: starColor);
          } else if (index < rating) {
            return Icon(Icons.star_half_rounded, size: size, color: starColor);
          } else {
            return Icon(Icons.star_outline_rounded,
                size: size, color: Colors.grey.shade300);
          }
        }),
        if (showLabel) ...[
          const SizedBox(width: 6),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.75,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ],
    );
  }
}

class InteractiveRatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final ValueChanged<double> onRatingChanged;

  const InteractiveRatingStars({
    super.key,
    required this.rating,
    this.size = 36,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () => onRatingChanged(index + 1.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color:
                  index < rating ? Colors.amber.shade600 : Colors.grey.shade300,
            ),
          ),
        );
      }),
    );
  }
}
