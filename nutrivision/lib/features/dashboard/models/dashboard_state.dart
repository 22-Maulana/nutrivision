class DashboardState {
  final String userName;
  final String currentDate;
  final String activeProfileName;
  final double caloryPercentage;
  final int currentCalories;
  final int targetCalories;
  final double proteinPercentage;
  final double ironPercentage;
  final double fatPercentage;
  final double calciumPercentage;
  final List<FoodHistoryItem> recentMeals;
  final bool isLoading;

  DashboardState({
    required this.userName,
    required this.currentDate,
    required this.activeProfileName,
    required this.caloryPercentage,
    required this.currentCalories,
    required this.targetCalories,
    required this.proteinPercentage,
    required this.ironPercentage,
    required this.fatPercentage,
    required this.calciumPercentage,
    required this.recentMeals,
    this.isLoading = false,
  });

  DashboardState copyWith({
    String? userName,
    String? currentDate,
    String? activeProfileName,
    double? caloryPercentage,
    int? currentCalories,
    int? targetCalories,
    double? proteinPercentage,
    double? ironPercentage,
    double? fatPercentage,
    double? calciumPercentage,
    List<FoodHistoryItem>? recentMeals,
    bool? isLoading,
  }) {
    return DashboardState(
      userName: userName ?? this.userName,
      currentDate: currentDate ?? this.currentDate,
      activeProfileName: activeProfileName ?? this.activeProfileName,
      caloryPercentage: caloryPercentage ?? this.caloryPercentage,
      currentCalories: currentCalories ?? this.currentCalories,
      targetCalories: targetCalories ?? this.targetCalories,
      proteinPercentage: proteinPercentage ?? this.proteinPercentage,
      ironPercentage: ironPercentage ?? this.ironPercentage,
      fatPercentage: fatPercentage ?? this.fatPercentage,
      calciumPercentage: calciumPercentage ?? this.calciumPercentage,
      recentMeals: recentMeals ?? this.recentMeals,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FoodHistoryItem {
  final String name;
  final String time;
  final int calories;
  final String imagePath;
  final bool isSaved;

  FoodHistoryItem({
    required this.name,
    required this.time,
    required this.calories,
    required this.imagePath,
    required this.isSaved,
  });
}
