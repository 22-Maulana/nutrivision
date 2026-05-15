import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../models/nutrition_graph_state.dart';
import '../providers/nutrition_graph_provider.dart';
import '../../profile/providers/profile_provider.dart';

class NutritionGraphView extends ConsumerWidget {
  const NutritionGraphView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nutritionGraphProvider);
    final notifier = ref.read(nutritionGraphProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('Grafik Gizi', style: TextStyle(color: AppColors.white, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileSelector(state, notifier, ref),
                _buildTabs(state, notifier),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      _buildDateSelector(state),
                      const SizedBox(height: 16),
                      _buildCaloryCard(state),
                      const SizedBox(height: 24),
                      _buildNutritionCard(state),
                      const SizedBox(height: 24),
                      _buildTimelineCard(state),
                      const SizedBox(height: 48), // Padding
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (state.isLoading)
            Container(
              color: AppColors.white.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileSelector(state, NutritionGraphNotifier notifier, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildProfileChip('Saya', state.activeProfileName, Icons.pregnant_woman, notifier),
            ...profileState.children.map((child) => Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: _buildProfileChip(child.name, state.activeProfileName, Icons.face, notifier),
            )),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary),
              ),
              child: const Text('+ Tambah', style: TextStyle(color: AppColors.primary, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileChip(String label, String active, IconData icon, NutritionGraphNotifier notifier) {
    final isSelected = label == active;
    return GestureDetector(
      onTap: () => notifier.setActiveProfile(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.textSecondary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? AppColors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppColors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(state, NutritionGraphNotifier notifier) {
    final tabs = ['Harian', 'Mingguan', 'Bulanan', 'Tahunan'];
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: tabs.map((tab) {
          final isSelected = tab == state.activeTab;
          return GestureDetector(
            onTap: () => notifier.setActiveTab(tab),
            child: Container(
              padding: const EdgeInsets.only(bottom: 12, top: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                tab,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateSelector(state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(icon: const Icon(Icons.chevron_left), onPressed: () {}),
        Text(state.currentDateText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        IconButton(icon: const Icon(Icons.chevron_right), onPressed: () {}),
      ],
    );
  }

  Widget _buildCaloryCard(state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: state.caloryPercentage,
                  strokeWidth: 14,
                  backgroundColor: AppColors.textSecondary.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              Column(
                children: [
                  Text(
                    '${(state.caloryPercentage * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Asupan Kalori', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${state.currentCalories}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
              Text(' / ${state.targetCalories} kkal', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.track_changes, size: 14, color: Colors.orange),
                const SizedBox(width: 4),
                Text('Sisa: +${state.remainingCalories} kkal', style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNutritionCard(state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nutrisi Hari Ini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          _buildMacroRow('Karbohidrat', state.macros['Karbohidrat']!, Colors.lightBlue),
          const SizedBox(height: 16),
          _buildMacroRow('Protein', state.macros['Protein']!, Colors.blue),
          const SizedBox(height: 16),
          _buildMacroRow('Lemak', state.macros['Lemak']!, Colors.orange),
          const SizedBox(height: 16),
          _buildMacroRow('Serat', state.macros['Serat']!, Colors.grey),
        ],
      ),
    );
  }

  Widget _buildMacroRow(String title, MacroNutrientInfo info, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 12)),
            Row(
              children: [
                Text('${info.current}g / ${info.target}g ', style: const TextStyle(fontSize: 12)),
                Text('(${(info.percentage * 100).toInt()}%)', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: info.percentage,
            minHeight: 6,
            backgroundColor: AppColors.textSecondary.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        )
      ],
    );
  }

  Widget _buildTimelineCard(state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Timeline Makanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton(onPressed: () {}, child: const Text('Lihat Semua', style: TextStyle(color: AppColors.primary, fontSize: 12))),
            ],
          ),
          const SizedBox(height: 16),
          ...state.mealsTimeline.map((meal) => _buildTimelineItem(meal)).toList(),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(TimelineMealInfo meal) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: meal.iconColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(meal.icon, size: 16, color: meal.iconColor),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: AppColors.textSecondary.withOpacity(0.2),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background, // slight grey
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.textSecondary.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(meal.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(meal.time, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${meal.calories} kkal', style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 10, color: Colors.green),
                        SizedBox(width: 4),
                        Text('Tersimpan', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
