import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../widgets/common/jumandi_app_bar.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  MainTab _currentFromLocation(String location) {
    if (location.contains('/booking')) return MainTab.booking;
    if (location.contains('/history')) return MainTab.history;
    if (location.contains('/chat')) return MainTab.chat;
    if (location.contains('/profile')) return MainTab.profile;
    return MainTab.home;
  }

  void _onTab(BuildContext context, MainTab tab) {
    switch (tab) {
      case MainTab.home:
        context.go('/home');
      case MainTab.booking:
        context.go('/home/booking');
      case MainTab.history:
        context.go('/home/history');
      case MainTab.chat:
        context.go('/home/chat');
      case MainTab.profile:
        context.go('/home/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    return Scaffold(
      backgroundColor: AppColors.black,
      body: child,
      bottomNavigationBar: JumandiBottomNav(
        current: _currentFromLocation(location),
        onTap: (tab) => _onTab(context, tab),
      ),
    );
  }
}
