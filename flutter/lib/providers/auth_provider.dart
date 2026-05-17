import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client_provider.dart';

enum BKMode { admin, viewer }

class BKVaultRef {
  final String id;
  final String? displayName;
  final String? slug;
  final String? kind;
  final DateTime? archivedAt;

  BKVaultRef({
    required this.id,
    this.displayName,
    this.slug,
    this.kind,
    this.archivedAt,
  });

  factory BKVaultRef.fromJson(Map<String, dynamic> json) {
    return BKVaultRef(
      id: json['id'].toString(),
      displayName: json['display_name'] as String?,
      slug: json['slug'] as String?,
      kind: json['kind'] as String?,
      archivedAt: json['archived_at'] != null
          ? DateTime.tryParse(json['archived_at'].toString())
          : null,
    );
  }
}

class BKUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final BKMode mode;
  final bool hasVault;
  final String? defaultVaultId;
  final bool canCreateVault;
  final bool bkcAccess;
  final bool isBetaTester;
  final int vaultQuota;
  final List<BKVaultRef> ownedVaults;
  final List<BKVaultRef> receivedVaults;

  BKUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.mode,
    required this.hasVault,
    this.defaultVaultId,
    this.canCreateVault = false,
    this.bkcAccess = false,
    this.isBetaTester = false,
    this.vaultQuota = 0,
    this.ownedVaults = const [],
    this.receivedVaults = const [],
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
    Object? error = _sentinel,
  }) {
    return AuthState(
      firebaseUser: firebaseUser ?? this.firebaseUser,
      bkUser: bkUser ?? this.bkUser,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }
}

const Object _sentinel = Object();

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
        _syncWithServer(user);
      } else {
        state = AuthState();
      }
    });
  }

  Future<void> _syncWithServer(User user) async {
    try {
      // Provision/upsert the Rails user record. Until this succeeds, every
      // authenticated endpoint returns 401 (BaseController#authenticate_user!
      // looks up users by firebase_uid).
      final idToken = await user.getIdToken();
      if (idToken == null) {
        state = state.copyWith(error: 'Missing Firebase ID token');
        return;
      }
      await _verifyWithServer(idToken);
      await _fetchAccountContext(user);
    } catch (e) {
      state = state.copyWith(
        bkUser: _fallbackBKUser(user),
        error: 'Failed to sync with server: $e',
      );
    }
  }

  Future<void> _verifyWithServer(String idToken) async {
    final dio = createDioClient(null);
    await dio.post('/auth/verify', data: {'token': idToken});
  }

  Future<void> _fetchAccountContext(User user) async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.get('/account/context');
    final account = (response.data as Map)['account'] as Map<String, dynamic>?;
    if (account == null) {
      state = state.copyWith(bkUser: _fallbackBKUser(user));
      return;
    }

    final capabilities =
        account['capabilities'] as Map<String, dynamic>? ?? const {};
    final ownedRaw = (account['owned_vaults'] as List?) ?? const [];
    final receivedRaw = (account['received_vaults'] as List?) ?? const [];
    final owned = ownedRaw
        .map((v) => BKVaultRef.fromJson(v as Map<String, dynamic>))
        .toList();
    final received = receivedRaw
        .map((v) => BKVaultRef.fromJson(v as Map<String, dynamic>))
        .toList();
    final defaultVaultId = account['default_vault_id']?.toString();

    state = state.copyWith(
      bkUser: BKUser(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoURL,
        mode: owned.isNotEmpty ? BKMode.admin : BKMode.viewer,
        hasVault: defaultVaultId != null || owned.isNotEmpty,
        defaultVaultId: defaultVaultId,
        canCreateVault: capabilities['can_create_vault'] == true,
        bkcAccess: capabilities['bkc_access'] == true,
        isBetaTester: capabilities['is_beta_tester'] == true,
        vaultQuota: (capabilities['vault_quota'] as num?)?.toInt() ?? 0,
        ownedVaults: owned,
        receivedVaults: received,
      ),
      error: null,
    );
  }

  BKUser _fallbackBKUser(User user) {
    return BKUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      mode: BKMode.viewer,
      hasVault: false,
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
