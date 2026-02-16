import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/category.dart';

class CategoryChip extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.category,
    required this.onTap,
  });

  static const _categoryColors = <String, List<Color>>{
    'electronics': [Color(0xFF3B82F6), Color(0xFF60A5FA)],
    'fashion': [Color(0xFFEC4899), Color(0xFFF472B6)],
    'home': [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    'beauty': [Color(0xFFF97316), Color(0xFFFB923C)],
    'sports': [Color(0xFF10B981), Color(0xFF34D399)],
    'books': [Color(0xFF6366F1), Color(0xFF818CF8)],
    'toys': [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    'grocery': [Color(0xFF22C55E), Color(0xFF4ADE80)],
    'health': [Color(0xFFEF4444), Color(0xFFF87171)],
    'auto': [Color(0xFF64748B), Color(0xFF94A3B8)],
    'laptops': [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
    'smartphones': [Color(0xFF14B8A6), Color(0xFF2DD4BF)],
    'mens-fashion': [Color(0xFF6366F1), Color(0xFF818CF8)],
    'womens-fashion': [Color(0xFFE11D48), Color(0xFFFB7185)],
  };

  static final _icons = <String, IconData>{
    'electronics': Icons.devices_rounded,
    'fashion': Icons.checkroom_rounded,
    'home': Icons.home_rounded,
    'beauty': Icons.face_rounded,
    'sports': Icons.sports_basketball_rounded,
    'books': Icons.menu_book_rounded,
    'toys': Icons.toys_rounded,
    'grocery': Icons.local_grocery_store_rounded,
    'health': Icons.health_and_safety_rounded,
    'auto': Icons.directions_car_rounded,
    'laptops': Icons.laptop_rounded,
    'smartphones': Icons.phone_android_rounded,
    'mens-fashion': Icons.man_rounded,
    'womens-fashion': Icons.woman_rounded,
  };

  IconData _getIcon() {
    for (final entry in _icons.entries) {
      if (category.slug.toLowerCase().contains(entry.key)) {
        return entry.value;
      }
    }
    return Icons.category_rounded;
  }

  List<Color> _getColors() {
    for (final entry in _categoryColors.entries) {
      if (category.slug.toLowerCase().contains(entry.key)) {
        return entry.value;
      }
    }
    return const [AppTheme.primaryColor, Color(0xFF60A5FA)];
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors[0].withAlpha(25),
                    colors[1].withAlpha(15),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colors[0].withAlpha(40),
                  width: 1,
                ),
              ),
              child: category.iconUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        category.iconUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(_getIcon(), color: colors[0], size: 28),
                      ),
                    )
                  : Icon(_getIcon(), color: colors[0], size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                height: 1.2,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
