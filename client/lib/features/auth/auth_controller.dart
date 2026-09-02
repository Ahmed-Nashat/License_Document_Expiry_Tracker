import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_api.dart';
import 'auth_models.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);

class AuthController extends AsyncNotifier<AuthSession?> {
  @override
  FutureOr<AuthSession?> build() => ref.read(authApiProvider).restore();

  Future<void> signIn({required String email, required String password}) async {
    final session = await ref
        .read(authApiProvider)
        .signIn(email: email, password: password);
    state = AsyncData(session);
  }

  Future<void> register(
      {required String name,
      required String email,
      required String password,
      required String ageRange,
      String? gender}) async {
    final session = await ref.read(authApiProvider).register(
        name: name,
        email: email,
        password: password,
        ageRange: ageRange,
        gender: gender);
    state = AsyncData(session);
  }

  Future<void> signOut() async {
    try {
      await ref.read(authApiProvider).signOut();
    } finally {
      state = const AsyncData(null);
    }
  }

  Future<void> updateProfile({
    required String displayName,
    String? ageRange,
    String? gender,
  }) async {
    final token = state.value?.accessToken;
    if (token == null) throw StateError('No active session.');

    final updatedUser = await ref.read(authApiProvider).updateProfile(
          token: token,
          displayName: displayName,
          ageRange: ageRange,
          gender: gender,
        );
    if (state.value != null) {
      state = AsyncData(state.value!.copyWith(user: updatedUser));
    }
  }

  Future<void> updatePassword(
      String currentPassword, String newPassword) async {
    final token = state.value?.accessToken;
    if (token == null) throw StateError('No active session.');

    await ref
        .read(authApiProvider)
        .updatePassword(token, currentPassword, newPassword);
    await signOut();
  }
}
