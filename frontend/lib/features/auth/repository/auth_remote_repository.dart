import 'dart:convert';
import 'dart:io';

import 'package:frontend/core/constants/constants.dart';
import 'package:frontend/core/services/sp_service.dart';
import 'package:frontend/features/auth/repository/auth_local_repository.dart';
import 'package:frontend/models/user_model.dart';
import 'package:http/http.dart' as http;

class AuthRemoteRepository {
  final spService = SpService();
  final authLocalRepository = AuthLocalRepository();

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("${Constants.backendUri}/auth/signup"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      if (res.statusCode != 201) {
        throw jsonDecode(res.body)["error"];
      }

      return UserModel.fromJson(res.body);
    } catch (e) {
      throw e.toString();
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("${Constants.backendUri}/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (res.statusCode != 200) {
        throw jsonDecode(res.body)["error"];
      }

      return UserModel.fromJson(res.body);
    } catch (e) {
      throw e.toString();
    }
  }

  Future<UserModel?> getUserData() async {
    try {
      final token = await spService.getToken();
      if (token == null) {
        return null;
      }

      final res = await http.post(
        Uri.parse("${Constants.backendUri}/auth/tokenIsValid"),
        headers: {"Content-Type": "application/json", "x-auth-token": token},
      );

      if (res.statusCode != 200 || jsonDecode(res.body) == false) {
        return null;
      }

      final userResponse = await http.get(
        Uri.parse("${Constants.backendUri}/auth"),
        headers: {"Content-Type": "application/json", "x-auth-token": token},
      );

      if (userResponse.statusCode != 200) {
        throw jsonDecode(userResponse.body)["error"];
      }

      return UserModel.fromJson(userResponse.body);
    } catch (e) {
      final user = await authLocalRepository.getUser();

      return user;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String token,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("${Constants.backendUri}/auth/change-password"),
        headers: {"Content-Type": "application/json", "x-auth-token": token},
        body: jsonEncode({
          "currentPassword": currentPassword,
          "newPassword": newPassword,
        }),
      );

      if (res.statusCode != 200) {
        throw jsonDecode(res.body)["error"];
      }
    } catch (e) {
      throw e.toString();
    }
  }

  Future<UserModel?> updateProfile({
    required String name,
    required String email,
  }) async {
    try {
      final token = await spService.getToken();
      if (token == null) {
        return null;
      }

      final res = await http.put(
        Uri.parse("${Constants.backendUri}/auth/update-profile"),
        headers: {"Content-Type": "application/json", "x-auth-token": token},
        body: jsonEncode({"name": name, "email": email}),
      );

      if (res.statusCode == 200) {
        return UserModel.fromJson(res.body);
      } else {
        final errorData = jsonDecode(res.body);
        final errorMessage = errorData["error"] ?? "Unknown error";
        throw errorMessage.toString();
      }
    } catch (e) {
      throw e.toString();
    }
  }

  Future<String> uploadProfileImage(File imageFile) async {
    try {
      final token = await spService.getToken();
      if (token == null) {
        throw "Unauthorized";
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse("${Constants.backendUri}/auth/upload-profile-image"),
      );

      request.headers['x-auth-token'] = token;

      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['imageUrl']; // adjust based on your backend response
      } else {
        final errorData = jsonDecode(response.body);
        throw errorData["error"] ?? "Failed to upload image";
      }
    } catch (e) {
      throw e.toString();
    }
  }

  Future<UserModel> updateProfileImageUrl(String imageUrl) async {
    try {
      final token = await spService.getToken();
      if (token == null) {
        throw "Unauthorized";
      }

      final res = await http.put(
        Uri.parse("${Constants.backendUri}/auth/update-profile-image"),
        headers: {"Content-Type": "application/json", "x-auth-token": token},
        body: jsonEncode({"profileImage": imageUrl}),
      );

      if (res.statusCode == 200) {
        return UserModel.fromJson(res.body);
      } else {
        final errorData = jsonDecode(res.body);
        throw errorData["error"] ?? "Failed to update profile image";
      }
    } catch (e) {
      throw e.toString();
    }
  }

  Future<UserModel> removeProfileImage() async {
    try {
      final token = await spService.getToken();
      if (token == null) throw "Token not found";

      final res = await http.put(
        Uri.parse("${Constants.backendUri}/auth/remove-profile-image"),
        headers: {"Content-Type": "application/json", "x-auth-token": token},
      );

      if (res.statusCode != 200) {
        throw jsonDecode(res.body)["error"];
      }

      return UserModel.fromJson(res.body);
    } catch (e) {
      throw e.toString();
    }
  }
}
