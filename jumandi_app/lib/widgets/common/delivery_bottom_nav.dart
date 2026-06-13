import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';

enum DeliveryTab { dashboard, requests, history, profile }

class DeliveryBottomNav extends StatelessWidget {
  const DeliveryBottomNav({
    super.key,
    required this.current,
    required this.onTap,
  });

  final DeliveryTab current;
  final ValueChanged<DeliveryTab> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.black,
        border: Border(top: BorderSide(color: AppColors.inputBorder, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _item(DeliveryTab.dashboard, Icons.grid_view_rounded, 'Dashboard'),
            _item(DeliveryTab.requests, Icons.assignment_outlined, 'Requests'),
            _item(DeliveryTab.history, Icons.history, 'History'),
            _item(DeliveryTab.profile, Icons.person_outline, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _item(DeliveryTab tab, IconData icon, String label) {
    final active = current == tab;
    return GestureDetector(
      onTap: () => onTap(tab),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.brandYellow : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: active ? AppColors.black : AppColors.textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: active ? AppColors.black : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DeliveryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DeliveryAppBar({
    super.key,
    this.title,
    this.showBack = false,
    this.onBack,
  });

  final String? title;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.black,
      elevation: 0,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.brandYellow),
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : IconButton(
              icon: const Icon(Icons.menu, color: AppColors.brandYellow),
              onPressed: () {},
            ),
      title: title != null
          ? Text(
              title!,
              style: AppTextStyles.button.copyWith(
                color: AppColors.brandYellow,
                fontSize: 16,
                letterSpacing: 2,
              ),
            )
          : Text('Jumandi', style: AppTextStyles.logo.copyWith(fontSize: 24)),
      centerTitle: title != null,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.card,
            child: Icon(Icons.engineering, size: 18, color: AppColors.brandGold),
          ),
        ),
      ],
    );
  }
}
