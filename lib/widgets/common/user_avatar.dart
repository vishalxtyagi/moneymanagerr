import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:moneymanager/constants/colors.dart';

class UserAvatar extends StatelessWidget {
  final String? photoURL;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? borderColor;
  final double borderWidth;
  final bool showBorder;

  const UserAvatar({
    super.key,
    this.photoURL,
    this.size = 40,
    this.backgroundColor,
    this.iconColor,
    this.borderColor,
    this.borderWidth = 2,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor =
        backgroundColor ?? AppColors.primary.withOpacity(0.1);
    final effectiveIconColor = iconColor ?? AppColors.primary;
    final effectiveBorderColor = borderColor ?? Colors.white.withOpacity(0.3);

    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: effectiveBackgroundColor,
        border: showBorder
            ? Border.all(
                color: effectiveBorderColor,
                width: borderWidth,
              )
            : null,
      ),
      child: photoURL != null
          ? ClipOval(
              child: Image.network(
                photoURL!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: size * 0.4,
                      height: size * 0.4,
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(effectiveIconColor),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Iconsax.user,
                    color: effectiveIconColor,
                    size: size * 0.5,
                  );
                },
              ),
            )
          : Icon(
              Iconsax.user,
              color: effectiveIconColor,
              size: size * 0.5,
            ),
    );

    return avatar;
  }
}
