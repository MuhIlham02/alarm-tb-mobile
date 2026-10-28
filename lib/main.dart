import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app_theme.dart';
import 'core/constants.dart';
import 'data/repositories/api_patient_repository.dart';
import 'data/repositories/mock_patient_repository.dart';
import 'data/repositories/patient_repository.dart';
import 'logic/app_provider.dart';
import 'ui/screens/activation_screen.dart';
import 'ui/screens/consent_screen.dart';
import 'ui/screens/home_screen.dart';

// 1. Ubah ke false saat ingin menyambungkan ke API Laravel Razzaq
final bool useMockData = false;

// 2. Isi alamat dasar server Laravel (TANPA akhiran /api/v1)
// Contoh lokal sendiri: 'http://127.0.0.1:8000'
// Contoh Port Forwarding VS Code Razzaq: 'https://xxxx-8000.asse.devtunnels.ms'
const String backendBaseUrl = 'http://127.0.0.1:8000';

String _normalizeBaseUrl(String url) {
  var clean = url.trim();
  while (clean.endsWith('/')) {
    clean = clean.substring(0, clean.length - 1);
  }
  if (clean.endsWith('/api/v1')) {
    clean = clean.substring(0, clean.length - 7);
  }
  return clean;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();

  final dio = Dio(
    BaseOptions(
      baseUrl: _normalizeBaseUrl(backendBaseUrl),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  final PatientRepository repository = useMockData
      ? MockPatientRepository(preferences)
      : ApiPatientRepository(dio: dio, preferences: preferences);

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(repository)..initialize(),
      child: const PatientApp(),
    ),
  );
}

class PatientApp extends StatelessWidget {
  const PatientApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: AppConstants.appTitle,
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: const _AppEntry(),
  );
}

class _AppEntry extends StatelessWidget {
  const _AppEntry();

  @override
  Widget build(BuildContext context) => Consumer<AppProvider>(
    builder: (context, app, _) {
      if (app.isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (!app.isActivated) return const ActivationScreen();
      if (!app.consentGranted) return const ConsentScreen();
      return const HomeScreen();
    },
  );
}