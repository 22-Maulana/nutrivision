import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../models/scan_response_model.dart';
import '../../../routes/app_routes.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/scan_provider.dart';

class ScanResultView extends ConsumerStatefulWidget {
  final ScanResponseModel result;

  const ScanResultView({super.key, required this.result});

  @override
  ConsumerState<ScanResultView> createState() => _ScanResultViewState();
}

class _ScanResultViewState extends ConsumerState<ScanResultView> {
  bool _isSaving = false;

  Future<void> _onSave(BuildContext context) async {
    setState(() { _isSaving = true; });
    
    // Panggil fungsi simpan di provider
    await ref.read(scanProvider.notifier).saveToHistory(widget.result);
    
    if (!mounted) return;
    
    setState(() { _isSaving = false; });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tersimpan! ${widget.result.foodName} (+${widget.result.calories} kkal)',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
      ),
    );
    context.go(AppRoutes.dashboard);
  }

  void _onDiscard(BuildContext context) {
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('Hasil Analisis', style: TextStyle(color: AppColors.white, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFoodCard(),
                const SizedBox(height: 24),
                _buildRecommendationCard(),
                const SizedBox(height: 24),
                _buildMacrosGrid(),
                const SizedBox(height: 24),
                _buildMicrosExpansion(),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomActions(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fastfood, color: AppColors.primary, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.result.foodName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.face, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(child: Text('Untuk: ${ref.watch(scanProvider).targetProfileName}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.lightBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(widget.result.portionDesc, style: const TextStyle(fontSize: 10, color: Colors.blue), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(widget.result.suggestionNote, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRecommendationCard() {
    final status = widget.result.recommendationStatus.toUpperCase();
    
    Color bgColor;
    Color iconColor;
    IconData icon;
    String label;

    if (status == 'DIANJURKAN') {
      bgColor = Colors.green.withOpacity(0.1);
      iconColor = Colors.green;
      icon = Icons.check_circle;
      label = 'Dianjurkan';
    } else if (status == 'PERHATIAN') {
      bgColor = Colors.orange.withOpacity(0.1);
      iconColor = Colors.orange;
      icon = Icons.priority_high;
      label = 'Perhatian';
    } else {
      bgColor = Colors.red.withOpacity(0.1);
      iconColor = Colors.red;
      icon = Icons.block;
      label = 'Hindari';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Text(widget.result.reasoning, style: TextStyle(color: iconColor.withOpacity(0.8), fontSize: 13, height: 1.4)),
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
      childAspectRatio: 1.2,
      children: [
        _buildMacroCard('Kalori', widget.result.calories.toStringAsFixed(0), 'kkal', widget.result.caloriesAkg, AppColors.primary),
        _buildMacroCard('Protein', widget.result.protein.toStringAsFixed(1), 'g', widget.result.proteinAkg, AppColors.primary),
        _buildMacroCard('Karbohidrat', widget.result.carbs.toStringAsFixed(1), 'g', widget.result.carbsAkg, AppColors.primary),
        _buildMacroCard('Lemak', widget.result.fat.toStringAsFixed(1), 'g', widget.result.fatAkg, AppColors.primary),
      ],
    );
  }

  Widget _buildMacroCard(String title, String value, String unit, int akg, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(unit, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('AKG:', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              Text('$akg%', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: akg / 100,
              minHeight: 4,
              backgroundColor: AppColors.textSecondary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMicrosExpansion() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.2)),
      ),
      child: ExpansionTile(
        title: const Text('Lihat mikronutrien lengkap', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        shape: const Border(),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: widget.result.micronutrients.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text('${entry.value}%', style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: entry.value / 100,
                          minHeight: 4,
                          backgroundColor: AppColors.textSecondary.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            entry.value >= 50 ? Colors.green : AppColors.primary,
                          ),
                        ),
                      )
                    ],
                  ),
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () => _onSave(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check, color: AppColors.white),
                    SizedBox(width: 8),
                    Text('Ya, Saya Makan Ini', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.white)),
                  ],
                ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _onDiscard(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.close, color: Colors.red),
                SizedBox(width: 8),
                Text('Saya Tidak Makan Ini', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Informasi gizi adalah estimasi dan dapat bervariasi berdasarkan bahan spesifik.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 8, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
