import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../models/history_state.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/history_provider.dart';

class HistoryDetailView extends ConsumerStatefulWidget {
  final DailyMealItem meal;
  final String dateText;

  const HistoryDetailView({super.key, required this.meal, required this.dateText});

  @override
  ConsumerState<HistoryDetailView> createState() => _HistoryDetailViewState();
}

class _HistoryDetailViewState extends ConsumerState<HistoryDetailView> {
  bool _isEditing = false;
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text('Riwayat Makan', style: TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert, color: AppColors.primary), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateNavigator(),
            const SizedBox(height: 24),
            _buildMealHeader(),
            const SizedBox(height: 24),
            _buildRecommendationCard(),
            const SizedBox(height: 24),
            _buildMacrosGrid(),
            const SizedBox(height: 24),
            _buildDailyAccumulationCard(),
            const SizedBox(height: 32),
            _buildBottomActions(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildDateNavigator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.textSecondary.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chevron_left, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 16),
            Text(widget.dateText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(width: 16),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMealHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.meal.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(widget.meal.time, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.lightBlue.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Column(
            children: [
              Text('${widget.meal.calories}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const Text('kkal', style: TextStyle(fontSize: 10, color: AppColors.primary)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildRecommendationCard() {
    final isRecommended = widget.meal.recommendation.toLowerCase() == 'dianjurkan';
    final bgColor = isRecommended ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1);
    final iconColor = isRecommended ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isRecommended ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isRecommended ? Icons.check_circle : Icons.warning, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(widget.meal.recommendation, style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Text(widget.meal.reason, style: TextStyle(color: iconColor.withOpacity(0.8), fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildMacrosGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2,
      children: [
        _buildMacroBox('Protein', '${widget.meal.protein}g', AppColors.primary),
        _buildMacroBox('Karbohidrat', '${widget.meal.carbs}g', AppColors.primary),
        _buildMacroBox('Lemak', '${widget.meal.fat}g', AppColors.primary),
        _buildMacroBox('Serat', '${widget.meal.fiber}g', AppColors.primary),
      ],
    );
  }

  Widget _buildMacroBox(String label, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildDailyAccumulationCard() {
    // In real app, these values would come from the state, 
    // but here we mock it to match the UI.
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
          const Row(
            children: [
              Icon(Icons.insert_chart, size: 16, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Nutrisi Harian Terkumpul', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 24),
          _buildAccumulationProgress('Kalori (Kkal)', 650, 1200),
          const SizedBox(height: 16),
          _buildAccumulationProgress('Protein (g)', 28, 45, color: Colors.green),
          const SizedBox(height: 16),
          _buildAccumulationProgress('Karbo (g)', 80, 150),
        ],
      ),
    );
  }

  Widget _buildAccumulationProgress(String label, int current, int target, {Color? color}) {
    final progressColor = color ?? AppColors.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text('$current / $target', style: const TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: current / target,
            minHeight: 6,
            backgroundColor: AppColors.white,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            setState(() { _isEditing = true; });
            await ref.read(historyProvider.notifier).editHistory(widget.meal);
            if (!mounted) return;
            setState(() { _isEditing = false; });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catatan berhasil diperbarui.')));
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isEditing ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Edit Catatan', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () async {
            setState(() { _isDeleting = true; });
            await ref.read(historyProvider.notifier).deleteHistory(widget.meal);
            if (!mounted) return;
            setState(() { _isDeleting = false; });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Riwayat dihapus.')));
            context.pop();
          },
          child: _isDeleting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Hapus Riwayat', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
