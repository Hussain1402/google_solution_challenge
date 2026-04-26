import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';

/// Auth state stream.
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Current user's Firestore profile (role, etc.).
final userProfileProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return null;
      return FirestoreService().getUser(user.uid);
    },
    loading: () => null,
    error: (e, st) => null,
  );
});

/// Auth state holder.
class AuthState {
  final bool isLoading;
  final String? errorMessage;
  const AuthState({this.isLoading = false, this.errorMessage});
  AuthState copyWith({bool? isLoading, String? errorMessage}) =>
      AuthState(isLoading: isLoading ?? this.isLoading, errorMessage: errorMessage);
}

/// Auth notifier using Riverpod 3.x Notifier pattern.
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
    required String role,
  }) async {
    state = const AuthState(isLoading: true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      final user = UserModel(
        uid: cred.user!.uid,
        displayName: displayName,
        email: email,
        role: role,
        createdAt: DateTime.now(),
      );
      await FirestoreService().setUser(user);
      state = const AuthState();
      return true;
    } on FirebaseAuthException catch (e) {
      state = AuthState(errorMessage: e.message ?? 'Registration failed');
      return false;
    } catch (e) {
      state = AuthState(errorMessage: 'Registration failed: $e');
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = const AuthState(isLoading: true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email, password: password,
      );
      state = const AuthState();
      return true;
    } on FirebaseAuthException catch (e) {
      state = AuthState(errorMessage: e.message ?? 'Sign-in failed');
      return false;
    } catch (e) {
      state = AuthState(errorMessage: 'Sign-in failed: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
