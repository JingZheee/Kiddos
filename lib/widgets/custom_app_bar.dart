import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nursery_app/core/routing/app_navigation.dart';
import '../core/constants/ui_constants.dart';
import '../core/theme/app_theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? leadingIcon;
  final Color? backgroundColor;
  final Color? titleColor;
  final double elevation;
  final bool centerTitle;
  final String? userRole;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.leadingIcon,
    this.backgroundColor,
    this.titleColor,
    this.elevation = 0,
    this.centerTitle = true,
    this.userRole,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      centerTitle: centerTitle,
      elevation: elevation,
      backgroundColor: backgroundColor ?? AppTheme.primaryColor,
      leading: showBackButton && userRole != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 20),
              onPressed: onBackPressed ?? () => AppNavigation.goBackOrDashboard(context, userRole!),
            )
          : leadingIcon,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class CustomScrollableAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? leadingIcon;
  final Color? backgroundColor;
  final Color? titleColor;
  final Widget? bottom;
  final double expandedHeight;

  const CustomScrollableAppBar({
    Key? key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.leadingIcon,
    this.backgroundColor,
    this.titleColor,
    this.bottom,
    this.expandedHeight = 180,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: false,
      pinned: true,
      backgroundColor: backgroundColor ?? AppTheme.primaryColor,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 20),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
            )
          : leadingIcon,
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(
          left: UIConstants.spacing16,
          right: UIConstants.spacing16,
          bottom: UIConstants.spacing16,
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: titleColor ?? Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: UIConstants.spacing4),
              Text(
                subtitle!,
                style: TextStyle(
                  color: (titleColor ?? Colors.white).withOpacity(0.8),
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
        background: Container(
          color: backgroundColor ?? AppTheme.primaryColor,
          child: bottom,
        ),
      ),
    );
  }
} 