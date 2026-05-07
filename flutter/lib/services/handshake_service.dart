import 'package:dio/dio.dart';
import '../models/content.dart';

class HandshakeResponse {
  final Map<String, dynamic> permission;
  final Map<String, dynamic> vault;
  final String? welcomeMessage;
  final int initialLevel;
  final Map<String, dynamic>? presetContext;

  HandshakeResponse({
    required this.permission,
    required this.vault,
    this.welcomeMessage,
    required this.initialLevel,
    this.presetContext,
  });

  factory HandshakeResponse.fromJson(Map<String, dynamic> json) {
    return HandshakeResponse(
      permission: json['permission'] ?? {},
      vault: json['vault'] ?? {},
      welcomeMessage: json['welcome_message'],
      initialLevel: json['initial_level'] ?? 0,
      presetContext: json['preset_context'],
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
        data: {
          'handshake': {
            'slug': slug,
            'firebase_uid': firebaseUid,
          }
        },
      );

      if (response.statusCode == 201) {
        return HandshakeResponse.fromJson(response.data);
      } else {
        throw Exception('Handshake failed: ${response.data['error']}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Invalid access link');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Access link expired or max uses exceeded');
      } else {
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
