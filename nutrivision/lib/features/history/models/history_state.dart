enum HistoryPeriod { daily, weekly, monthly }

class HistoryState {
  final int selectedDayIndex;
  final DateTime selectedDate;
  final HistoryPeriod selectedPeriod;
  final String dateText;
  final List<DailyMealItem> meals;
  final DailySummary summary;
  final bool isLoading;
  final String? error;

  HistoryState({
    required this.selectedDayIndex,
    required this.selectedDate,
    required this.selectedPeriod,
    required this.dateText,
    required this.meals,
    required this.summary,
    this.isLoading = false,
    this.error,
  });

  HistoryState copyWith({
    int? selectedDayIndex,
    DateTime? selectedDate,
    HistoryPeriod? selectedPeriod,
    String? dateText,
    List<DailyMealItem>? meals,
    DailySummary? summary,
    bool? isLoading,
    String? error,
  }) {
    return HistoryState(
      selectedDayIndex: selectedDayIndex ?? this.selectedDayIndex,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      dateText: dateText ?? this.dateText,
      meals: meals ?? this.meals,
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class DailyMealItem {
  final String name;
  final String time;
  final int calories;
  final String recommendation;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;
  final String reason;

  DailyMealItem({
    required this.name,
    required this.time,
    required this.calories,
    required this.recommendation,
    required this.protein,
    required this.fat,
    required this.carbs,
    this.fiber = 0.0,
    this.reason = '',
  });
}

class DailySummary {
  final int currentCalories;
  final int targetCalories;
  final int currentProtein;
  final int targetProtein;
  final int currentCarbs;
  final int targetCarbs;

  DailySummary({
    required this.currentCalories,
    required this.targetCalories,
    required this.currentProtein,
    required this.targetProtein,
    required this.currentCarbs,
    required this.targetCarbs,
  });
}
