import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:arvi_b3_uts/features/auth/domain/user_model.dart';
import 'package:arvi_b3_uts/features/dashboard/data/user_repository.dart';
import 'package:arvi_b3_uts/features/auth/presentation/providers/auth_provider.dart';

class UserListNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final UserRepository _repository;

  UserListNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    state = const AsyncValue.loading();
    try {
      final users = await _repository.getUsers();
      state = AsyncValue.data(users);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> toggleUserStatus(String userId, bool currentStatus) async {
    try {
      final newStatus = !currentStatus;
      await _repository.toggleUserStatus(userId, newStatus);
      
      // Update UI optimistically or by re-fetching
      if (state.hasValue) {
        final currentUsers = state.value!;
        final updatedUsers = currentUsers.map((user) {
          if (user.id == userId) {
            return UserModel(
              id: user.id,
              name: user.name,
              email: user.email,
              role: user.role,
              isActive: newStatus,
            );
          }
          return user;
        }).toList();
        state = AsyncValue.data(updatedUsers);
      }
    } catch (e) {
      // Revert will happen automatically if we don't update state or if we re-fetch
      rethrow;
    }
  }
}

final userListProvider = StateNotifierProvider.autoDispose<UserListNotifier, AsyncValue<List<UserModel>>>((ref) {
  // Restart if auth changes
  ref.watch(authProvider);
  final repo = ref.watch(userRepositoryProvider);
  return UserListNotifier(repo);
});
