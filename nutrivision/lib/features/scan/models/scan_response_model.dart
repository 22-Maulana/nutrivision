class ScanResponseModel {
  final String foodName;
  final String portionDesc;
  final String suggestionNote;
  final String recommendationStatus;
  final String reasoning;
  
  final double calories;
  final int caloriesAkg;
  final double protein;
  final int proteinAkg;
  final double carbs;
  final int carbsAkg;
  final double fat;
  final int fatAkg;

  final Map<String, double> micronutrients;

  ScanResponseModel({
    required this.foodName,
    required this.portionDesc,
    required this.suggestionNote,
    required this.recommendationStatus,
    required this.reasoning,
    required this.calories,
    required this.caloriesAkg,
    required this.protein,
    required this.proteinAkg,
    required this.carbs,
    required this.carbsAkg,
    required this.fat,
    required this.fatAkg,
    required this.micronutrients,
  });
}
