import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/profile_provider.dart';

class AddChildDialog {
  static void show(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final allergyController = TextEditingController();
    DateTime? selectedDate;
    String selectedGender = 'L';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Tambah Profil Anak'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(selectedDate == null ? 'Tanggal Lahir' : DateFormat('dd/MM/yyyy').format(selectedDate!)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().subtract(const Duration(days: 365)),
                      firstDate: DateTime(2010),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => selectedDate = picked);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  items: const [
                    DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                    DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                  ],
                  onChanged: (val) => setState(() => selectedGender = val!),
                  decoration: const InputDecoration(labelText: 'Jenis Kelamin'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: allergyController,
                  decoration: const InputDecoration(labelText: 'Alergi (Pisahkan dengan koma)', hintText: 'Contoh: Kacang, Telur'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || selectedDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama dan tanggal lahir harus diisi')));
                  return;
                }
                final allergies = allergyController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                final success = await ref.read(profileProvider.notifier).addChild(
                  name: nameController.text,
                  birthDate: selectedDate!,
                  gender: selectedGender,
                  allergies: allergies,
                );
                if (success && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil anak berhasil ditambahkan')));
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
