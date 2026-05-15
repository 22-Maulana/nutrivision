import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../models/register_form_state.dart';

// Provider untuk mengelola form registrasi bertahap
final registerFormProvider = StateNotifierProvider<RegisterFormNotifier, RegisterFormState>((ref) {
  return RegisterFormNotifier();
});

class RegisterFormNotifier extends StateNotifier<RegisterFormState> {
  RegisterFormNotifier() : super(RegisterFormState(children: [ChildProfile()]));

  void updateStep1({String? fullName, String? email, String? password}) {
    state = state.copyWith(
      fullName: fullName,
      email: email,
      password: password,
    );
  }

  void updateStep2({
    String? pregnancyStatus,
    String? trimester,
    String? hpl,
    String? motherDob,
    List<String>? motherAllergies,
  }) {
    state = state.copyWith(
      pregnancyStatus: pregnancyStatus,
      trimester: trimester,
      hpl: hpl,
      motherDob: motherDob,
      motherAllergies: motherAllergies,
    );
  }

  void updateChild(int index, ChildProfile child) {
    final newChildren = List<ChildProfile>.from(state.children);
    if (index >= 0 && index < newChildren.length) {
      newChildren[index] = child;
      state = state.copyWith(children: newChildren);
    }
  }

  void addChild() {
    final newChildren = List<ChildProfile>.from(state.children)..add(ChildProfile());
    state = state.copyWith(children: newChildren);
  }

  void removeChild(int index) {
    final newChildren = List<ChildProfile>.from(state.children);
    if (newChildren.length > 1 && index >= 0 && index < newChildren.length) {
      newChildren.removeAt(index);
      state = state.copyWith(children: newChildren);
    }
  }

  Future<Map<String, dynamic>> submitRegister() async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.register),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': state.fullName,
          'email': state.email,
          'password': state.password,
          'pregnancy_status': state.pregnancyStatus,
          'trimester': state.trimester,
          'hpl': state.hpl.isNotEmpty ? "${state.hpl.split('/')[2]}-${state.hpl.split('/')[0]}-${state.hpl.split('/')[1]}" : null,
          'mother_dob': state.motherDob.isNotEmpty ? "${state.motherDob.split('/')[2]}-${state.motherDob.split('/')[0]}-${state.motherDob.split('/')[1]}" : null,
          'mother_allergies': state.motherAllergies,
          'children': state.children.map((c) => {
            'name': c.name,
            'birth_date': c.dob.isNotEmpty ? "${c.dob.split('/')[2]}-${c.dob.split('/')[0]}-${c.dob.split('/')[1]}" : null,
            'gender': c.gender == 'Laki-laki' ? 'L' : 'P',
            'allergies': c.allergies,
          }).toList(),
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return {
          'success': true,
          'requires_activation': data['requires_activation'] ?? false,
          'email': state.email,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registrasi gagal',
          'errors': data['errors']
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }
}

// Provider untuk mengelola login dan status autentikasi umum
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<String?>>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AsyncValue<String?>> {
  AuthNotifier() : super(const AsyncValue.data(null));

  Future<Map<String, dynamic>> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = data['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        state = AsyncValue.data(token);
        return {'success': true};
      } else if (response.statusCode == 403 && data['requires_activation'] == true) {
        state = const AsyncValue.data(null);
        return {
          'success': false,
          'requires_activation': true,
          'email': email,
          'message': data['message']
        };
      } else {
        state = const AsyncValue.data(null);
        return {'success': false, 'message': data['message'] ?? 'Login gagal'};
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    state = const AsyncValue.data(null);
  }
}
