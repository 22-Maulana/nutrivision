<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\FoodLog;
use Carbon\Carbon;
use Illuminate\Support\Facades\Validator;

class FoodLogController extends Controller
{
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'target_type' => 'required|in:MOTHER,CHILD',
            'target_id' => 'required|uuid',
            'meal_time' => 'required|date',
            'food_name_detected' => 'required|string|max:255',
            'recommendation_status' => 'required|string',
            'calories_kcal' => 'required|numeric',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $foodLog = FoodLog::create([
            'user_id' => $request->user()->id,
            'target_type' => $request->target_type,
            'target_id' => $request->target_id,
            'meal_time' => Carbon::parse($request->meal_time),
            'photo_url' => $request->photo_url,
            'food_name_detected' => $request->food_name_detected,
            'notes' => $request->notes,
            'recommendation_status' => $request->recommendation_status,
            'calories_kcal' => $request->calories_kcal ?? 0,
            'protein_g' => $request->protein_g ?? 0,
            'fat_g' => $request->fat_g ?? 0,
            'carbs_g' => $request->carbs_g ?? 0,
            'fiber_g' => $request->fiber_g ?? 0,
            'iron_mg' => $request->iron_mg ?? 0,
            'calcium_mg' => $request->calcium_mg ?? 0,
        ]);

        return response()->json([
            'message' => 'Food log successfully saved',
            'data' => $foodLog
        ], 201);
    }

    public function getSummary(Request $request)
    {
        $query = FoodLog::where('user_id', $request->user()->id);

        if ($request->has('target_type')) {
            $query->where('target_type', $request->target_type);
        }

        if ($request->has('target_id')) {
            $query->where('target_id', $request->target_id);
        }

        if ($request->has('start_date') && $request->has('end_date')) {
            $query->whereDate('meal_time', '>=', $request->start_date)
                  ->whereDate('meal_time', '<=', $request->end_date);
        } else if ($request->has('date')) {
            $query->whereDate('meal_time', $request->date);
        } else {
            $query->whereDate('meal_time', Carbon::today());
        }

        $logs = $query->orderBy('meal_time', 'asc')->get();

        $totalCalories = $logs->sum('calories_kcal');
        $totalProtein = $logs->sum('protein_g');
        $totalFat = $logs->sum('fat_g');
        $totalCarbs = $logs->sum('carbs_g');
        $totalFiber = $logs->sum('fiber_g');
        $totalIron = $logs->sum('iron_mg');
        $totalCalcium = $logs->sum('calcium_mg');

        return response()->json([
            'message' => 'Summary retrieved successfully',
            'summary' => [
                'current_calories' => $totalCalories,
                'protein_g' => $totalProtein,
                'fat_g' => $totalFat,
                'carbs_g' => $totalCarbs,
                'fiber_g' => $totalFiber,
                'iron_mg' => $totalIron,
                'calcium_mg' => $totalCalcium,
            ],
            'recent_meals' => $logs
        ]);
    }

    public function index(Request $request)
    {
        $logs = FoodLog::where('user_id', $request->user()->id)
            ->orderBy('meal_time', 'desc')
            ->get();

        return response()->json([
            'message' => 'Food logs retrieved successfully',
            'data' => $logs
        ]);
    }

    public function update(Request $request, $id)
    {
        $log = FoodLog::where('user_id', $request->user()->id)->find($id);

        if (!$log) {
            return response()->json(['message' => 'Food log not found'], 404);
        }

        $validator = Validator::make($request->all(), [
            'notes' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $log->update([
            'notes' => $request->notes
        ]);

        return response()->json([
            'message' => 'Food log notes updated successfully',
            'data' => $log
        ]);
    }

    public function destroy(Request $request, $id)
    {
        $log = FoodLog::where('user_id', $request->user()->id)->find($id);

        if (!$log) {
            return response()->json(['message' => 'Food log not found'], 404);
        }

        $log->delete();

        return response()->json([
            'message' => 'Food log deleted successfully'
        ]);
    }
}
