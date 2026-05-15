import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/step_progress_indicator.dart';
import '../../../core/widgets/custom_selection_card.dart';
import '../../../core/widgets/allergy_chip.dart';
import '../providers/auth_provider.dart';
import '../models/register_form_state.dart';
import '../../../routes/app_routes.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Check for initial step from query param
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final step = GoRouterState.of(context).uri.queryParameters['step'];
      if (step != null) {
        final stepInt = int.tryParse(step) ?? 1;
        if (stepInt > 1 && stepInt <= 3) {
          _pageController.jumpToPage(stepInt - 1);
          setState(() => _currentStep = stepInt);
        }
      }
    });
  }

  void _nextStep() async {
    if (_currentStep < 3) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      // Submit
      setState(() => _isLoading = true);
      
      // Regular registration
      final result = await ref.read(registerFormProvider.notifier).submitRegister();
      
      setState(() => _isLoading = false);

      if (result['success']) {
        if (result['requires_activation'] == true && mounted) {
          context.push(AppRoutes.otpVerification, extra: result['email']);
        } else if (mounted) {
          context.go(AppRoutes.dashboard);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: _prevStep,
        ),
        title: const Text('Daftar Akun', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => context.go(AppRoutes.dashboard),
            child: const Text('Skip', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: StepProgressIndicator(currentStep: _currentStep),
            ),
            Expanded(
              child: Stack(
                children: [
                  PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _currentStep = index + 1;
                      });
                    },
                    children: [
                      _RegisterStep1Account(onNext: _nextStep),
                      _RegisterStep2Mother(onNext: _nextStep),
                      _RegisterStep3Child(onFinish: _nextStep),
                    ],
                  ),
                  if (_isLoading)
                    Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterStep1Account extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const _RegisterStep1Account({required this.onNext});

  @override
  ConsumerState<_RegisterStep1Account> createState() => _RegisterStep1AccountState();
}

class _RegisterStep1AccountState extends ConsumerState<_RegisterStep1Account> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerFormProvider);
    final notifier = ref.read(registerFormProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Buat Akun NutriVision', style: textTheme.titleLarge?.copyWith(fontSize: 24)),
          const SizedBox(height: 8),
          Text('Gratis, tanpa kartu kredit.', style: textTheme.bodyMedium),
          const SizedBox(height: 32),
          CustomTextField(
            label: 'Nama Lengkap',
            hint: 'Masukkan nama lengkap Anda',
            prefixIcon: Icons.person_outline,
            initialValue: state.fullName,
            onChanged: (val) => notifier.updateStep1(fullName: val),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Alamat Email',
            hint: 'contoh@email.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            initialValue: state.email,
            onChanged: (val) => notifier.updateStep1(email: val),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Password',
            hint: 'Minimal 8 karakter',
            prefixIcon: Icons.lock_outline,
            isPassword: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            initialValue: state.password,
            onChanged: (val) => notifier.updateStep1(password: val),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Konfirmasi Password',
            hint: 'Ulangi password',
            prefixIcon: Icons.lock_reset_outlined,
            isPassword: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              final password = state.password;
              
              // Validation Regex
              final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
              final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
              final hasDigits = RegExp(r'[0-9]').hasMatch(password);
              final hasSpecialCharacters = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
              final hasMinLength = password.length >= 8;

              if (state.fullName.isEmpty || state.email.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Harap isi semua bidang')),
                );
                return;
              }

              if (!hasMinLength || !hasUppercase || !hasLowercase || !hasDigits || !hasSpecialCharacters) {
                String error = 'Password harus mengandung:';
                if (!hasMinLength) error += '\n- Minimal 8 karakter';
                if (!hasUppercase) error += '\n- Huruf besar (A-Z)';
                if (!hasLowercase) error += '\n- Huruf kecil (a-z)';
                if (!hasDigits) error += '\n- Angka (0-9)';
                if (!hasSpecialCharacters) error += '\n- Karakter spesial (!@#\$ dll)';
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error),
                    duration: const Duration(seconds: 4),
                  ),
                );
                return;
              }

              widget.onNext();
            },
            child: const Text('Lanjut'),
          ),

          const SizedBox(height: 32),

          Center(
            child: GestureDetector(
              onTap: () => context.go(AppRoutes.login),
              child: RichText(
                text: const TextSpan(
                  text: 'Sudah punya akun? ',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  children: [
                    TextSpan(
                      text: 'Masuk',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterStep2Mother extends ConsumerWidget {
  final VoidCallback onNext;
  const _RegisterStep2Mother({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(registerFormProvider);
    final notifier = ref.read(registerFormProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ceritakan tentang dirimu', style: textTheme.titleLarge?.copyWith(fontSize: 24)),
          const SizedBox(height: 8),
          Text('Pilih profil yang paling sesuai dengan kondisimu saat ini untuk personalisasi informasi.', style: textTheme.bodyMedium),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: CustomSelectionCard(
                  icon: Icons.pregnant_woman,
                  title: 'Sedang Hamil',
                  isSelected: state.pregnancyStatus == 'Sedang Hamil',
                  onTap: () => notifier.updateStep2(pregnancyStatus: 'Sedang Hamil'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomSelectionCard(
                  icon: Icons.child_care,
                  title: 'Sedang Menyusui',
                  isSelected: state.pregnancyStatus == 'Sedang Menyusui',
                  onTap: () => notifier.updateStep2(pregnancyStatus: 'Sedang Menyusui'),
                ),
              ),
            ],
          ),
          if (state.pregnancyStatus == 'Sedang Hamil') ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.textSecondary.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Detail Kehamilan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  const Text('Trimester Berapa?', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildTrimButton('Trim 1', state.trimester, notifier),
                      const SizedBox(width: 8),
                      _buildTrimButton('Trim 2', state.trimester, notifier),
                      const SizedBox(width: 8),
                      _buildTrimButton('Trim 3', state.trimester, notifier),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    key: ValueKey(state.hpl),
                    label: 'Hari Perkiraan Lahir (HPL)',
                    hint: 'mm/dd/yyyy',
                    initialValue: state.hpl.isEmpty ? null : state.hpl,
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 300)),
                      );
                      if (date != null) {
                        notifier.updateStep2(hpl: "${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}");
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          CustomTextField(
            key: ValueKey(state.motherDob),
            label: 'Tanggal lahir ibu',
            hint: 'mm/dd/yyyy',
            initialValue: state.motherDob.isEmpty ? null : state.motherDob,
            readOnly: true,
            onTap: () async {
               final date = await showDatePicker(
                 context: context,
                 initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
                 firstDate: DateTime.now().subtract(const Duration(days: 365 * 50)),
                 lastDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
               );
               if (date != null) {
                 notifier.updateStep2(motherDob: "${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}");
               }
            },
          ),
          const SizedBox(height: 24),
          const Text('Riwayat Alergi Makanan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildAllergy('Kacang', state, notifier),
              _buildAllergy('Susu Sapi', state, notifier),
              _buildAllergy('Telur', state, notifier),
              _buildAllergy('Seafood', state, notifier),
              ...state.motherAllergies
                  .where((a) => !['Kacang', 'Susu Sapi', 'Telur', 'Seafood'].contains(a))
                  .map((a) => _buildAllergy(a, state, notifier)),
              AllergyChip(label: '+ Tambah Lainnya', isSelected: false, isAddButton: true, onTap: () {
                _showAddAllergyDialog(context, (newAllergy) {
                   final current = List<String>.from(state.motherAllergies)..add(newAllergy);
                   notifier.updateStep2(motherAllergies: current);
                });
              }),
            ],
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: onNext,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Lanjut'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAllergyDialog(BuildContext context, Function(String) onAdd) {
    String newAllergy = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Alergi'),
          content: TextField(
            autofocus: true,
            onChanged: (val) => newAllergy = val,
            decoration: const InputDecoration(hintText: 'Masukkan nama alergi...'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                if (newAllergy.trim().isNotEmpty) {
                  onAdd(newAllergy.trim());
                }
                Navigator.pop(context);
              }, 
              child: const Text('Tambah'),
            ),
          ],
        );
      }
    );
  }

  Widget _buildTrimButton(String trim, String selectedTrim, RegisterFormNotifier notifier) {
    final isSelected = trim == selectedTrim;
    return Expanded(
      child: GestureDetector(
        onTap: () => notifier.updateStep2(trimester: trim),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.secondary.withOpacity(0.5) : Colors.transparent,
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.textSecondary.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            trim,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllergy(String allergy, RegisterFormState state, RegisterFormNotifier notifier) {
    final isSelected = state.motherAllergies.contains(allergy);
    return AllergyChip(
      label: allergy,
      isSelected: isSelected,
      onTap: () {
        final current = List<String>.from(state.motherAllergies);
        if (isSelected) {
          current.remove(allergy);
        } else {
          current.add(allergy);
        }
        notifier.updateStep2(motherAllergies: current);
      },
    );
  }
}

class _RegisterStep3Child extends ConsumerWidget {
  final VoidCallback onFinish;
  const _RegisterStep3Child({required this.onFinish});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(registerFormProvider);
    final notifier = ref.read(registerFormProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tambah profil anakmu', style: textTheme.titleLarge?.copyWith(fontSize: 24)),
          const SizedBox(height: 8),
          Text('Data ini membantu kami mempersonalisasi rekomendasi nutrisi.', style: textTheme.bodyMedium),
          const SizedBox(height: 32),
          
          ...state.children.asMap().entries.map((entry) {
            final index = entry.key;
            return _buildChildForm(index, context, state, notifier);
          }),
          
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => notifier.addChild(),
            icon: const Icon(Icons.add, color: AppColors.primary),
            label: const Text('+ Tambah Anak Lagi', style: TextStyle(color: AppColors.primary)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: const BorderSide(color: AppColors.primary, style: BorderStyle.solid),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: onFinish,
            child: const Text('Selesai & Mulai'),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: onFinish,
              child: const Text('Lewati, isi nanti', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAllergyDialog(BuildContext context, Function(String) onAdd) {
    String newAllergy = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Alergi'),
          content: TextField(
            autofocus: true,
            onChanged: (val) => newAllergy = val,
            decoration: const InputDecoration(hintText: 'Masukkan nama alergi...'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                if (newAllergy.trim().isNotEmpty) {
                  onAdd(newAllergy.trim());
                }
                Navigator.pop(context);
              }, 
              child: const Text('Tambah'),
            ),
          ],
        );
      }
    );
  }

  Widget _buildChildForm(int index, BuildContext context, RegisterFormState state, RegisterFormNotifier notifier) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (state.children.length > 1)
                GestureDetector(
                  onTap: () => notifier.removeChild(index),
                  child: const Icon(Icons.delete_outline, color: AppColors.textSecondary),
                )
            ],
          ),
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.textSecondary.withOpacity(0.1),
              child: const Icon(Icons.face, size: 40, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 24),
          CustomTextField(
            label: 'Nama Anak',
            hint: 'Masukkan nama panggilan',
            initialValue: state.children[index].name,
            onChanged: (val) => notifier.updateChild(index, state.children[index].copyWith(name: val)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  key: ValueKey(state.children[index].dob),
                  label: 'Tanggal Lahir',
                  hint: 'mm/dd/yyyy',
                  initialValue: state.children[index].dob.isEmpty ? null : state.children[index].dob,
                  suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      notifier.updateChild(index, state.children[index].copyWith(dob: "${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}"));
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Jenis Kelamin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.textSecondary.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: state.children[index].gender.isEmpty ? null : state.children[index].gender,
                          hint: const Text('Pilih'),
                          items: ['Laki-laki', 'Perempuan'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              notifier.updateChild(index, state.children[index].copyWith(gender: val));
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Alergi (Opsional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChildAllergy(index, 'Susu Sapi', state, notifier),
              _buildChildAllergy(index, 'Kacang', state, notifier),
              ...state.children[index].allergies
                  .where((a) => !['Susu Sapi', 'Kacang'].contains(a))
                  .map((a) => _buildChildAllergy(index, a, state, notifier)),
              AllergyChip(label: '+ Tambah', isSelected: false, isAddButton: true, onTap: () {
                _showAddAllergyDialog(context, (newAllergy) {
                   final current = List<String>.from(state.children[index].allergies)..add(newAllergy);
                   notifier.updateChild(index, state.children[index].copyWith(allergies: current));
                });
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChildAllergy(int index, String allergy, RegisterFormState state, RegisterFormNotifier notifier) {
    final isSelected = state.children[index].allergies.contains(allergy);
    return AllergyChip(
      label: allergy,
      isSelected: isSelected,
      onTap: () {
        final current = List<String>.from(state.children[index].allergies);
        if (isSelected) {
          current.remove(allergy);
        } else {
          current.add(allergy);
        }
        notifier.updateChild(index, state.children[index].copyWith(allergies: current));
      },
    );
  }
}
