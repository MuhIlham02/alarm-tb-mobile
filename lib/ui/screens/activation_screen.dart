import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../logic/app_provider.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    await context.read<AppProvider>().activate(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.medication_rounded,
                    size: 74,
                    color: AppColors.royalBlue,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    AppConstants.appTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Masukkan kode aktivasi dari petugas untuk menghubungkan pengingat dengan jadwal Anda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, height: 1.5),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.characters,
                    keyboardType: TextInputType.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                    inputFormatters: [
                      _ActivationCodeFormatter(),
                      LengthLimitingTextInputFormatter(9),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Kode aktivasi',
                      hintText: 'ABCD-EFGH',
                      prefixIcon: Icon(Icons.key_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Kode simulasi: ABCD-EFGH',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: provider.isBusy ? null : _activate,
                    child: provider.isBusy
                        ? const CircularProgressIndicator()
                        : const Text('LANJUTKAN'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivationCodeFormatter extends TextInputFormatter {
  static const _allowed = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final characters = newValue.text
        .toUpperCase()
        .split('')
        .where(_allowed.contains)
        .take(8)
        .toList();
    final value = characters.length > 4
        ? '${characters.take(4).join()}-${characters.skip(4).join()}'
        : characters.join();
    return TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }
}
