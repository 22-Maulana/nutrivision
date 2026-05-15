import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/models/profile_state.dart';
import '../models/nutrition_graph_state.dart';

final nutritionGraphProvider = StateNotifierProvider<NutritionGraphNotifier, NutritionGraphState>((ref) {
  final profileState = ref.watch(profileProvider);
  return NutritionGraphNotifier(ref, profileState);
});

class NutritionGraphNotifier extends StateNotifier<NutritionGraphState> {
  final Ref _ref;
  final ProfileState _profileState;

  NutritionGraphNotifier(this._ref, this._profileState) : super(_initialState()) {
    // Initialize with first profile name if available
    if (_profileState.motherName != 'Loading...') {
      _initializeFirstProfile();
    }
  }

  void _initializeFirstProfile() {
    state = state.copyWith(activeProfileName: 'Saya');
    fetchSummary();
  }

  static NutritionGraphState _initialState() {
    return NutritionGraphState(
      activeProfileName: 'Saya',
      activeTab: 'Harian',
      currentDateText: DateFormat('EEEE, d MMMM yyyy', 'id').format(DateTime.now()),
      caloryPercentage: 0,
      currentCalories: 0,
      targetCalories: 2550, // Default target
      remainingCalories: 2550,
      macros: {
        'Karbohidrat': MacroNutrientInfo(current: 0, target: 300, percentage: 0),
        'Protein': MacroNutrientInfo(current: 0, target: 75, percentage: 0),
        'Lemak': MacroNutrientInfo(current: 0, target: 60, percentage: 0),
        'Serat': MacroNutrientInfo(current: 0, target: 25, percentage: 0),
      },
      mealsTimeline: [],
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
        final List<dynamic> recentMeals = data['recent_meals'];

        // Targets (Should ideally come from profile/settings, using defaults for now)
        int targetCal = targetType == 'MOTHER' ? 2550 : 1400;
        int targetCarbs = targetType == 'MOTHER' ? 300 : 150;
        int targetProtein = targetType == 'MOTHER' ? 75 : 40;
        int targetFat = targetType == 'MOTHER' ? 60 : 35;
        int targetFiber = targetType == 'MOTHER' ? 25 : 15;

        final currentCal = (summary['current_calories'] as num).toInt();
        final currentCarbs = (summary['carbs_g'] as num).toInt();
        final currentProtein = (summary['protein_g'] as num).toInt();
        final currentFat = (summary['fat_g'] as num).toInt();
        final currentFiber = (summary['fiber_g'] as num).toInt();

        final meals = recentMeals.map((m) {
          final time = DateTime.parse(m['meal_time']);
          return TimelineMealInfo(
            time: DateFormat('HH:mm').format(time),
            name: m['food_name_detected'],
            calories: (m['calories_kcal'] as num).toInt(),
            icon: _getIconForFood(m['food_name_detected']),
            iconColor: _getIconColorForFood(m['food_name_detected']),
          );
        }).toList();

        state = state.copyWith(
          currentCalories: currentCal,
          targetCalories: targetCal,
          remainingCalories: targetCal - currentCal,
          caloryPercentage: (currentCal / targetCal).clamp(0, 1).toDouble(),
          macros: {
            'Karbohidrat': MacroNutrientInfo(
              current: currentCarbs,
              target: targetCarbs,
              percentage: (currentCarbs / targetCarbs).clamp(0, 1).toDouble(),
            ),
            'Protein': MacroNutrientInfo(
              current: currentProtein,
              target: targetProtein,
              percentage: (currentProtein / targetProtein).clamp(0, 1).toDouble(),
            ),
            'Lemak': MacroNutrientInfo(
              current: currentFat,
              target: targetFat,
              percentage: (currentFat / targetFat).clamp(0, 1).toDouble(),
            ),
            'Serat': MacroNutrientInfo(
              current: currentFiber,
              target: targetFiber,
              percentage: (currentFiber / targetFiber).clamp(0, 1).toDouble(),
            ),
          },
          mealsTimeline: meals,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      print("Error fetching summary: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  IconData _getIconForFood(String name) {
    name = name.toLowerCase();
    if (name.contains('nasi')) return Icons.restaurant;
    if (name.contains('susu')) return Icons.local_cafe;
    if (name.contains('buah')) return Icons.bakery_dining;
    if (name.contains('ayam') || name.contains('daging')) return Icons.kebab_dining;
    return Icons.lunch_dining;
  }

  Color _getIconColorForFood(String name) {
    name = name.toLowerCase();
    if (name.contains('nasi')) return Colors.blue;
    if (name.contains('susu')) return Colors.brown;
    if (name.contains('buah')) return Colors.green;
    return Colors.orange;
  }

  void setActiveProfile(String profileName) {
    if (state.activeProfileName == profileName) return;
    state = state.copyWith(activeProfileName: profileName);
    fetchSummary();
  }

  Future<void> setActiveTab(String tab) async {
    state = state.copyWith(activeTab: tab);
    // In a real app, this might fetch weekly/monthly data
    await fetchSummary();
  }
}
