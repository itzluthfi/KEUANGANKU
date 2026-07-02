<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $request->validate([
            'email' => 'required|email|unique:users',
            'password' => 'required|min:6',
        ]);

        $user = User::create([
            'name' => explode('@', $request->email)[0],
            'email' => $request->email,
            'password' => Hash::make($request->password),
        ]);

        $token = $user->createToken('DanakuAppToken')->plainTextToken;

        return response()->json([
            'message' => 'Pendaftaran sukses!',
            'token' => $token,
            'user' => $user
        ], 201);
    }

    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        $user = User::where('email', $request->email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json(['message' => 'Kredensial salah!'], 401);
        }

        // Token ini akan disimpan di SQLite HP Anda untuk hak akses selanjutnya
        $token = $user->createToken('DanakuAppToken')->plainTextToken;

        return response()->json([
            'message' => 'Login Berhasil!',
            'token' => $token,
            'email' => $user->email
        ], 200);
    }
}
