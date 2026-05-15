class GrowthState {
  final String selectedChildName;
  final String targetId;
  final String targetType;
  final String growthStatusText;
  final String childInfoText;
  final double tbUsiaSd;
  final double bbUsiaSd;
  final double bbTbSd;
  final String lastUpdatedText;
  final List<GrowthMeasurement> measurements;
  final String activeChartTab;
  final bool isLoading;

  GrowthState({
    required this.selectedChildName,
    required this.targetId,
    required this.targetType,
    required this.growthStatusText,
    required this.childInfoText,
    required this.tbUsiaSd,
    required this.bbUsiaSd,
    required this.bbTbSd,
    required this.lastUpdatedText,
    required this.measurements,
    required this.activeChartTab,
    this.isLoading = false,
  });

  GrowthState copyWith({
    String? selectedChildName,
    String? targetId,
    String? targetType,
    String? growthStatusText,
    String? childInfoText,
    double? tbUsiaSd,
    double? bbUsiaSd,
    double? bbTbSd,
    String? lastUpdatedText,
    List<GrowthMeasurement>? measurements,
    String? activeChartTab,
    bool? isLoading,
  }) {
    return GrowthState(
      selectedChildName: selectedChildName ?? this.selectedChildName,
      targetId: targetId ?? this.targetId,
      targetType: targetType ?? this.targetType,
      growthStatusText: growthStatusText ?? this.growthStatusText,
      childInfoText: childInfoText ?? this.childInfoText,
      tbUsiaSd: tbUsiaSd ?? this.tbUsiaSd,
      bbUsiaSd: bbUsiaSd ?? this.bbUsiaSd,
      bbTbSd: bbTbSd ?? this.bbTbSd,
      lastUpdatedText: lastUpdatedText ?? this.lastUpdatedText,
      measurements: measurements ?? this.measurements,
      activeChartTab: activeChartTab ?? this.activeChartTab,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class GrowthMeasurement {
  final String date;
  final double weightKg;
  final double heightCm;
  final String status;

  GrowthMeasurement({
    required this.date,
    required this.weightKg,
    required this.heightCm,
    required this.status,
  });
}
