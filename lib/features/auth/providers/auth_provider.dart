import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/services/remote_config_service.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Auth state stream.
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Current user's Firestore profile (role, etc.).
final userProfileProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) async {
      if (user == null) return null;
      final profile = await FirestoreService().getUser(user.uid);
      // Initialize FCM if user is admin
      if (profile != null && profile.role == 'admin') {
        FCMService().init(profile.uid);
      }
      return profile;
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
    String? adminKey,
  }) async {
    state = const AuthState(isLoading: true);
    try {
      // Security Check: If trying to register as admin, verify the private key
      String finalRole = role;
      if (role == 'admin') {
        final rc = ref.read(remoteConfigServiceProvider);
        // Ensure we have latest config (optional, already activated in main, but let's be safe)
        try {
          await FirebaseRemoteConfig.instance.fetch();
          await FirebaseRemoteConfig.instance.activate();
        } catch (_) {} 
        
        final expectedKey = rc.adminPrivateKey;
        if (adminKey != expectedKey) {
          state = const AuthState(errorMessage: 'Invalid Admin Private Key. Registration blocked.');
          return false;
        }
      } else if (role == 'staff') {
        // Just in case someone tries to spoof role: 'admin' via staff selection
        finalRole = 'staff';
      }
      print('[AUTH] Attempting registration for: $email with role: $role');
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      print('[AUTH] Firebase Auth user created: ${cred.user?.uid}');
      final user = UserModel(
        uid: cred.user!.uid,
        displayName: displayName,
        email: email,
        role: finalRole,
        createdAt: DateTime.now(),
      );
      await FirestoreService().setUser(user);
      print('[AUTH] Firestore user profile written successfully');
      
      if (finalRole == 'admin') {
        await FCMService().init(cred.user!.uid);
      }

      if (finalRole == 'donor') {
        await FirebaseAuth.instance.signOut();
      }

      state = const AuthState();
      return true;
    } on FirebaseAuthException catch (e) {
      print('[AUTH ERROR] FirebaseAuthException: code=${e.code}, message=${e.message}');
      state = AuthState(errorMessage: e.message ?? 'Registration failed');
      return false;
    } catch (e, st) {
      print('[AUTH ERROR] Generic exception: $e');
      print('[AUTH ERROR] Stack trace: $st');
      state = AuthState(errorMessage: 'Registration failed: $e');
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = const AuthState(isLoading: true);
    try {
      print('[AUTH] Attempting sign-in for: $email');
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email, password: password,
      );
      print('[AUTH] Sign-in successful');
      state = const AuthState();
      return true;
    } on FirebaseAuthException catch (e) {
      print('[AUTH ERROR] FirebaseAuthException: code=${e.code}, message=${e.message}');
      state = AuthState(errorMessage: e.message ?? 'Sign-in failed');
      return false;
    } catch (e, st) {
      print('[AUTH ERROR] Generic exception: $e');
      print('[AUTH ERROR] Stack trace: $st');
      state = AuthState(errorMessage: 'Sign-in failed: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

