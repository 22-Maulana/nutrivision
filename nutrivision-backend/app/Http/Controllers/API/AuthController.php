<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\User;
use App\Models\MotherProfile;
use App\Models\ChildProfile;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Mail;
use App\Mail\ActivationMail;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:6',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $otpCode = str_pad(random_int(100000, 999999), 6, '0', STR_PAD_LEFT);

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'role' => 'MOTHER',
            'is_active' => false,
            'otp_code' => $otpCode,
        ]);

        // Create mother profile from request
        MotherProfile::create([
            'user_id' => $user->id,
            'full_name' => $user->name,
            'birth_date' => $request->mother_dob ?? now()->subYears(25)->toDateString(),
            'status' => $request->pregnancy_status ?? 'Sedang Menyusui',
            'allergies' => $request->mother_allergies ?? [],
        ]);

        // Create child profiles if provided
        if ($request->has('children') && is_array($request->children)) {
            foreach ($request->children as $childData) {
                if (!empty($childData['name'])) {
                    ChildProfile::create([
                        'user_id' => $user->id,
                        'name' => $childData['name'],
                        'birth_date' => $childData['birth_date'] ?? now()->toDateString(),
                        'gender' => $childData['gender'] ?? 'L',
                        'allergies' => $childData['allergies'] ?? [],
                    ]);
                }
            }
        }

        // Kirim OTP via Email
        Mail::to($user->email)->send(new ActivationMail($otpCode));

        return response()->json([
            'message' => 'User successfully registered. Please verify OTP.',
            'requires_activation' => true,
            'email' => $user->email,
            'debug_otp' => $otpCode // HANYA UNTUK DEVELOPMENT, HAPUS SAAT PRODUCTION
        ], 201);
    }

    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|string|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'message' => 'Invalid login credentials'
            ], 401);
        }

        if (!$user->is_active) {
            $otpCode = str_pad(random_int(100000, 999999), 6, '0', STR_PAD_LEFT);
            $user->update(['otp_code' => $otpCode]);
            
            // Kirim ulang OTP jika mencoba login tapi belum aktif
            Mail::to($user->email)->send(new ActivationMail($otpCode));
            
            return response()->json([
                'message' => 'Account not activated. Please verify OTP.',
                'requires_activation' => true,
                'email' => $user->email,
                'debug_otp' => $otpCode
            ], 403);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'User logged in',
            'user' => $user,
            'token' => $token,
        ]);
    }

    public function verifyOtp(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'otp_code' => 'required|string|size:6'
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user) {
            return response()->json(['message' => 'User not found'], 404);
        }

        if ($user->is_active) {
            return response()->json(['message' => 'User is already activated'], 400);
        }

        if ($user->otp_code !== $request->otp_code) {
            return response()->json(['message' => 'Invalid OTP code'], 400);
        }

        $user->update([
            'is_active' => true,
            'otp_code' => null
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Account successfully activated',
            'user' => $user,
            'token' => $token,
        ]);
    }
}
