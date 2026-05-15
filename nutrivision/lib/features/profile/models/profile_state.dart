class ProfileState {
  final String motherName;
  final String email;
  final String pregnancyStatusText;
  final String breastfeedingStatusText;
  final String motherAvatarPath;
  final List<ChildProfileInfo> children;
  final String motherId;
  final DateTime? motherBirthDate;
  final String motherStatus;
  final List<String> motherAllergies;
  final bool isDarkMode;
  final bool hasNotifications;
  final bool isLoading;

  ProfileState({
    required this.motherId,
    required this.motherName,
    required this.email,
    required this.pregnancyStatusText,
    required this.breastfeedingStatusText,
    required this.motherAvatarPath,
    required this.children,
    required this.motherBirthDate,
    required this.motherStatus,
    required this.motherAllergies,
    required this.isDarkMode,
    required this.hasNotifications,
    this.isLoading = false,
  });

  ProfileState copyWith({
    String? motherId,
    String? motherName,
    String? email,
    String? pregnancyStatusText,
    String? breastfeedingStatusText,
    String? motherAvatarPath,
    List<ChildProfileInfo>? children,
    DateTime? motherBirthDate,
    String? motherStatus,
    List<String>? motherAllergies,
    bool? isDarkMode,
    bool? hasNotifications,
    bool? isLoading,
  }) {
    return ProfileState(
      motherId: motherId ?? this.motherId,
      motherName: motherName ?? this.motherName,
      email: email ?? this.email,
      pregnancyStatusText: pregnancyStatusText ?? this.pregnancyStatusText,
      breastfeedingStatusText: breastfeedingStatusText ?? this.breastfeedingStatusText,
      motherAvatarPath: motherAvatarPath ?? this.motherAvatarPath,
      children: children ?? this.children,
      motherBirthDate: motherBirthDate ?? this.motherBirthDate,
      motherStatus: motherStatus ?? this.motherStatus,
      motherAllergies: motherAllergies ?? this.motherAllergies,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      hasNotifications: hasNotifications ?? this.hasNotifications,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ChildProfileInfo {
  final String id;
  final String name;
  final String ageText;
  final String allergiesText;
  final String initial;
  final String? avatarPath;

  ChildProfileInfo({
    required this.id,
    required this.name,
    required this.ageText,
    required this.allergiesText,
    required this.initial,
    this.avatarPath,
  });
}
