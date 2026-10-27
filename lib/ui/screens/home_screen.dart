import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../data/models/medication_schedule.dart';
import '../../logic/app_provider.dart';
import 'battery_guide_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final profile = provider.profile;
    final dose = provider.todayDose;
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appTitle),
        actions: [
          IconButton(
            tooltip: 'Panduan pengingat',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const BatteryGuideScreen(),
              ),
            ),
            icon: const Icon(Icons.notifications_active_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.refreshRecords,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              'Halo, ${profile?.name ?? 'Pasien'}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'No. RM ${profile?.medicalRecordNumber ?? '-'}  •  ${profile?.familySupport ?? ''}',
              style: const TextStyle(fontSize: 16, color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            _InfoCard(
              icon: Icons.medical_information_outlined,
              title: 'Informasi resep',
              body: profile?.prescription ?? 'Belum ada data resep',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ScheduleInfo(
                    icon: Icons.event_available_outlined,
                    title: 'Kontrol',
                    date: profile?.controlDate ?? '-',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ScheduleInfo(
                    icon: Icons.local_pharmacy_outlined,
                    title: 'Ambil obat',
                    date: profile?.medicationPickupDate ?? '-',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _todayDoseCard(context, provider, dose),
            const SizedBox(height: 14),
            _SyncCard(
              count: provider.pendingCount,
              isBusy: provider.isBusy,
              onSync: provider.syncPending,
            ),
            if (provider.errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                provider.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
              ),
              icon: const Icon(Icons.history),
              label: const Text('LIHAT RIWAYAT 30 HARI'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const BatteryGuideScreen(),
                ),
              ),
              icon: const Icon(Icons.settings_suggest_outlined),
              label: const Text('PANDUAN PENGATURAN PENGINGAT'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _todayDoseCard(
    BuildContext context,
    AppProvider provider,
    MedicationSchedule? dose,
  ) {
    if (dose == null) {
      return const _InfoCard(
        icon: Icons.event_busy_outlined,
        title: 'Jadwal hari ini',
        body: 'Jadwal minum obat belum tersedia.',
      );
    }
    final status = _statusForToday(dose.status);
    return Card(
      color: const Color(0xFFEAF8F7),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.alarm, color: AppColors.teal, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Jadwal minum hari ini',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              dose.time,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 38,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(dose.description, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              'Status: $status',
              style: const TextStyle(
                color: AppColors.royalBlue,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: provider.isBusy || dose.status == 'diminum'
                  ? null
                  : () => provider.recordDose('diminum'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: AppColors.navy,
              ),
              child: const Text('SUDAH MINUM'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: provider.isBusy || dose.status == 'diminum'
                  ? null
                  : () => provider.recordDose('ditunda'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Tunda 10 Menit'),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () {
                SystemSound.play(SystemSoundType.alert);
                showDialog<void>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    icon: const Icon(
                      Icons.notifications_active,
                      color: AppColors.teal,
                      size: 42,
                    ),
                    title: const Text(AppConstants.reminderMessage),
                    content: Text('Jadwal Anda pukul ${dose.time}.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('TUTUP'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.volume_up_outlined),
              label: const Text(
                'Simulasikan bunyi pengingat',
                style: TextStyle(fontSize: 16),
              ),
            ),
            if (provider.deferredUntil != null)
              Text(
                'Pengingat ditunda hingga ${DateFormat('HH:mm').format(provider.deferredUntil!)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: AppColors.muted),
              ),
          ],
        ),
      ),
    );
  }

  String _statusForToday(String status) {
    switch (status) {
      case 'diminum':
        return 'Diminum';
      case 'ditunda':
        return 'Ditunda';
      case 'terlewat':
        return 'Terlewat';
      default:
        return 'Belum dikonfirmasi';
    }
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 30, color: AppColors.royalBlue),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 5),
                Text(body, style: const TextStyle(fontSize: 17)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ScheduleInfo extends StatelessWidget {
  const _ScheduleInfo({
    required this.icon,
    required this.title,
    required this.date,
  });

  final IconData icon;
  final String title;
  final String date;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.royalBlue, size: 27),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(date, style: const TextStyle(fontSize: 16)),
        ],
      ),
    ),
  );
}

class _SyncCard extends StatelessWidget {
  const _SyncCard({
    required this.count,
    required this.isBusy,
    required this.onSync,
  });

  final int count;
  final bool isBusy;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            count == 0
                ? Icons.cloud_done_outlined
                : Icons.cloud_upload_outlined,
            color: AppColors.royalBlue,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              count == 0
                  ? 'Semua catatan tersinkron'
                  : '$count catatan menunggu sinkronisasi',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          if (count > 0)
            TextButton(
              onPressed: isBusy ? null : onSync,
              child: const Text('KIRIM'),
            ),
        ],
      ),
    ),
  );
}
