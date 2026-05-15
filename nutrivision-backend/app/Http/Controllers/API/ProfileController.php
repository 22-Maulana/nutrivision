<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\ChildProfile;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;
use App\Models\MotherProfile;

class ProfileController extends Controller
{
    public function storeChild(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'birth_date' => 'required|date',
            'gender' => 'required|in:L,P',
            'allergies' => 'nullable|array',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $child = ChildProfile::create([
            'user_id' => $request->user()->id,
            'name' => $request->name,
            'birth_date' => Carbon::parse($request->birth_date),
            'gender' => $request->gender,
            'allergies' => $request->allergies ?? [],
        ]);

        return response()->json([
            'message' => 'Child profile successfully created',
            'data' => $child
        ], 201);
    }

    public function updateMotherProfile(Request $request)
    {
        $user = $request->user();
        $profile = $user->motherProfile;

        if (!$profile) {
            $profile = MotherProfile::create([
                'user_id' => $user->id,
                'full_name' => $user->name,
                'birth_date' => now()->subYears(25)->toDateString(),
                'status' => 'Sedang Menyusui',
                'allergies' => [],
            ]);
        }

        $profile->update([
            'birth_date' => $request->birth_date ?? $profile->birth_date,
            'status' => $request->status ?? $profile->status,
            'allergies' => $request->allergies ?? $profile->allergies,
        ]);

        return response()->json([
            'message' => 'Mother profile updated successfully',
            'data' => $profile
        ]);
    }

    public function getProfile(Request $request)
    {
        $user = $request->user()->load(['motherProfile', 'childrenProfiles']);

        return response()->json([
            'message' => 'Profile retrieved successfully',
            'data' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'mother_profile' => $user->motherProfile,
                'children' => $user->childrenProfiles,
            ]
        ]);
    }
}
