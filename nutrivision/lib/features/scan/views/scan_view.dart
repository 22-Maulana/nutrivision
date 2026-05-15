import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/scan_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../../routes/app_routes.dart';

class ScanView extends ConsumerStatefulWidget {
  const ScanView({super.key});

  @override
  ConsumerState<ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends ConsumerState<ScanView> {
  bool _isLoading = false;

  void _onScanPressed() async {
    setState(() => _isLoading = true);
    final response = await ref.read(scanProvider.notifier).analyzeFood();
    setState(() => _isLoading = false);
    
    if (response != null && mounted) {
      context.push(AppRoutes.scanResult, extra: response);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scanProvider);
    final notifier = ref.read(scanProvider.notifier);
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('Scan Makanan', style: TextStyle(color: AppColors.white, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('Makanan ini untuk: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildProfileChip('Saya', Icons.pregnant_woman, state.targetProfileName, notifier),
                  if (profileState.children.isNotEmpty)
                    ...profileState.children.map((child) => Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: _buildProfileChip(child.name, Icons.child_care, state.targetProfileName, notifier),
                    )),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildCameraBox(state, notifier),
            const SizedBox(height: 32),
            const Text('Tambah catatan (Opsional)', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              maxLines: 4,
              maxLength: 200,
              onChanged: (val) => notifier.setNotes(val),
              decoration: InputDecoration(
                hintText: 'Contoh: Digoreng dengan sedikit minyak...',
                hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _onScanPressed,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.document_scanner),
                    SizedBox(width: 8),
                    Text('Scan Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 12, color: AppColors.textSecondary),
                  SizedBox(width: 4),
                  Text('Foto dianalisis AI dan dihapus otomatis dalam 30 hari', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileChip(String label, IconData icon, String selectedProfile, ScanNotifier notifier) {
    final isSelected = label == selectedProfile;
    return GestureDetector(
      onTap: () => notifier.setTargetProfile(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.textSecondary.withOpacity(0.3), width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraBox(state, ScanNotifier notifier) {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 2, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          if (state.imagePath != null && state.imagePath!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Image.file(
                  File(state.imagePath!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => notifier.pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 18),
                    label: const Text('Kamera', style: TextStyle(color: AppColors.primary)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      backgroundColor: AppColors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => notifier.pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.image_outlined, color: AppColors.primary, size: 18),
                    label: const Text('Galeri', style: TextStyle(color: AppColors.primary)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      backgroundColor: AppColors.white,
                    ),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}
