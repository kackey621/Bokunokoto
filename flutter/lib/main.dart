import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/router.dart';
import 'app/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final options = DefaultFirebaseOptions.currentPlatform;
  _assertNoTodoPlaceholders(options);

  await Firebase.initializeApp(options: options);
  runApp(const ProviderScope(child: BokuApp()));
}

// LOW-029: refuse to boot if firebase_options.dart still ships with the
// `TODO_*` placeholders. Without this guard a release build silently
// authenticates against an empty Firebase project.
void _assertNoTodoPlaceholders(FirebaseOptions options) {
  final fields = <String, String?>{
    'apiKey': options.apiKey,
    'appId': options.appId,
    'projectId': options.projectId,
    'messagingSenderId': options.messagingSenderId,
  };
  for (final entry in fields.entries) {
    final value = entry.value ?? '';
    if (value.startsWith('TODO_')) {
      throw StateError(
        'firebase_options.dart still contains TODO placeholder for '
        '${entry.key}. Run `flutterfire configure` before shipping.',
      );
    }
  }
}

class BokuApp extends ConsumerWidget {
  const BokuApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Bokunokoto',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
