class RegisterFormState {
  // Step 1
  final String fullName;
  final String email;
  final String password;

  // Step 2
  final String pregnancyStatus; // 'Sedang Hamil' atau 'Sedang Menyusui' atau ''
  final String trimester; // 'Trim 1', 'Trim 2', 'Trim 3'
  final String hpl; // YYYY-MM-DD
  final String motherDob; // YYYY-MM-DD
  final List<String> motherAllergies;

  // Step 3 (List of children)
  final List<ChildProfile> children;

  RegisterFormState({
    this.fullName = '',
    this.email = '',
    this.password = '',
    this.pregnancyStatus = '',
    this.trimester = '',
    this.hpl = '',
    this.motherDob = '',
    this.motherAllergies = const [],
    this.children = const [],
  });

  RegisterFormState copyWith({
    String? fullName,
    String? email,
    String? password,
    String? pregnancyStatus,
    String? trimester,
    String? hpl,
    String? motherDob,
    List<String>? motherAllergies,
    List<ChildProfile>? children,
  }) {
    return RegisterFormState(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      pregnancyStatus: pregnancyStatus ?? this.pregnancyStatus,
      trimester: trimester ?? this.trimester,
      hpl: hpl ?? this.hpl,
      motherDob: motherDob ?? this.motherDob,
      motherAllergies: motherAllergies ?? this.motherAllergies,
      children: children ?? this.children,
    );
  }
}

class ChildProfile {
  final String name;
  final String dob;
  final String gender;
  final List<String> allergies;

  ChildProfile({
    this.name = '',
    this.dob = '',
    this.gender = '',
    this.allergies = const [],
  });

  ChildProfile copyWith({
    String? name,
    String? dob,
    String? gender,
    List<String>? allergies,
  }) {
    return ChildProfile(
      name: name ?? this.name,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      allergies: allergies ?? this.allergies,
    );
  }
}
