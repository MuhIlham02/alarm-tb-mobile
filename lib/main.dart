import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app_theme.dart';
import 'core/constants.dart';
import 'data/repositories/mock_patient_repository.dart';
import 'data/repositories/patient_repository.dart';
import 'logic/app_provider.dart';
import 'ui/screens/activation_screen.dart';
import 'ui/screens/consent_screen.dart';
import 'ui/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();

  // Swap to ApiPatientRepository to connect a configured backend.
  final PatientRepository repository = MockPatientRepository(preferences);
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
