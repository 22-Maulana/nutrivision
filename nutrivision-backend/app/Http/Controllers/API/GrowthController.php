<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\GrowthRecord;
use Carbon\Carbon;
use Illuminate\Support\Facades\Validator;

class GrowthController extends Controller
{
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'target_type' => 'required|in:MOTHER,CHILD',
            'target_id' => 'required|uuid',
            'measured_at' => 'required|date',
            'weight_kg' => 'required|numeric',
            'height_cm' => 'required|numeric',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $record = GrowthRecord::create([
            'target_type' => $request->target_type,
            'target_id' => $request->target_id,
            'measured_at' => Carbon::parse($request->measured_at),
            'weight_kg' => $request->weight_kg,
            'height_cm' => $request->height_cm,
            'status' => 'Normal',
        ]);

        return response()->json([
            'message' => 'Growth record successfully saved',
            'data' => $record
        ], 201);
    }

    public function index(Request $request)
    {
        $request->validate([
            'target_type' => 'required|in:MOTHER,CHILD',
            'target_id' => 'required|uuid',
        ]);

        $records = GrowthRecord::where('target_type', $request->target_type)
            ->where('target_id', $request->target_id)
            ->orderBy('measured_at', 'asc')
            ->get();

        return response()->json([
            'message' => 'Growth records retrieved successfully',
            'data' => $records
        ]);
    }
}
