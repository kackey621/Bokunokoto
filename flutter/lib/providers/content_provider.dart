import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/content.dart';
import 'api_client_provider.dart';

final contentProvider = FutureProvider.family<List<Content>, String>((ref, vaultId) async {
  final dio = ref.watch(apiClientProvider);
  try {
    final response = await dio.get('/vaults/$vaultId/contents');
    final data = response.data as Map<String, dynamic>;
    final contents = (data['contents'] as List)
        .map((e) => Content.fromJson(e as Map<String, dynamic>))
        .toList();
    return contents;
  } catch (e) {
    throw Exception('Failed to load contents: $e');
  }
});

final contentDetailProvider = FutureProvider.family<Content, String>((ref, contentId) async {
  final dio = ref.watch(apiClientProvider);
  try {
    final response = await dio.get('/contents/$contentId');
    return Content.fromJson(response.data['content']);
  } catch (e) {
    throw Exception('Failed to load content: $e');
  }
});
