import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BKMode { admin, viewer }

class BKUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final BKMode mode;
  final bool hasVault;

  BKUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.mode,
    required this.hasVault,
  });
}

class AuthState {
  final User? firebaseUser;
  final BKUser? bkUser;
  final bool isLoading;
  final String? error;

  AuthState({
    this.firebaseUser,
    this.bkUser,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => firebaseUser != null;

  AuthState copyWith({
    User? firebaseUser,
    BKUser? bkUser,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      firebaseUser: firebaseUser ?? this.firebaseUser,
      bkUser: bkUser ?? this.bkUser,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return AuthNotifier(auth, ref);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth;
  final Ref _ref;

  AuthNotifier(this._auth, this._ref) : super(AuthState()) {
    _initializeAuth();
  }

  void _initializeAuth() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        state = state.copyWith(firebaseUser: user);
        _fetchBKUser(user);
      } else {
        state = AuthState();
      }
    });
  }

  Future<void> _fetchBKUser(User user) async {
    try {
      final idToken = await user.getIdToken();
      // TODO: Call Rails API to get user context
      // const apiService = _ref.watch(apiClientProvider);
      // final response = await apiService.get('/account/context');
      // Parse response and set bkUser
      state = state.copyWith(bkUser: _createBKUser(user));
    } catch (e) {
      state = state.copyWith(error: 'Failed to fetch user: $e');
    }
  }

  BKUser _createBKUser(User user) {
    return BKUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      mode: BKMode.viewer, // TODO: Determine from API
      hasVault: false, // TODO: Determine from API
    );
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true);
    try {
      // TODO: Implement Google sign-in
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Google sign-in failed: $e',
      );
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Email sign-in failed: $e',
      );
    }
  }

  Future<void> signUp(String email, String password, String displayName) async {
    state = state.copyWith(isLoading: true);
    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCred.user?.updateDisplayName(displayName);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Sign-up failed: $e',
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _auth.signOut();
      state = AuthState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Sign-out failed: $e',
      );
    }
  }
}
