import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../dashboard/views/home_view.dart';
import '../../history/views/history_view.dart';
import '../../scan/views/scan_view.dart';
import '../../growth/views/growth_view.dart';
import '../../profile/views/profile_view.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class MainWrapperScreen extends ConsumerWidget {
  const MainWrapperScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    final List<Widget> pages = [
      const HomeView(),
      const HistoryView(),
      const ScanView(),
      const GrowthView(),
      const ProfileView(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Keluar Aplikasi'),
            content: const Text('Apakah Anda yakin ingin keluar dari aplikasi NutriVision?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Tidak'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Ya'),
              ),
            ],
          ),
        );
        if (shouldPop == true && context.mounted) {
          // If using SystemNavigator.pop() or similar
          Navigator.of(context).pop(); 
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: pages,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            ref.read(bottomNavIndexProvider.notifier).state = 2; // Index Scan
          },
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          elevation: 4,
          child: const Icon(Icons.camera_alt, color: AppColors.white, size: 28),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          color: AppColors.white,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(context, ref, icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Beranda', index: 0, currentIndex: currentIndex),
                _buildNavItem(context, ref, icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Riwayat', index: 1, currentIndex: currentIndex),
                const SizedBox(width: 48), // Space for FAB
                _buildNavItem(context, ref, icon: Icons.show_chart_outlined, activeIcon: Icons.show_chart, label: 'Tumbuh', index: 3, currentIndex: currentIndex),
                _buildNavItem(context, ref, icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profil', index: 4, currentIndex: currentIndex),
              ],
            ),
          ),
        ),
      ),
    );

  }

  Widget _buildNavItem(BuildContext context, WidgetRef ref, {required IconData icon, required IconData activeIcon, required String label, required int index, required int currentIndex}) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () {
        ref.read(bottomNavIndexProvider.notifier).state = index;
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
