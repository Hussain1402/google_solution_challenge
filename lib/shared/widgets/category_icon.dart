import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

/// Maps category_id to a human-readable icon + color.
class CategoryIcon extends StatelessWidget {
  final String categoryId;
  final double size;

  const CategoryIcon({super.key, required this.categoryId, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final config = _categoryConfig(categoryId);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(config.icon, size: size * 0.55, color: config.fgColor),
    );
  }

  static _CatConfig _categoryConfig(String categoryId) {
    switch (categoryId) {
      case 'CAT-01':
        return _CatConfig(Icons.restaurant, kLightBlue, kBlue);
      case 'CAT-02':
        return _CatConfig(Icons.local_hospital, kLightRed, kRed);
      case 'CAT-03':
        return _CatConfig(Icons.checkroom, kLightTeal, kTeal);
      case 'CAT-04':
        return _CatConfig(Icons.cleaning_services, kLightAmb, kAmber);
      case 'CAT-05':
        return _CatConfig(Icons.school, kLightGreen, kGreen);
      default:
        return _CatConfig(Icons.inventory_2, kLightGray, kGray);
    }
  }
}

class _CatConfig {
  final IconData icon;
  final Color bgColor;
  final Color fgColor;
  const _CatConfig(this.icon, this.bgColor, this.fgColor);
}
