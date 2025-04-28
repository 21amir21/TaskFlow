import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/services/sp_service.dart';
import 'package:frontend/features/auth/pages/login_page.dart';
import 'package:frontend/features/auth/repository/auth_local_repository.dart';
import 'package:frontend/features/auth/repository/auth_remote_repository.dart';
import 'package:frontend/models/user_model.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());
  final authRemoteRepository = AuthRemoteRepository();
  final authLocalRepository = AuthLocalRepository();
  final spService = SpService();

  void getUserData() async {
    try {
      emit(AuthLoading());
      final userModel = await authRemoteRepository.getUserData();

      if (userModel != null) {
        await authLocalRepository.insertUser(userModel);
        emit(AuthLoggedIn(userModel));
      } else {
        emit(AuthInitial());
      }
    } catch (e) {
      emit(AuthInitial());
    }
  }

  void signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      emit(AuthLoading());
      await authRemoteRepository.signUp(
        name: name,
        email: email,
        password: password,
      );

      emit(AuthSignUp());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void login({required String email, required String password}) async {
    try {
      emit(AuthLoading());
      final userModel = await authRemoteRepository.login(
        email: email,
        password: password,
      );

      if (userModel.token.isNotEmpty) {
        await spService.setToken(userModel.token);
      }

      await authLocalRepository.insertUser(userModel);

      emit(AuthLoggedIn(userModel));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> logout(BuildContext context) async {
    emit(AuthLoading());
    await spService.removeToken();
    await authLocalRepository.deleteUser();
    emit(AuthInitial());

    // Check if the widget is still mounted before navigating
    if (!context.mounted) return;

    Navigator.of(context).push(LoginPage.route());
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      emit(AuthLoading());
      final token = await spService.getToken();
      if (token == null) throw "Token not found";

      await authRemoteRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        token: token,
      );

      getUserData();
    } catch (e) {
      emit(AuthError("Failed to change password: $e"));
    }
  }
}
