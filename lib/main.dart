import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  if (kDebugMode) {
    try {
      FirebaseFunctions.instance.useFunctionsEmulator('127.0.0.1', 5001);
      print('Cloud Functions emulator configured.');
    } catch (e) {
      print('Failed to configure Cloud Functions emulator: $e');
    }
  }

  runApp(const ProviderScope(child: ReliefHubApp()));
}

class ReliefHubApp extends ConsumerWidget {
  const ReliefHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'ReliefHub AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
