import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  final Widget child;
  final String location;

  const HomeScreen({
    super.key,
    required this.child,
    required this.location,
  });

  static const _tabs = [
    _TabItem(path: '/home', icon: Icons.home_outlined, activeIcon: Icons.home, label: '홈'),
    _TabItem(path: '/pets', icon: Icons.pets_outlined, activeIcon: Icons.pets, label: '개체'),
    _TabItem(path: '/records', icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: '기록'),
    _TabItem(path: '/community', icon: Icons.forum_outlined, activeIcon: Icons.forum, label: '커뮤니티'),
    _TabItem(path: '/my', icon: Icons.person_outline, activeIcon: Icons.person, label: 'MY'),
  ];

  int get _currentIndex {
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => context.go(_tabs[i].path),
          items: _tabs
              .map((t) => BottomNavigationBarItem(
                    icon: Icon(t.icon),
                    activeIcon: Icon(t.activeIcon),
                    label: t.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _TabItem {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _TabItem({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
