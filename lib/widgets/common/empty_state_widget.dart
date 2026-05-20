import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/theme_helper.dart';
import 'custom_button.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  const EmptyStateWidget({
    Key? key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onActionPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.darkBorder : Colors.grey[400]!;
    final textColor = ThemeHelper.textSecondary(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 100, color: iconColor),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: 28),
              SizedBox(
                width: 200,
                child: CustomButton(
                  text: actionLabel!,
                  onPressed: onActionPressed!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
