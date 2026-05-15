import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/growth_provider.dart';
import '../models/growth_state.dart';

class GrowthView extends ConsumerStatefulWidget {
  const GrowthView({super.key});

  @override
  ConsumerState<GrowthView> createState() => _GrowthViewState();
}

class _GrowthViewState extends ConsumerState<GrowthView> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  String _selectedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
  bool _isSaving = false;

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(growthProvider);
    final notifier = ref.read(growthProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text('Tumbuh Kembang', style: TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              final profile = ref.read(profileProvider);
              if (value == 'mother') {
                notifier.setProfile('Saya (Ibu)', profile.motherId, 'MOTHER', profile.motherName);
              } else {
                final child = profile.children.firstWhere((c) => c.id == value);
                notifier.setProfile(child.name, child.id, 'CHILD', '${child.name} · ${child.ageText}');
              }
            },
            itemBuilder: (context) {
              final profile = ref.read(profileProvider);
              return [
                const PopupMenuItem(value: 'mother', child: Text('Saya (Ibu)')),
                ...profile.children.map((child) => PopupMenuItem(value: child.id, child: Text(child.name))),
              ];
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.textSecondary.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text(state.selectedChildName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                  const Icon(Icons.keyboard_arrow_down, color: AppColors.textPrimary, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.notifications_none, color: AppColors.primary),
          const SizedBox(width: 16),
        ],
      ),
      body: state.isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildStatusCard(state),
            const SizedBox(height: 24),
            _buildMeasurementForm(context),
            const SizedBox(height: 24),
            _buildChartCard(state, notifier),
            const SizedBox(height: 24),
            _buildHistoryTable(state),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.growthStatusText, style: const TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(state.childInfoText, style: TextStyle(color: Colors.green.withOpacity(0.8), fontSize: 12)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSdBox('TB/Usia', '+${state.tbUsiaSd} SD'),
              _buildSdBox('BB/Usia', '${state.bbUsiaSd} SD'),
              _buildSdBox('BB/TB', '${state.bbTbSd} SD'),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Text('Pembaruan terakhir: ${state.lastUpdatedText}', style: TextStyle(color: Colors.green.withOpacity(0.8), fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildSdBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    );
  }

  Widget _buildMeasurementForm(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.1)),
      ),
      child: ExpansionTile(
        title: const Row(
          children: [
            Icon(Icons.add_circle_outline, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Tambah Pengukuran Baru', style: TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.bold)),
          ],
        ),
        shape: const Border(),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Berat Badan (kg)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                _buildTextField('Misal: 8.5', _weightController),
                const SizedBox(height: 16),
                const Text('Tinggi Badan (cm)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                _buildTextField('Misal: 72.0', _heightController),
                const SizedBox(height: 16),
                const Text('Tanggal Pengukuran', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = DateFormat('dd/MM/yyyy').format(picked);
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.textSecondary.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 18),
                        const SizedBox(width: 12),
                        Text(_selectedDate, style: const TextStyle(color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (_weightController.text.isEmpty || _heightController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap isi BB dan TB.')));
                      return;
                    }
                    setState(() { _isSaving = true; });
                    await ref.read(growthProvider.notifier).addMeasurement(
                      double.parse(_weightController.text),
                      double.parse(_heightController.text),
                      _selectedDate,
                    );
                    if (!mounted) return;
                    setState(() {
                      _isSaving = false;
                      _weightController.clear();
                      _heightController.clear();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data berhasil disimpan!')));
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan Pengukuran'),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.2)),
        ),
      ),
    );
  }

  Widget _buildChartCard(state, notifier) {
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
          const Text('Grafik Pertumbuhan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildChartTab('TB/Usia', state.activeChartTab, notifier),
              _buildChartTab('BB/Usia', state.activeChartTab, notifier),
              _buildChartTab('BB/TB', state.activeChartTab, notifier),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 250,
            padding: const EdgeInsets.only(right: 16, top: 24, bottom: 10),
            decoration: BoxDecoration(
              color: Colors.cyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: state.measurements.isEmpty 
              ? const Center(child: Text('Belum ada data untuk grafik', style: TextStyle(color: Colors.cyan, fontSize: 12)))
              : LineChart(
              LineChartData(
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: const FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: () {
                      final List<GrowthMeasurement> chronoMeasurements = state.measurements.reversed.toList();
                      if (state.activeChartTab == 'TB/Usia') {
                        return chronoMeasurements.asMap().entries.map<FlSpot>((e) => FlSpot(e.key.toDouble(), e.value.heightCm)).toList();
                      } else if (state.activeChartTab == 'BB/Usia') {
                        return chronoMeasurements.asMap().entries.map<FlSpot>((e) => FlSpot(e.key.toDouble(), e.value.weightKg)).toList();
                      } else {
                        // BB/TB
                        return chronoMeasurements.map<FlSpot>((m) => FlSpot(m.heightCm, m.weightKg)).toList();
                      }
                    }(),
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: Colors.red.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('Data ${state.selectedChildName}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildChartTab(String title, String activeTab, GrowthNotifier notifier) {
    final isSelected = title == activeTab;
    return GestureDetector(
      onTap: () => notifier.setActiveChartTab(title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : AppColors.background,
          border: Border.all(color: isSelected ? AppColors.textSecondary.withOpacity(0.2) : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTable(state) {
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
          const Text('Riwayat Pengukuran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Tanggal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text('BB (kg)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text('TB (cm)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(),
          ...state.measurements.map((m) {
            final isNormal = m.status == 'Normal';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(flex: 2, child: Text(m.date, style: const TextStyle(fontSize: 12))),
                  Expanded(child: Text('${m.weightKg}', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center)),
                  Expanded(child: Text('${m.heightCm}', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center)),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isNormal ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        m.status,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, color: isNormal ? Colors.green : Colors.orange, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Memuat riwayat lengkap...')));
              },
              child: const Text('Lihat Semua Riwayat', style: TextStyle(color: AppColors.primary, fontSize: 12)),
            ),
          )
        ],
      ),
    );
  }
}
