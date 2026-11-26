import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/formatters.dart';

// Green = inside the 1 km walk zone around the shelter, yellow = outside.
class ZoneChip extends StatelessWidget {
  final double distance;
  final bool inZone;
  const ZoneChip({super.key, required this.distance, required this.inZone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: inZone ? AppColors.green : const Color(0xFFFFE3A3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        inZone
            ? '🏠 ${formatDistance(distance)} from shelter · inside walk zone'
            : '⚠️ ${formatDistance(distance)} from shelter · outside the 1 km zone',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.navy,
        ),
      ),
    );
  }
}
