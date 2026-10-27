import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../logic/app_provider.dart';

class ConsentScreen extends StatelessWidget {
  const ConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Persetujuan penggunaan data')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.privacy_tip_outlined,
                    size: 68,
                    color: AppColors.royalBlue,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Pelindungan data kesehatan',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 18),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(22),
                      child: Text(
                        'Aplikasi ini menggunakan data profil dan jadwal perawatan Anda untuk menampilkan pengingat harian serta mencatat konfirmasi minum obat. Data konfirmasi dapat tersimpan di perangkat dan dikirim saat koneksi tersedia. Akses data dibatasi untuk keperluan layanan kesehatan.',
                        style: TextStyle(fontSize: 18, height: 1.55),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Dengan memilih “Saya setuju”, Anda memberikan persetujuan pemrosesan data pribadi dan data kesehatan sesuai Undang-Undang Pelindungan Data Pribadi (UU PDP). Persetujuan versi ${AppConstants.consentVersion}. Anda dapat meminta informasi lebih lanjut kepada petugas.',
                    style: TextStyle(fontSize: 17, height: 1.5),
                  ),
                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      provider.errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: provider.isBusy
                        ? null
                        : () => provider.acceptConsent(),
                    child: provider.isBusy
                        ? const CircularProgressIndicator()
                        : const Text('SAYA SETUJU'),
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
