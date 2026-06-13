import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../widgets/common/delivery_bottom_nav.dart';

class DeliveryShell extends StatelessWidget {
  const DeliveryShell({super.key, required this.child});

  final Widget child;

  DeliveryTab _tabFromLocation(String location) {
    if (location.contains('/requests')) return DeliveryTab.requests;
    if (location.contains('/history')) return DeliveryTab.history;
    if (location.contains('/profile')) return DeliveryTab.profile;
    return DeliveryTab.dashboard;
  }

  void _onTab(BuildContext context, DeliveryTab tab) {
    switch (tab) {
      case DeliveryTab.dashboard:
        context.go('/delivery');
      case DeliveryTab.requests:
        context.go('/delivery/requests');
      case DeliveryTab.history:
        context.go('/delivery/history');
      case DeliveryTab.profile:
        context.go('/delivery/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final hideNav = location.contains('/order/') || location.contains('/chat/');

    return Scaffold(
      backgroundColor: AppColors.black,
      body: child,
      bottomNavigationBar: hideNav
          ? null
          : DeliveryBottomNav(
              current: _tabFromLocation(location),
              onTap: (tab) => _onTab(context, tab),
            ),
    );
  }
}
