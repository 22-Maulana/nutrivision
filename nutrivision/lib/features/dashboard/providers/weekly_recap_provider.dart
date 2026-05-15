import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../profile/providers/profile_provider.dart';

class ProfileRecapData {
  final String id;
  final String name;
  final String role;
  final double compliance;
  final Map<String, double> macros; // 'Karbo', 'Protein', 'Lemak'
  final String status;

  ProfileRecapData({
    required this.id,
    required this.name,
    required this.role,
    required this.compliance,
    required this.macros,
    required this.status,
  });
}

class WeeklyRecapState {
  final List<ProfileRecapData> recaps;
  final bool isLoading;

  WeeklyRecapState({required this.recaps, this.isLoading = false});

  WeeklyRecapState copyWith({List<ProfileRecapData>? recaps, bool? isLoading}) {
    return WeeklyRecapState(
      recaps: recaps ?? this.recaps,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final weeklyRecapProvider = StateNotifierProvider<WeeklyRecapNotifier, WeeklyRecapState>((ref) {
  return WeeklyRecapNotifier(ref);
});

class WeeklyRecapNotifier extends StateNotifier<WeeklyRecapState> {
  final Ref _ref;

  WeeklyRecapNotifier(this._ref) : super(WeeklyRecapState(recaps: [], isLoading: true)) {
    fetchWeeklyRecaps();
  }

  Future<void> fetchWeeklyRecaps() async {
    state = state.copyWith(isLoading: true);
    try {
      final profileState = _ref.read(profileProvider);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final List<ProfileRecapData> newRecaps = [];

      // Calculate date range (7 days)
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final startDate = DateFormat('yyyy-MM-dd').format(sevenDaysAgo);
      final endDate = DateFormat('yyyy-MM-dd').format(now);

      // 1. Fetch Mother Recap
      final motherRecap = await _fetchSingleProfileRecap(
        token: token,
        targetType: 'MOTHER',
        targetId: profileState.motherId,
        name: profileState.motherName,
        role: 'Ibu (${profileState.pregnancyStatusText})',
        startDate: startDate,
        endDate: endDate,
      );
      if (motherRecap != null) newRecaps.add(motherRecap);

      // 2. Fetch Children Recaps
      for (var child in profileState.children) {
        final childRecap = await _fetchSingleProfileRecap(
          token: token,
          targetType: 'CHILD',
          targetId: child.id,
          name: child.name,
          role: 'Anak (${child.ageText})',
          startDate: startDate,
          endDate: endDate,
        );
        if (childRecap != null) newRecaps.add(childRecap);
      }

      state = state.copyWith(recaps: newRecaps, isLoading: false);
    } catch (e) {
      print("Error fetching weekly recaps: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  Future<ProfileRecapData?> _fetchSingleProfileRecap({
    required String token,
    required String targetType,
    required String targetId,
    required String name,
    required String role,
    required String startDate,
    required String endDate,
  }) async {
    if (targetId.isEmpty) return null;

    final queryParams = {
      'target_type': targetType,
      'target_id': targetId,
      'start_date': startDate,
      'end_date': endDate,
    };

    final uri = Uri.parse('${ApiConstants.apiBaseUrl}/dashboard/summary').replace(queryParameters: queryParams);
    
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['summary'];
      
      // Calculate average compliance over 7 days
      // Assuming target is per day, so weekly target is target * 7
      double targetCal = targetType == 'MOTHER' ? 2550 * 7 : 1400 * 7;
      double targetCarbs = targetType == 'MOTHER' ? 300 * 7 : 150 * 7;
      double targetProtein = targetType == 'MOTHER' ? 75 * 7 : 40 * 7;
      double targetFat = targetType == 'MOTHER' ? 60 * 7 : 35 * 7;

      double currentCal = (data['current_calories'] as num).toDouble();
      double currentCarbs = (data['carbs_g'] as num).toDouble();
      double currentProtein = (data['protein_g'] as num).toDouble();
      double currentFat = (data['fat_g'] as num).toDouble();

      double compliance = (currentCal / targetCal).clamp(0, 1);
      
      String status = 'Cukup';
      if (compliance > 0.8) status = 'Sangat Baik';
      else if (compliance > 0.5) status = 'Baik';
      else if (compliance < 0.3) status = 'Perlu Perhatian';

      return ProfileRecapData(
        id: targetId,
        name: name,
        role: role,
        compliance: compliance,
        macros: {
          'Karbo': (currentCarbs / targetCarbs).clamp(0, 1),
          'Protein': (currentProtein / targetProtein).clamp(0, 1),
          'Lemak': (currentFat / targetFat).clamp(0, 1),
        },
        status: status,
      );
    }
    return null;
  }
}
