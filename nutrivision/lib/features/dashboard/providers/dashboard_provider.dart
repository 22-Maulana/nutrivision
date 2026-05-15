import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/notification_service.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/models/profile_state.dart';
import '../models/dashboard_state.dart';

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final profileState = ref.watch(profileProvider);
  return DashboardNotifier(ref, profileState);
});

class DashboardNotifier extends StateNotifier<DashboardState> {
  final Ref _ref;
  final ProfileState _profileState;

  DashboardNotifier(this._ref, this._profileState) : super(_initialState()) {
    if (_profileState.motherName != 'Loading...') {
      _updateFromProfile();
    }
  }

  void _updateFromProfile() {
    state = state.copyWith(
      userName: _profileState.motherName.split(' ')[0], // First name
    );
    fetchSummary();
  }

  static DashboardState _initialState() {
    return DashboardState(
      userName: 'User',
      currentDate: DateFormat('EEEE, d MMMM yyyy', 'id').format(DateTime.now()),
      activeProfileName: 'Saya',
      caloryPercentage: 0,
      currentCalories: 0,
      targetCalories: 2550,
      proteinPercentage: 0,
      ironPercentage: 0,
      fatPercentage: 0,
      calciumPercentage: 0,
      recentMeals: [],
      isLoading: false,
    );
  }

  Future<void> fetchSummary() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      String targetType = 'MOTHER';
      String targetId = _profileState.motherId;

      if (state.activeProfileName != 'Saya') {
        final child = _profileState.children.firstWhereOrNull(
          (c) => c.name == state.activeProfileName,
        );
        if (child != null) {
          targetType = 'CHILD';
          targetId = child.id;
        }
      }

      final queryParams = {
        'target_type': targetType,
        'target_id': targetId,
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
        final data = jsonDecode(response.body);
        final summary = data['summary'];
        final List<dynamic> recentMealsRaw = data['recent_meals'];

        // Targets
        int targetCal = targetType == 'MOTHER' ? 2550 : 1400;
        int targetProtein = targetType == 'MOTHER' ? 75 : 40;
        int targetIron = targetType == 'MOTHER' ? 27 : 10;
        int targetFat = targetType == 'MOTHER' ? 67 : 45;
        int targetCalcium = targetType == 'MOTHER' ? 1200 : 800;

        // Safe parsing helpers
        int parseInt(dynamic value) => value is num ? value.toInt() : (int.tryParse(value?.toString() ?? '') ?? 0);
        double parseDouble(dynamic value) => value is num ? value.toDouble() : (double.tryParse(value?.toString() ?? '') ?? 0.0);

        final currentCal = parseInt(summary['current_calories']);
        final currentProtein = parseDouble(summary['protein_g']);
        final currentIron = parseDouble(summary['iron_mg']);
        final currentFat = parseDouble(summary['fat_g']);
        final currentCalcium = parseDouble(summary['calcium_mg']);
        
        // Recent meals mapping
        final meals = recentMealsRaw.reversed.take(3).map((m) {
          final time = DateTime.parse(m['meal_time']);
          return FoodHistoryItem(
            name: m['food_name_detected'],
            time: DateFormat('HH:mm').format(time) + ' WIB',
            calories: parseInt(m['calories_kcal']),
            imagePath: m['photo_url'] ?? 'assets/images/placeholder.png',
            isSaved: true,
          );
        }).toList();


        state = state.copyWith(
          currentCalories: currentCal,
          targetCalories: targetCal,
          caloryPercentage: (currentCal / targetCal).clamp(0, 1).toDouble(),
          proteinPercentage: (currentProtein / targetProtein).clamp(0, 1).toDouble(),
          ironPercentage: (currentIron / targetIron).clamp(0, 1).toDouble(),
          calciumPercentage: (currentCalcium / targetCalcium).clamp(0, 1).toDouble(),
          fatPercentage: (currentFat / targetFat).clamp(0, 1).toDouble(),
          recentMeals: meals,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      print("Error fetching dashboard summary: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  void setActiveProfile(String profileName) {
    if (state.activeProfileName == profileName) return;
    state = state.copyWith(activeProfileName: profileName);
    fetchSummary();
  }

  Future<void> triggerDailySummaryNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // Get Mother Summary
      final motherUri = Uri.parse('${ApiConstants.apiBaseUrl}/dashboard/summary?target_type=MOTHER&target_id=${_profileState.motherId}');
      final motherRes = await http.get(
        motherUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      
      String bodyText = "";
      if (motherRes.statusCode == 200) {
        final mData = jsonDecode(motherRes.body)['summary'];
        bodyText += "Ibu: ${(mData['current_calories'] as num).toInt()} / 2550 kkal. ";
      }

      // Get Child Summary if exists
      if (_profileState.children.isNotEmpty) {
        final child = _profileState.children.first;
        final childUri = Uri.parse('${ApiConstants.apiBaseUrl}/dashboard/summary?target_type=CHILD&target_id=${child.id}');
        final childRes = await http.get(
          childUri,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
        if (childRes.statusCode == 200) {
          final cData = jsonDecode(childRes.body)['summary'];
          bodyText += "${child.name}: ${(cData['current_calories'] as num).toInt()} / 1400 kkal.";
        }
      }

      if (bodyText.isNotEmpty) {
        await NotificationService.showNotification(
          id: 100,
          title: "Rekapan Gizi NutriVision Hari Ini",
          body: bodyText + " Tetap jaga asupan sehat ya!",
        );
      }
    } catch (e) {
      print("Error triggering notification: $e");
    }
  }
}
