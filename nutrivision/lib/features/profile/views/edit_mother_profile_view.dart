import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/profile_provider.dart';

class EditMotherProfileView extends ConsumerStatefulWidget {
  const EditMotherProfileView({super.key});

  @override
  ConsumerState<EditMotherProfileView> createState() => _EditMotherProfileViewState();
}

class _EditMotherProfileViewState extends ConsumerState<EditMotherProfileView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _allergyController;
  DateTime? _selectedDate;
  String _selectedStatus = '';
  List<String> _allergies = [];

  @override
  void initState() {
    super.initState();
    final state = ref.read(profileProvider);
    _nameController = TextEditingController(text: state.motherName);
    _allergyController = TextEditingController();
    _selectedDate = state.motherBirthDate;
    
    // Pastikan _selectedStatus sesuai dengan salah satu value di Dropdown items
    final validStatuses = ['PREGNANT_T1', 'PREGNANT_T2', 'PREGNANT_T3', 'BREASTFEEDING', 'NOT_PREGNANT', 'Hamil'];
    if (validStatuses.contains(state.motherStatus)) {
      _selectedStatus = state.motherStatus;
    } else {
      _selectedStatus = 'Hamil'; // Fallback
    }
    
    _allergies = List.from(state.motherAllergies);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _allergyController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _addAllergy() {
    if (_allergyController.text.isNotEmpty) {
      setState(() {
        _allergies.add(_allergyController.text.trim());
        _allergyController.clear();
      });
    }
  }

  void _removeAllergy(String allergy) {
    setState(() {
      _allergies.remove(allergy);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(profileProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profil Ibu',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.secondary.withOpacity(0.5),
                      child: const Icon(Icons.person, size: 50, color: AppColors.primary),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text('Nama Lengkap', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Masukkan nama lengkap',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.1)),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 24),
              const Text('Tanggal Lahir', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.textSecondary.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null ? 'Pilih Tanggal' : DateFormat('dd MMMM yyyy', 'id').format(_selectedDate!),
                        style: TextStyle(color: _selectedDate == null ? AppColors.textSecondary : AppColors.textPrimary),
                      ),
                      const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Status Saat Ini', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.1)),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'Hamil', child: Text('Hamil')),
                  DropdownMenuItem(value: 'PREGNANT_T1', child: Text('Hamil (Trimester 1)')),
                  DropdownMenuItem(value: 'PREGNANT_T2', child: Text('Hamil (Trimester 2)')),
                  DropdownMenuItem(value: 'PREGNANT_T3', child: Text('Hamil (Trimester 3)')),
                  DropdownMenuItem(value: 'BREASTFEEDING', child: Text('Sedang Menyusui')),
                  DropdownMenuItem(value: 'NOT_PREGNANT', child: Text('Tidak Hamil')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
              ),
              const SizedBox(height: 24),
              const Text('Alergi Makanan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _allergyController,
                      decoration: InputDecoration(
                        hintText: 'Tambah alergi (misal: Udang)',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.1)),
                        ),
                      ),
                      onFieldSubmitted: (_) => _addAllergy(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addAllergy,
                    icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 40),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allergies.map((allergy) => Chip(
                  label: Text(allergy, style: const TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.secondary.withOpacity(0.3),
                  onDeleted: () => _removeAllergy(allergy),
                  deleteIconColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                )).toList(),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: isLoading ? null : () async {
                  if (_formKey.currentState!.validate()) {
                    final success = await ref.read(profileProvider.notifier).updateMotherProfile(
                      name: _nameController.text,
                      status: _selectedStatus,
                      birthDate: _selectedDate,
                      allergies: _allergies,
                    );
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profil berhasil diperbarui!'), backgroundColor: Colors.green),
                      );
                      Navigator.pop(context);
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gagal memperbarui profil.'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
