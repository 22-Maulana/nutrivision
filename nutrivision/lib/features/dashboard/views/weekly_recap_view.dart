import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/nutrition_graph_provider.dart';

import '../providers/weekly_recap_provider.dart';

class WeeklyRecapView extends ConsumerWidget {
  const WeeklyRecapView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(weeklyRecapProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('Rekapan Mingguan', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.white),
            onPressed: () => ref.read(weeklyRecapProvider.notifier).fetchWeeklyRecaps(),
          ),
        ],
      ),
      body: state.isLoading 
      ? const Center(child: CircularProgressIndicator())
      : RefreshIndicator(
          onRefresh: () => ref.read(weeklyRecapProvider.notifier).fetchWeeklyRecaps(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ringkasan Gizi Keluarga',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pantau progres pemenuhan gizi Ibu dan Anak dalam 7 hari terakhir berdasarkan data asupan makan.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary.withOpacity(0.8)),
                ),
                const SizedBox(height: 32),
                
                if (state.recaps.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Text('Belum ada data asupan untuk minggu ini.', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  )
                else
                  ...state.recaps.map((recap) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _buildProfileRecapCard(
                      context,
                      name: recap.name,
                      role: recap.role,
                      progress: recap.compliance,
                      color: recap.role.contains('Ibu') ? AppColors.primary : Colors.orange,
                      icon: recap.role.contains('Ibu') ? Icons.pregnant_woman : Icons.face,
                      status: recap.status,
                      macros: recap.macros,
                    ),
                  )),
                  
                const SizedBox(height: 32),
                _buildInfoCard(),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildProfileRecapCard(
    BuildContext context, {
    required String name,
    required String role,
    required double progress,
    required Color color,
    required IconData icon,
    required String status,
    required Map<String, double> macros,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(role, style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withOpacity(0.8))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (status == 'Perlu Perhatian' ? Colors.red : Colors.green).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: status == 'Perlu Perhatian' ? Colors.red : Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Kepatuhan Gizi', style: TextStyle(fontSize: 13)),
              Text('${(progress * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMiniStat('Karbo', '${(macros['Karbo']! * 100).toInt()}%', Colors.blue),
              _buildMiniStat('Protein', '${(macros['Protein']! * 100).toInt()}%', Colors.green),
              _buildMiniStat('Lemak', '${(macros['Lemak']! * 100).toInt()}%', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildMiniStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tips: Tingkatkan konsumsi Zat Besi untuk Ibu agar terhindar dari anemia selama masa kehamilan.',
              style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
            ),
          ),
        ],
      ),
    );
  }
}
