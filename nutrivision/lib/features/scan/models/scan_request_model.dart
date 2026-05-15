class ScanRequestModel {
  final String? imagePath;
  final String targetProfileName;
  final String notes;

  ScanRequestModel({
    this.imagePath,
    this.targetProfileName = 'Saya',
    this.notes = '',
  });

  ScanRequestModel copyWith({
    String? imagePath,
    String? targetProfileName,
    String? notes,
  }) {
    return ScanRequestModel(
      imagePath: imagePath ?? this.imagePath,
      targetProfileName: targetProfileName ?? this.targetProfileName,
      notes: notes ?? this.notes,
    );
  }
}
