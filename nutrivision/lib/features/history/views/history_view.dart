import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/history_provider.dart';
import '../models/history_state.dart';
import '../../../routes/app_routes.dart';
import '../../main/views/main_wrapper_screen.dart'; // To access bottomNavIndexProvider

class HistoryView extends ConsumerWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historyProvider);
    final notifier = ref.read(historyProvider.notifier);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text('Food History', style: TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              ref.read(bottomNavIndexProvider.notifier).state = 0; // Go to Home
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Membuka opsi bagikan riwayat...')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: AppColors.primary,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  onTap: (index) {
                    final periods = [HistoryPeriod.daily, HistoryPeriod.weekly, HistoryPeriod.monthly];
                    notifier.setPeriod(periods[index]);
                  },
                  tabs: const [
                    Tab(text: 'Harian'),
                    Tab(text: 'Mingguan'),
                    Tab(text: 'Bulanan'),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: state.isLoading 
              ? const Center(child: CircularProgressIndicator())
              : state.meals.isEmpty 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          state.selectedPeriod == HistoryPeriod.daily 
                            ? 'Belum ada riwayat makan hari ini' 
                            : state.selectedPeriod == HistoryPeriod.weekly 
                              ? 'Belum ada riwayat makan minggu ini'
                              : 'Belum ada riwayat makan bulan ini', 
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (state.selectedPeriod == HistoryPeriod.daily) ...[
                          _buildDatePicker(context, state, notifier),
                          const SizedBox(height: 32),
                        ],
                        Text(
                          state.selectedPeriod == HistoryPeriod.daily 
                            ? 'Ringkasan Gizi Hari Ini' 
                            : state.selectedPeriod == HistoryPeriod.weekly 
                              ? 'Ringkasan Gizi Minggu Ini'
                              : 'Ringkasan Gizi Bulan Ini', 
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildDailySummaryCard(state.summary),
                        const SizedBox(height: 32),
                        const Text('Daftar Konsumsi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        ...state.meals.map((meal) => _buildMealCard(context, meal, state)).toList(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildDatePicker(BuildContext context, HistoryState state, HistoryNotifier notifier) {
    final now = DateTime.now();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(state.dateText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.calendar_month, color: AppColors.primary, size: 24),
              onPressed: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: state.selectedDate,
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now(),
                  locale: const Locale('id', 'ID'),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: AppColors.primary,
                          onPrimary: AppColors.white,
                          onSurface: AppColors.textPrimary,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  notifier.selectCustomDate(picked);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            final date = now.subtract(Duration(days: 4 - index));
            final dayName = DateFormat('E', 'id').format(date);
            final dayDate = DateFormat('d').format(date);
            final fullDate = DateFormat('EEEE, d MMMM yyyy', 'id').format(date);
            
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: index == 0 ? 0 : 8),
                child: _buildDayBox(dayName, dayDate, index, state.selectedDayIndex, notifier, fullDate),
              ),
            );
          }),
        )
      ],
    );
  }

  Widget _buildDayBox(String day, String date, int index, int selectedIndex, HistoryNotifier notifier, String fullDate) {
    final isSelected = index == selectedIndex;
    return GestureDetector(
      onTap: () => notifier.selectDay(index, fullDate),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.lightBlue.withOpacity(0.1) : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.textSecondary.withOpacity(0.2), width: isSelected ? 1.5 : 1),
        ),
        child: Column(
          children: [
            Text(day, style: TextStyle(fontSize: 12, color: isSelected ? AppColors.primary : AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(date, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? AppColors.primary : AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(BuildContext context, DailyMealItem meal, HistoryState state) {
    return GestureDetector(
      onTap: () {
        context.push(AppRoutes.historyDetail, extra: {'meal': meal, 'date': state.dateText});
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.textSecondary.withOpacity(0.1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.fastfood, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(meal.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                      Text(meal.time, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('${meal.calories} kkal', style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.lightBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(meal.recommendation, style: const TextStyle(color: Colors.blue, fontSize: 10)),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'P: ${meal.protein.toInt()}g   L: ${meal.fat.toInt()}g   K: ${meal.carbs.toInt()}g',
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDailySummaryCard(DailySummary summary) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.cyan.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyan.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily Nutrition Summary', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          _buildSummaryProgress('Calories', summary.currentCalories, summary.targetCalories, 'kcal'),
          const SizedBox(height: 16),
          _buildSummaryProgress('Protein', summary.currentProtein, summary.targetProtein, 'g'),
          const SizedBox(height: 16),
          _buildSummaryProgress('Carbs', summary.currentCarbs, summary.targetCarbs, 'g'),
        ],
      ),
    );
  }

  Widget _buildSummaryProgress(String label, int current, int target, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.teal)),
            Text('$current / $target $unit', style: const TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: current / target,
            minHeight: 6,
            backgroundColor: Colors.white,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade700),
          ),
        ),
      ],
    );
  }
}
