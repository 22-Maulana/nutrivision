import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/pdf_service.dart';
import '../models/profile_state.dart';

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(_initialState()) {
    fetchProfile();
  }

  static ProfileState _initialState() {
    return ProfileState(
      motherId: '',
      motherName: 'Loading...',
      email: '',
      pregnancyStatusText: '',
      breastfeedingStatusText: '',
      motherAvatarPath: '', 
      children: [],
      motherBirthDate: null,
      motherStatus: '',
      motherAllergies: [],
      isDarkMode: false,
      hasNotifications: true,
      isLoading: true,
    );
  }

  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse(ApiConstants.apiBaseUrl + '/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        final mother = data['mother_profile'];
        final List<dynamic> childrenData = data['children'];

        final children = childrenData.map((c) {
          // Hitung usia secara kasar berdasarkan bulan
          final birthDate = DateTime.parse(c['birth_date']);
          final months = DateTime.now().difference(birthDate).inDays ~/ 30;
          String ageText = months >= 12 ? "${months ~/ 12} Tahun" : "$months Bulan";

          return ChildProfileInfo(
            id: c['id'].toString(),
            name: c['name'],
            ageText: ageText,
            allergiesText: (c['allergies'] as List).isEmpty ? 'Tidak ada alergi' : "Alergi: ${(c['allergies'] as List).join(', ')}",
            initial: c['name'].toString().substring(0, 1),
          );
        }).toList();

        String statusRaw = mother != null ? (mother['status'] ?? 'Hamil') : 'Hamil';
        String statusLabel = statusRaw;
        
        // Pemetaan kode internal dari database ke label yang ramah pengguna
        switch (statusRaw.toUpperCase()) {
          case 'PREGNANT_T1': statusLabel = 'Hamil (Trimester 1)'; break;
          case 'PREGNANT_T2': statusLabel = 'Hamil (Trimester 2)'; break;
          case 'PREGNANT_T3': statusLabel = 'Hamil (Trimester 3)'; break;
          case 'BREASTFEEDING': statusLabel = 'Sedang Menyusui'; break;
          case 'NOT_PREGNANT': statusLabel = 'Tidak Hamil/Menyusui'; break;
          default: statusLabel = statusRaw;
        }

        state = state.copyWith(
          motherId: mother != null ? (mother['id']?.toString() ?? data['id']?.toString() ?? '') : (data['id']?.toString() ?? ''),
          motherName: data['name'],
          email: data['email'],
          pregnancyStatusText: statusLabel,
          motherBirthDate: mother != null ? (mother['birth_date'] != null ? DateTime.parse(mother['birth_date']) : null) : null,
          motherStatus: statusRaw,
          motherAllergies: mother != null ? List<String>.from(mother['allergies'] ?? []) : [],
          children: children,
          isLoading: false,
        );
      }
    } catch (e) {
      print("Error fetching profile: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  void toggleDarkMode(bool value) {
    state = state.copyWith(isDarkMode: value);
  }

  Future<bool> updateMotherProfile({
    String? name,
    String? status,
    DateTime? birthDate,
    List<String>? allergies,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // Note: Backend ProfileController@updateMotherProfile might not update 'name' in User table,
      // but we send it anyway if available or we might need another endpoint.
      final response = await http.put(
        Uri.parse(ApiConstants.apiBaseUrl + '/profile/mother'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': status,
          'birth_date': birthDate?.toIso8601String().split('T')[0],
          'allergies': allergies,
        }),
      );

      if (response.statusCode == 200) {
        await fetchProfile();
        return true;
      }
      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      print("Error updating mother profile: $e");
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<bool> addChild({
    required String name,
    required DateTime birthDate,
    required String gender,
    List<String>? allergies,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse(ApiConstants.apiBaseUrl + '/profile/child'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'birth_date': birthDate.toIso8601String(),
          'gender': gender,
          'allergies': allergies ?? [],
        }),
      );

      if (response.statusCode == 201) {
        await fetchProfile();
        return true;
      }
      return false;
    } catch (e) {
      print("Error adding child: $e");
      return false;
    }
  }

  Future<void> exportPdfReport() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // 1. Fetch Mother Data (Logs & Growth)
      final motherLogsRes = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/food-logs?target_type=MOTHER&target_id=${state.motherId}'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      
      final motherGrowthRes = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/growth-records?target_type=MOTHER&target_id=${state.motherId}'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      List<Map<String, dynamic>> motherLogs = [];
      if (motherLogsRes.statusCode == 200) {
        final data = jsonDecode(motherLogsRes.body)['data'] as List;
        motherLogs = data.map((m) => {
          'date': DateFormat('dd/MM/yy').format(DateTime.parse(m['meal_time'])),
          'name': m['food_name_detected'],
          'calories': double.tryParse(m['calories_kcal']?.toString() ?? '0') ?? 0.0,
          'protein': double.tryParse(m['protein_g']?.toString() ?? '0') ?? 0.0,
          'carbs': double.tryParse(m['carbs_g']?.toString() ?? '0') ?? 0.0,
        }).toList();
      }

      List<Map<String, dynamic>> motherGrowth = [];
      if (motherGrowthRes.statusCode == 200) {
        final data = jsonDecode(motherGrowthRes.body)['data'] as List;
        motherGrowth = data.map((g) => {
          'date': DateFormat('dd/MM/yy').format(DateTime.parse(g['measured_at'])),
          'weight': double.tryParse(g['weight_kg']?.toString() ?? '0') ?? 0.0,
          'height': double.tryParse(g['height_cm']?.toString() ?? '0') ?? 0.0,
          'status': g['status'] ?? 'Normal',
        }).toList();
      }

      // 2. Fetch Children Data
      List<Map<String, dynamic>> childrenData = [];
      for (var child in state.children) {
        // Logs
        final childLogsRes = await http.get(
          Uri.parse('${ApiConstants.apiBaseUrl}/food-logs?target_type=CHILD&target_id=${child.id}'),
          headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
        );
        
        // Growth
        final childGrowthRes = await http.get(
          Uri.parse('${ApiConstants.apiBaseUrl}/growth-records?target_type=CHILD&target_id=${child.id}'),
          headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
        );

        List<Map<String, dynamic>> cLogs = [];
        if (childLogsRes.statusCode == 200) {
          final data = jsonDecode(childLogsRes.body)['data'] as List;
          cLogs = data.map((m) => {
            'date': DateFormat('dd/MM/yy').format(DateTime.parse(m['meal_time'])),
            'name': m['food_name_detected'],
            'calories': double.tryParse(m['calories_kcal']?.toString() ?? '0') ?? 0.0,
            'protein': double.tryParse(m['protein_g']?.toString() ?? '0') ?? 0.0,
            'carbs': double.tryParse(m['carbs_g']?.toString() ?? '0') ?? 0.0,
          }).toList();
        }

        List<Map<String, dynamic>> cGrowth = [];
        if (childGrowthRes.statusCode == 200) {
          final data = jsonDecode(childGrowthRes.body)['data'] as List;
          cGrowth = data.map((g) => {
            'date': DateFormat('dd/MM/yy').format(DateTime.parse(g['measured_at'])),
            'weight': double.tryParse(g['weight_kg']?.toString() ?? '0') ?? 0.0,
            'height': double.tryParse(g['height_cm']?.toString() ?? '0') ?? 0.0,
            'status': g['status'] ?? 'Normal',
          }).toList();
        }

        childrenData.add({
          'name': child.name,
          'logs': cLogs,
          'growth': cGrowth,
        });
      }

      state = state.copyWith(isLoading: false);
      
      // 3. Generate PDF
      await PdfService.generateNutritionReport(
        motherName: state.motherName,
        motherLogs: motherLogs,
        motherGrowth: motherGrowth,
        childrenData: childrenData,
      );

    } catch (e) {
      print("Error exporting PDF: $e");
      state = state.copyWith(isLoading: false);
    }
  }
}
