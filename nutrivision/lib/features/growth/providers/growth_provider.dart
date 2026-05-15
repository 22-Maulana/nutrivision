import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/models/profile_state.dart';
import '../models/growth_state.dart';

final growthProvider = StateNotifierProvider<GrowthNotifier, GrowthState>((ref) {
  final profileState = ref.watch(profileProvider);
  return GrowthNotifier(ref, profileState);
});

class GrowthNotifier extends StateNotifier<GrowthState> {
  final Ref _ref;
  final ProfileState _profileState;

  GrowthNotifier(this._ref, this._profileState) : super(_initialState()) {
    if (_profileState.motherId.isNotEmpty) {
      _initDefaultProfile();
    }
  }

  void _initDefaultProfile() {
    if (_profileState.motherId.isEmpty) return;

    // Default to Mother if no children, otherwise first child
    if (_profileState.children.isNotEmpty) {
      final child = _profileState.children.first;
      state = state.copyWith(
        selectedChildName: child.name,
        targetId: child.id,
        targetType: 'CHILD',
        childInfoText: '${child.name} · ${child.ageText}',
      );
    } else {
      state = state.copyWith(
        selectedChildName: 'Saya (Ibu)',
        targetId: _profileState.motherId,
        targetType: 'MOTHER',
        childInfoText: _profileState.motherName,
      );
    }
    
    // Use future delayed to avoid calling state update during build
    Future.delayed(Duration.zero, () => fetchGrowthRecords());
  }

  static GrowthState _initialState() {
    return GrowthState(
      selectedChildName: 'Loading...',
      targetId: '',
      targetType: 'MOTHER',
      growthStatusText: 'Memuat data...',
      childInfoText: '',
      tbUsiaSd: 0.0,
      bbUsiaSd: 0.0,
      bbTbSd: 0.0,
      lastUpdatedText: '-',
      activeChartTab: 'TB/Usia',
      measurements: [],
      isLoading: false,
    );
  }

  Future<void> fetchGrowthRecords() async {
    if (state.targetId.isEmpty) return;
    
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/growth-records?target_type=${state.targetType}&target_id=${state.targetId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['data'];
        
        // Map data safely
        final measurements = data.map((m) {
          // Use tryParse to handle potential string/null from API
          double weight = double.tryParse(m['weight_kg']?.toString() ?? '0') ?? 0.0;
          double height = double.tryParse(m['height_cm']?.toString() ?? '0') ?? 0.0;
          
          return GrowthMeasurement(
            date: DateFormat('dd MMM yyyy', 'id').format(DateTime.parse(m['measured_at'])),
            weightKg: weight,
            heightCm: height,
            status: m['status'] ?? 'Normal',
          );
        }).toList();

        // Sort by measured_at (raw data) newest first for display
        final List<dynamic> sortedRaw = List.from(data);
        sortedRaw.sort((a, b) => DateTime.parse(b['measured_at']).compareTo(DateTime.parse(a['measured_at'])));

        final latest = sortedRaw.isNotEmpty ? sortedRaw.first : null;
        double tbUsia = 0.0;
        double bbUsia = 0.0;
        double bbTb = 0.0;
        String status = 'Belum ada data';

        if (latest != null) {
          double lWeight = double.tryParse(latest['weight_kg']?.toString() ?? '0') ?? 0.0;
          double lHeight = double.tryParse(latest['height_cm']?.toString() ?? '0') ?? 0.0;

          if (state.targetType == 'MOTHER') {
             tbUsia = 0.5; 
             bbUsia = -0.2;
             bbTb = 0.1;
             status = 'Sehat';
          } else {
             bbUsia = (lWeight - 8.5) / 1.0; 
             tbUsia = (lHeight - 70.0) / 2.5; 
             bbTb = (lWeight / lHeight) * 10; 
             status = bbUsia.abs() < 2 ? 'Normal' : (bbUsia > 2 ? 'Berlebih' : 'Kurang');
          }
        }

        // We want the measurements list in state to be ordered Newest First for the table
        final List<GrowthMeasurement> sortedMeasurements = sortedRaw.map((m) {
          return GrowthMeasurement(
            date: DateFormat('dd MMM yyyy', 'id').format(DateTime.parse(m['measured_at'])),
            weightKg: double.tryParse(m['weight_kg']?.toString() ?? '0') ?? 0.0,
            heightCm: double.tryParse(m['height_cm']?.toString() ?? '0') ?? 0.0,
            status: m['status'] ?? 'Normal',
          );
        }).toList();

        state = state.copyWith(
          measurements: sortedMeasurements,
          lastUpdatedText: sortedMeasurements.isNotEmpty ? sortedMeasurements.first.date : '-',
          growthStatusText: 'Pertumbuhan $status',
          tbUsiaSd: double.parse(tbUsia.toStringAsFixed(1)),
          bbUsiaSd: double.parse(bbUsia.toStringAsFixed(1)),
          bbTbSd: double.parse(bbTb.toStringAsFixed(1)),
          isLoading: false,
        );
      } else {
        print("Growth API Error: ${response.statusCode} - ${response.body}");
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      print("Error fetching growth records: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  void setActiveChartTab(String tab) {
    state = state.copyWith(activeChartTab: tab);
  }

  void setProfile(String name, String id, String type, String info) {
    state = state.copyWith(
      selectedChildName: name,
      targetId: id,
      targetType: type,
      childInfoText: info,
    );
    fetchGrowthRecords();
  }

  Future<bool> addMeasurement(double weight, double height, String dateStr) async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // Convert dd/MM/yyyy to yyyy-MM-dd
      final parts = dateStr.split('/');
      final formattedDate = "${parts[2]}-${parts[1]}-${parts[0]}";

      final response = await http.post(
        Uri.parse('${ApiConstants.apiBaseUrl}/growth-records'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'target_type': state.targetType,
          'target_id': state.targetId,
          'measured_at': formattedDate,
          'weight_kg': weight,
          'height_cm': height,
        }),
      );

      if (response.statusCode == 201) {
        await fetchGrowthRecords();
        return true;
      }
      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      print("Error adding growth record: $e");
      state = state.copyWith(isLoading: false);
      return false;
    }
  }
}
