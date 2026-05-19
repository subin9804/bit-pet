import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PetProfileCard extends StatelessWidget {
  final String name;
  final String speciesName;
  final String? colorCode;
  final String? imageUrl;
  final bool isSelected;
  final VoidCallback? onTap;

  const PetProfileCard({
    super.key,
    required this.name,
    required this.speciesName,
    this.colorCode,
    this.imageUrl,
    this.isSelected = false,
    this.onTap,
  });

  Color get _accentColor {
    if (colorCode == null) return AppColors.primary;
    try {
      return Color(int.parse(colorCode!.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _accentColor : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _avatar(),
            const SizedBox(height: 8),
            Text(name,
                style: AppTextStyles.bodyBold,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(speciesName,
                style: AppTextStyles.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _avatar() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _accentColor.withOpacity(0.2),
        border: Border.all(color: _accentColor, width: 2),
      ),
      child: imageUrl != null
          ? ClipOval(
              child: Image.network(imageUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder()),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Icon(Icons.pets, color: _accentColor, size: 32);
  }
}
