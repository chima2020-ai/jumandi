import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';

enum MainTab { home, booking, history, chat, profile }

class JumandiBottomNav extends StatelessWidget {
  const JumandiBottomNav({
    super.key,
    required this.current,
    required this.onTap,
  });

  final MainTab current;
  final ValueChanged<MainTab> onTap;

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
            _item(MainTab.home, Icons.home_outlined, 'HOME'),
            _item(MainTab.booking, Icons.local_gas_station_outlined, 'BOOKING'),
            _item(MainTab.history, Icons.history, 'HISTORY'),
            _item(MainTab.chat, Icons.chat_bubble_outline, 'CHAT'),
            _item(MainTab.profile, Icons.person_outline, 'PROFILE'),
          ],
        ),
      ),
    );
  }

  Widget _item(MainTab tab, IconData icon, String label) {
    final active = current == tab;
    return GestureDetector(
      onTap: () => onTap(tab),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: active ? AppColors.brandYellow : AppColors.brandGold,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: active ? AppColors.brandYellow : AppColors.brandGold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JumandiAppBar extends StatelessWidget implements PreferredSizeWidget {
  const JumandiAppBar({
    super.key,
    this.showMenu = true,
    this.showAvatar = true,
    this.leading,
    this.actions,
  });

  final bool showMenu;
  final bool showAvatar;
  final Widget? leading;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.black,
      elevation: 0,
      leading: leading ??
          (showMenu
              ? IconButton(
                  icon: const Icon(Icons.menu, color: AppColors.brandYellow),
                  onPressed: () {},
                )
              : null),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!showMenu) const SizedBox.shrink(),
          const Icon(Icons.local_gas_station, color: AppColors.brandGold, size: 22),
          const SizedBox(width: 8),
          Text(
            'Jumandi',
            style: AppTextStyles.logo.copyWith(fontSize: 24),
          ),
        ],
      ),
      centerTitle: !showMenu,
      actions: actions ??
          (showAvatar
              ? [
                  IconButton(
                    icon: const Icon(Icons.notifications_none, color: AppColors.brandGold),
                    onPressed: () {},
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.card,
                      child: Icon(Icons.person, size: 18, color: AppColors.brandGold),
                    ),
                  ),
                ]
              : null),
    );
  }
}
