import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class AboutAppView extends StatelessWidget {
  const AboutAppView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Tentang NutriVision', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome, size: 60, color: AppColors.white),
                      const SizedBox(height: 10),
                      Text(
                        'UNITY#14 - Tim NutriVision',
                        style: TextStyle(color: AppColors.white.withOpacity(0.9), fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.white),
              onPressed: () => context.pop(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Visi Aplikasi'),
                  const SizedBox(height: 12),
                  const Text(
                    'NutriVision adalah solusi cerdas berbasis AI yang dirancang untuk membantu para Ibu dalam memantau dan mengoptimalkan nutrisi keluarga, khususnya selama masa kehamilan dan masa pertumbuhan anak. Kami percaya bahwa nutrisi yang tepat adalah pondasi utama masa depan yang cerah.',
                    style: TextStyle(fontSize: 14, height: 1.6, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Panduan Fitur Utama'),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    icon: Icons.camera_alt_outlined,
                    title: 'Smart Food Scan',
                    description: 'Gunakan kamera untuk memotret makanan Anda. AI kami akan mendeteksi jenis makanan, menghitung estimasi kalori, dan memberikan saran apakah makanan tersebut aman berdasarkan profil kesehatan Anda.',
                    color: Colors.blue,
                  ),
                  _buildFeatureItem(
                    icon: Icons.chat_bubble_outline,
                    title: 'NutriBot (AI Assistant)',
                    description: 'Konsultasi gizi kapan saja. NutriBot memahami riwayat kesehatan Anda dan memberikan saran yang dipersonalisasi sesuai kebutuhan Ibu dan Anak.',
                    color: Colors.green,
                  ),
                  _buildFeatureItem(
                    icon: Icons.show_chart,
                    title: 'Growth Tracker',
                    description: 'Pantau perkembangan fisik anak secara berkala (Berat Badan, Tinggi Badan, Lingkar Kepala) dengan grafik standar kesehatan yang mudah dipahami.',
                    color: Colors.orange,
                  ),
                  _buildFeatureItem(
                    icon: Icons.notifications_active_outlined,
                    title: 'Weekly Nutrition Recap',
                    description: 'Dapatkan laporan mingguan tentang kepatuhan nutrisi keluarga Anda. Ketahui apa yang sudah tercapai dan apa yang perlu ditingkatkan.',
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Tim Pengembang'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.textSecondary.withOpacity(0.1)),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.secondary,
                          child: Text('U14', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('UNITY#14 - UNESA', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Innovative Solutions for Health', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  const Center(
                    child: Text(
                      'Versi 1.0.0 (Stable)',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
