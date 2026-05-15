import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/profile_provider.dart';
import '../widgets/add_child_dialog.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../routes/app_routes.dart';
import 'package:intl/intl.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileProvider);
    final notifier = ref.read(profileProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('Profil & Pengaturan', style: TextStyle(color: AppColors.white, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.notifications_none, color: AppColors.white),
              onPressed: () => context.push(AppRoutes.weeklyRecap),
            ),
          ),
        ],

      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMotherProfileCard(context, state),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Profil Anak', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => AddChildDialog.show(context, ref),
                  child: const Text('+ Tambah Anak', style: TextStyle(color: AppColors.primary)),
                ),

              ],
            ),
            const SizedBox(height: 8),
            ...state.children.map((child) => _buildChildCard(child)),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.textSecondary.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  _buildSettingItem(
                    Icons.notifications_none, 
                    'Cek Rekapan Gizi (Notifikasi)', 
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mengirim rekapan gizi ke notifikasi...')));
                      ref.read(dashboardProvider.notifier).triggerDailySummaryNotification();
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingItem(
                    Icons.info_outline, 
                    'Tentang Aplikasi', 
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.aboutApp),
                  ),

                ],
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sedang menyusun laporan PDF...')));
                notifier.exportPdfReport();
              },
              icon: const Icon(Icons.download, color: AppColors.primary),
              label: state.isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Ekspor Laporan PDF', style: TextStyle(color: AppColors.primary)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Konfirmasi Keluar'),
                    content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () {
                          // Logout logic here
                          context.go(AppRoutes.login);
                        },
                        child: const Text('Keluar', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Keluar dari Akun', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 100), // padding for bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildMotherProfileCard(BuildContext context, state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.secondary,
            child: const Icon(Icons.person, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(state.motherName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(state.email, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          if (state.isLoading)
            const CircularProgressIndicator()
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state.pregnancyStatusText.isNotEmpty)
                  _buildSmallChip(state.pregnancyStatusText),
                if (state.pregnancyStatusText.isNotEmpty && state.breastfeedingStatusText.isNotEmpty)
                  const SizedBox(width: 8),
                if (state.breastfeedingStatusText.isNotEmpty)
                  _buildSmallChip(state.breastfeedingStatusText),
              ],
            ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.push(AppRoutes.editMotherProfile),
            child: const Text('Edit Profil Ibu', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.1)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildChildCard(child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.lightBlue.withOpacity(0.3),
            child: Text(child.initial, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(child.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${child.ageText} • ${child.allergiesText}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
          )
        ],
      ),
    );
  }



  Widget _buildSettingItem(IconData icon, String title, {required Widget trailing, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
            trailing,
          ],
        ),
      ),
    );
  }
}

