import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:collection/collection.dart';
import '../../../core/constants/api_constants.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/models/profile_state.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../history/providers/history_provider.dart';
import '../models/scan_request_model.dart';
import '../models/scan_response_model.dart';

final scanProvider = StateNotifierProvider<ScanNotifier, ScanRequestModel>((ref) {
  return ScanNotifier(ref);
});

class ScanNotifier extends StateNotifier<ScanRequestModel> {
  final Ref _ref;

  ScanNotifier(this._ref) : super(ScanRequestModel());
  final ImagePicker _picker = ImagePicker();

  void setTargetProfile(String profile) {
    state = state.copyWith(targetProfileName: profile);
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 80,
      );
      if (image != null) {
        state = state.copyWith(imagePath: image.path);
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  void removeImage() {
    state = state.copyWith(imagePath: '');
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  Future<ScanResponseModel?> analyzeFood() async {
    if (state.imagePath == null || state.imagePath!.isEmpty) {
      print("No image selected");
      return null;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final profileState = _ref.read(profileProvider);

      // Tentukan informasi target berdasarkan profil yang dipilih
      String targetType = 'MOTHER';
      String targetId = profileState.motherId;
      
      if (state.targetProfileName != 'Saya') {
        final child = profileState.children.firstWhereOrNull(
          (c) => c.name == state.targetProfileName,
        );
        if (child != null) {
          targetType = 'CHILD';
          targetId = child.id;
        }
      }

      if (targetId.isEmpty) {
        print("Error: target_id is empty. Profile might not be loaded yet.");
        return null;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.scan),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['target_type'] = targetType;
      request.fields['target_id'] = targetId;
      request.fields['notes'] = state.notes ?? '';

      request.files.add(
        await http.MultipartFile.fromPath('image', state.imagePath!),
      );


      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body)['data'];
        
        return ScanResponseModel(
          foodName: data['food_name_detected'] ?? 'Makanan',
          portionDesc: '1 Porsi', 
          suggestionNote: data['notes'] ?? '',
          recommendationStatus: data['recommendation_status'] ?? 'MODERATE',
          reasoning: data['notes'] ?? '',
          calories: double.tryParse(data['calories_kcal']?.toString() ?? '0') ?? 0.0,
          caloriesAkg: 20, 
          protein: double.tryParse(data['protein_g']?.toString() ?? '0') ?? 0.0,
          proteinAkg: 20,
          carbs: double.tryParse(data['carbs_g']?.toString() ?? '0') ?? 0.0,
          carbsAkg: 20,
          fat: double.tryParse(data['fat_g']?.toString() ?? '0') ?? 0.0,
          fatAkg: 20,
          micronutrients: {
            'Zat Besi (Iron)': double.tryParse(data['iron_mg']?.toString() ?? '0') ?? 0.0,
            'Kalsium': double.tryParse(data['calcium_mg']?.toString() ?? '0') ?? 0.0,
            'Serat': double.tryParse(data['fiber_g']?.toString() ?? '0') ?? 0.0,
          },
        );
      } else {
        print("API Error: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Scan Request Error: $e");
      return null;
    }
  }

  Future<void> saveToHistory(ScanResponseModel result) async {
    _ref.read(dashboardProvider.notifier).fetchSummary();
    _ref.read(historyProvider.notifier).fetchHistory();
  }
}
