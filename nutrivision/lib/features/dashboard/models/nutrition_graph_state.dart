import 'package:flutter/material.dart';

class NutritionGraphState {
  final String activeProfileName;
  final String activeTab;
  final String currentDateText;
  
  final double caloryPercentage;
  final int currentCalories;
  final int targetCalories;
  final int remainingCalories;

  final Map<String, MacroNutrientInfo> macros;
  final List<TimelineMealInfo> mealsTimeline;
  final bool isLoading;

  NutritionGraphState({
    required this.activeProfileName,
    required this.activeTab,
    required this.currentDateText,
    required this.caloryPercentage,
    required this.currentCalories,
    required this.targetCalories,
    required this.remainingCalories,
    required this.macros,
    required this.mealsTimeline,
    this.isLoading = false,
  });

  NutritionGraphState copyWith({
    String? activeProfileName,
    String? activeTab,
    String? currentDateText,
    double? caloryPercentage,
    int? currentCalories,
    int? targetCalories,
    int? remainingCalories,
    Map<String, MacroNutrientInfo>? macros,
    List<TimelineMealInfo>? mealsTimeline,
    bool? isLoading,
  }) {
    return NutritionGraphState(
      activeProfileName: activeProfileName ?? this.activeProfileName,
      activeTab: activeTab ?? this.activeTab,
      currentDateText: currentDateText ?? this.currentDateText,
      caloryPercentage: caloryPercentage ?? this.caloryPercentage,
      currentCalories: currentCalories ?? this.currentCalories,
      targetCalories: targetCalories ?? this.targetCalories,
      remainingCalories: remainingCalories ?? this.remainingCalories,
      macros: macros ?? this.macros,
      mealsTimeline: mealsTimeline ?? this.mealsTimeline,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MacroNutrientInfo {
  final int current;
  final int target;
  final double percentage;

  MacroNutrientInfo({
    required this.current,
    required this.target,
    required this.percentage,
  });
}

class TimelineMealInfo {
  final String time;
  final String name;
  final int calories;
  final IconData icon;
  final Color iconColor;

  TimelineMealInfo({
    required this.time,
    required this.name,
    required this.calories,
    required this.icon,
    required this.iconColor,
  });
}
