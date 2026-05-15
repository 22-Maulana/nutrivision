import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../main/views/main_wrapper_screen.dart';
import '../../../routes/app_routes.dart';
import '../../history/models/history_state.dart';
import '../models/dashboard_state.dart';
import '../providers/dashboard_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/widgets/add_child_dialog.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, state),
            _buildProfileChips(context, ref, state),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildNutritionCard(state),
                  const SizedBox(height: 24),
                  _buildScanButton(ref),
                  const SizedBox(height: 24),
                  _buildMenuGrid(context, ref),
                  const SizedBox(height: 32),
                  _buildHistoryHeader(ref),
                  const SizedBox(height: 16),
                  ...state.recentMeals.map((meal) => _buildRecentMeal(context, meal)).toList(),
                  const SizedBox(height: 100), // padding for bottom nav
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, ${state.userName} 👋',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                state.currentDate,
                style: TextStyle(
                  color: AppColors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => context.push(AppRoutes.weeklyRecap),
            child: Stack(

              children: [
                const Icon(Icons.notifications_none, color: AppColors.white, size: 28),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProfileChips(BuildContext context, WidgetRef ref, DashboardState state) {
    final profileState = ref.watch(profileProvider);
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 8),
      child: Row(
        children: [
          _buildChip(
            'Saya', 
            state.activeProfileName == 'Saya', 
            Icons.pregnant_woman,
            onTap: () => ref.read(dashboardProvider.notifier).setActiveProfile('Saya'),
          ),
          ...profileState.children.map((child) => Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: _buildChip(
              child.name, 
              state.activeProfileName == child.name, 
              Icons.face,
              onTap: () => ref.read(dashboardProvider.notifier).setActiveProfile(child.name),
            ),
          )),
          const SizedBox(width: 8),
          _buildChip(
            '+ Tambah Profil', 
            false, 
            null, 
            isDashed: true,
            onTap: () => AddChildDialog.show(context, ref),
          ),

        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, IconData? icon, {bool isDashed = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.textSecondary.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: isSelected ? AppColors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppColors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionCard(DashboardState state) {
    if (state.isLoading) {
      return Container(
        height: 350,
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Asupan Gizi Hari Ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: state.caloryPercentage,
                  strokeWidth: 10,
                  backgroundColor: AppColors.textSecondary.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              Column(
                children: [
                  Text(
                    '${(state.caloryPercentage * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Text('Kalori', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${state.currentCalories} / ${state.targetCalories} kkal',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: _buildLinearProgress('Protein', state.proteinPercentage, AppColors.primary)),
              const SizedBox(width: 16),
              Expanded(child: _buildLinearProgress('Zat Besi', state.ironPercentage, Colors.orange)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildLinearProgress('Lemak', state.fatPercentage, Colors.teal)),
              const SizedBox(width: 16),
              Expanded(child: _buildLinearProgress('Kalsium', state.calciumPercentage, AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLinearProgress(String title, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            Text('${(percentage * 100).toInt()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 6,
            backgroundColor: AppColors.textSecondary.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildScanButton(WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        ref.read(bottomNavIndexProvider.notifier).state = 2;
      },
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt),
          SizedBox(width: 8),
          Text('Scan Makanan Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildMenuItem(Icons.bar_chart, 'Grafik Gizi', Colors.blue.withOpacity(0.1), Colors.blue, onTap: () => context.push(AppRoutes.nutritionGraph)),
              const SizedBox(height: 16),
              _buildMenuItem(Icons.history, 'Riwayat Makan', AppColors.white, AppColors.textSecondary, hasBorder: true, onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 1),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              _buildMenuItem(Icons.trending_up, 'Tumbuh Kembang', Colors.cyan.withOpacity(0.1), Colors.cyan, onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 3),
              const SizedBox(height: 16),
              _buildMenuItem(Icons.chat_bubble_outline, 'NutriBot', AppColors.white, Colors.orange, hasBorder: true, onTap: () => context.push(AppRoutes.chatbot)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, Color bgColor, Color iconColor, {bool hasBorder = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: hasBorder ? Border.all(color: AppColors.textSecondary.withOpacity(0.2)) : null,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryHeader(WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Terakhir Makan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        GestureDetector(
          onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 1,
          child: const Text('Lihat Semua', style: TextStyle(color: AppColors.primary, fontSize: 12)),
        )
      ],
    );
  }

  Widget _buildRecentMeal(BuildContext context, FoodHistoryItem meal) {
    return GestureDetector(
      onTap: () {
        context.push(AppRoutes.historyDetail, extra: {
          'meal': DailyMealItem(
            name: meal.name,
            time: meal.time,
            calories: meal.calories,
            recommendation: 'Tersimpan',
            protein: 0.0, // We could fetch more if needed, but using available info
            fat: 0.0, 
            carbs: 0.0, 
            fiber: 0.0, 
            reason: 'Data gizi lengkap tersedia di halaman Riwayat.',
          ),
          'date': 'Hari Ini',
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.textSecondary.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.secondary,
              ),
              child: meal.imagePath.startsWith('http') 
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      meal.imagePath, 
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.fastfood, color: AppColors.primary),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                          ),
                        );
                      },
                    ),
                  )
                : const Icon(Icons.fastfood, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meal.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${meal.time} • ${meal.calories} kkal', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, size: 12, color: Colors.green),
                  SizedBox(width: 4),
                  Text('Tersimpan', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
