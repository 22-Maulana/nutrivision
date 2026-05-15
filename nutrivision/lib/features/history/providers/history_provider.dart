import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/models/profile_state.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/models/dashboard_state.dart';
import '../models/history_state.dart';

final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  final profileState = ref.watch(profileProvider);
  final dashboardState = ref.watch(dashboardProvider);
  return HistoryNotifier(ref, profileState, dashboardState);
});

class HistoryNotifier extends StateNotifier<HistoryState> {
  final Ref _ref;
  final ProfileState _profileState;
  final DashboardState _dashboardState;

  HistoryNotifier(this._ref, this._profileState, this._dashboardState) : super(_initialState()) {
    if (_profileState.motherName != 'Loading...') {
      fetchHistory();
    }
  }

  static HistoryState _initialState() {
    final now = DateTime.now();
    return HistoryState(
      selectedDayIndex: 4, 
      selectedDate: now,
      selectedPeriod: HistoryPeriod.daily,
      dateText: DateFormat('EEEE, d MMMM yyyy', 'id').format(now),
      meals: [],
      summary: DailySummary(
        currentCalories: 0,
        targetCalories: 2200,
        currentProtein: 0,
        targetProtein: 75,
        currentCarbs: 0,
        targetCarbs: 300,
      ),
      isLoading: true,
    );
  }

  Future<void> fetchHistory() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      String targetType = 'MOTHER';
      String targetId = _profileState.motherId;

      if (_dashboardState.activeProfileName != 'Saya') {
        final child = _profileState.children.firstWhereOrNull(
          (c) => c.name == _dashboardState.activeProfileName,
        );
        if (child != null) {
          targetType = 'CHILD';
          targetId = child.id;
        }
      }

      final Map<String, String> queryParams = {
        'target_type': targetType,
        'target_id': targetId,
      };

      if (state.selectedPeriod == HistoryPeriod.daily) {
        queryParams['date'] = DateFormat('yyyy-MM-dd').format(state.selectedDate);
      } else if (state.selectedPeriod == HistoryPeriod.weekly) {
        final now = DateTime.now();
        final startDate = now.subtract(const Duration(days: 6));
        queryParams['start_date'] = DateFormat('yyyy-MM-dd').format(startDate);
        queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(now);
      } else if (state.selectedPeriod == HistoryPeriod.monthly) {
        final now = DateTime.now();
        final startDate = now.subtract(const Duration(days: 29));
        queryParams['start_date'] = DateFormat('yyyy-MM-dd').format(startDate);
        queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(now);
      }

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
        
        final meals = recentMealsRaw.map((item) {
          final DateTime dt = DateTime.parse(item['meal_time']);
          String timeStr;
          if (state.selectedPeriod == HistoryPeriod.daily) {
            timeStr = DateFormat('HH:mm').format(dt);
          } else {
            timeStr = DateFormat('d MMM, HH:mm', 'id').format(dt);
          }
          
          // Safe parsing helpers
          int parseInt(dynamic value) => value is num ? value.toInt() : (int.tryParse(value?.toString() ?? '') ?? 0);
          double parseDouble(dynamic value) => value is num ? value.toDouble() : (double.tryParse(value?.toString() ?? '') ?? 0.0);

          return DailyMealItem(
            name: item['food_name_detected'],
            time: timeStr,
            calories: parseInt(item['calories_kcal']),
            recommendation: item['recommendation_status'] ?? 'Dianjurkan',
            protein: parseDouble(item['protein_g']),
            fat: parseDouble(item['fat_g']),
            carbs: parseDouble(item['carbs_g']),
            fiber: parseDouble(item['fiber_g']),
            reason: item['notes'] ?? '',
          );
        }).toList();

        // Adjust targets based on period
        int multiplier = 1;
        if (state.selectedPeriod == HistoryPeriod.weekly) multiplier = 7;
        if (state.selectedPeriod == HistoryPeriod.monthly) multiplier = 30;

        int baseCal = targetType == 'MOTHER' ? 2550 : 1400;
        int baseProt = 75;
        int baseCarbs = 300;

        if (!mounted) return;
        
        int parseInt(dynamic value) => value is num ? value.toInt() : (int.tryParse(value?.toString() ?? '') ?? 0);

        state = state.copyWith(
          meals: meals,
          summary: DailySummary(
            currentCalories: parseInt(summary['current_calories']),
            targetCalories: baseCal * multiplier,
            currentProtein: parseInt(summary['protein_g']),
            targetProtein: baseProt * multiplier,
            currentCarbs: parseInt(summary['carbs_g']),
            targetCarbs: baseCarbs * multiplier,
          ),
          isLoading: false,
        );

      } else {
        if (!mounted) return;
        state = state.copyWith(isLoading: false, error: 'Gagal mengambil data riwayat');
      }
    } catch (e) {
      print("Error fetching history: $e");
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: 'Error: $e');
    }
  }

  void setPeriod(HistoryPeriod period) {
    if (state.selectedPeriod == period) return;
    state = state.copyWith(selectedPeriod: period);
    fetchHistory();
  }

  void selectDay(int index, String dateText) {
    if (state.selectedDayIndex == index) return;
    final selectedDate = DateTime.now().subtract(Duration(days: (4 - index).toInt()));
    state = state.copyWith(selectedDayIndex: index, selectedDate: selectedDate, dateText: dateText, selectedPeriod: HistoryPeriod.daily);
    fetchHistory();
  }

  void selectCustomDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(DateTime(date.year, date.month, date.day)).inDays;
    int index = -1;
    
    // Check if it's within the last 5 days
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(selectedDay).inDays;
    
    if (diff >= 0 && diff <= 4) {
      index = 4 - diff;
    }
    
    state = state.copyWith(
      selectedDayIndex: index,
      selectedDate: date,
      dateText: DateFormat('EEEE, d MMMM yyyy', 'id').format(date),
      selectedPeriod: HistoryPeriod.daily
    );
    fetchHistory();
  }

  Future<void> deleteHistory(DailyMealItem meal) async {
    // Logic to delete log via API
    fetchHistory(); // Refresh
  }

  Future<void> editHistory(DailyMealItem meal) async {
    // Logic to edit log via API
    fetchHistory(); // Refresh
  }
}
