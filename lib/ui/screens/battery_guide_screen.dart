import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

class BatteryGuideScreen extends StatelessWidget {
  const BatteryGuideScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Panduan Pengingat')),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: const [
        _GuideCard(
          number: '1',
          title: 'Izin notifikasi Android 13 atau lebih baru',
          steps: [
            'Buka Pengaturan di HP.',
            'Pilih Aplikasi, lalu Pengingat Obat Harian.',
            'Pilih Notifikasi dan aktifkan Izinkan notifikasi.',
          ],
        ),
        SizedBox(height: 12),
        _GuideCard(
          number: '2',
          title: 'Izinkan alarm tepat waktu',
          steps: [
            'Buka Pengaturan > Aplikasi > Akses aplikasi khusus.',
            'Pilih Alarm & pengingat atau Jadwal alarm.',
            'Izinkan Pengingat Obat Harian jika pilihan ini tersedia.',
          ],
        ),
        SizedBox(height: 12),
        _GuideCard(
          number: '3',
          title: 'Xiaomi / Redmi',
          steps: [
            'Buka Pengaturan > Aplikasi > Kelola aplikasi > Pengingat Obat Harian.',
            'Pilih Penghemat baterai, lalu pilih Tidak ada batasan.',
            'Aktifkan Mulai otomatis jika tersedia.',
          ],
        ),
        SizedBox(height: 12),
        _GuideCard(
          number: '4',
          title: 'OPPO',
          steps: [
            'Buka Pengaturan > Baterai > Pengaturan baterai lainnya.',
            'Atur aplikasi agar berjalan di latar belakang.',
            'Di Info aplikasi, izinkan mulai otomatis jika tersedia.',
          ],
        ),
        SizedBox(height: 12),
        _GuideCard(
          number: '5',
          title: 'vivo',
          steps: [
            'Buka Pengaturan > Baterai > Penggunaan baterai latar belakang.',
            'Pilih Pengingat Obat Harian dan izinkan aktivitas latar belakang.',
            'Matikan pembatasan hemat daya untuk aplikasi ini.',
          ],
        ),
        SizedBox(height: 12),
        _GuideCard(
          number: '6',
          title: 'Samsung',
          steps: [
            'Buka Pengaturan > Aplikasi > Pengingat Obat Harian > Baterai.',
            'Pilih Tidak dibatasi.',
            'Periksa Baterai > Batas penggunaan latar belakang dan keluarkan aplikasi dari aplikasi tidur.',
          ],
        ),
        SizedBox(height: 14),
        Text(
          'Nama menu dapat berbeda sesuai model HP dan versi Android. Bila perlu, minta bantuan keluarga atau pendamping.',
          style: TextStyle(color: AppColors.muted, fontSize: 16, height: 1.5),
        ),
      ],
    ),
  );
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.number,
    required this.title,
    required this.steps,
  });

  final String number;
  final String title;
  final List<String> steps;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AppColors.royalBlue,
                foregroundColor: Colors.white,
                child: Text(
                  number,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < steps.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Text(
                '${index + 1}. ${steps[index]}',
                style: const TextStyle(fontSize: 16, height: 1.45),
              ),
            ),
        ],
      ),
    ),
  );
}
