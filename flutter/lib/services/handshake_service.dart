import 'package:dio/dio.dart';
import '../models/content.dart';

class HandshakeResponse {
  final Map<String, dynamic> permission;
  final String? welcomeMessage;
  final int initialLevel;
  final Map<String, dynamic>? presetContext;

  HandshakeResponse({
    required this.permission,
    this.welcomeMessage,
    required this.initialLevel,
    this.presetContext,
  });

  String? get vaultId => permission['vault_id']?.toString();
  int get grantedLevel => (permission['granted_level'] as num?)?.toInt() ?? 0;

  factory HandshakeResponse.fromJson(Map<String, dynamic> json) {
    return HandshakeResponse(
      permission: Map<String, dynamic>.from(json['permission'] ?? const {}),
      welcomeMessage: json['welcome_message'] as String?,
      initialLevel: (json['initial_level'] as num?)?.toInt() ?? 0,
      presetContext: json['preset_context'] is Map
          ? Map<String, dynamic>.from(json['preset_context'] as Map)
          : null,
    );
  }
}

class HandshakeService {
  final Dio dio;

  HandshakeService(this.dio);

  Future<HandshakeResponse> performHandshake({
    required String slug,
    required String firebaseUid,
  }) async {
    try {
      final response = await dio.post(
        '/handshake',
        data: {'slug': slug, 'firebase_uid': firebaseUid},
      );
      return HandshakeResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final code = e.response?.data is Map ? e.response!.data['code'] : null;
      switch (e.response?.statusCode) {
        case 404:
          throw Exception('Invalid access link');
        case 403:
          throw Exception('Access link already bound to another account');
        case 422:
          if (code == 'expired') throw Exception('Access link expired');
          if (code == 'exhausted') throw Exception('Access link max uses exceeded');
          throw Exception('Handshake rejected: ${code ?? e.message}');
        default:
          throw Exception('Handshake error: ${e.message}');
      }
    }
  }

  String? extractSlugFromQRUrl(String qrData) {
    try {
      final uri = Uri.parse(qrData);
      final slug = uri.pathSegments.lastOrNull;
      return slug;
    } catch (e) {
      return null;
    }
  }
}
