import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../data/models/dose_log.dart';
import '../../data/models/medication_schedule.dart';
import '../../logic/app_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final schedules =
        app.schedules.where((schedule) => schedule.type == 'minum').toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final lastThirtyDays = schedules.take(30).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat 30 Hari')),
      body: lastThirtyDays.isEmpty
          ? const Center(
              child: Text(
                'Riwayat belum tersedia.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: lastThirtyDays.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final schedule = lastThirtyDays[index];
                final status = _statusFor(_statusValue(schedule, app.history));
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: status.color.withValues(alpha: 0.13),
                      child: Icon(status.icon, color: status.color),
                    ),
                    title: Text(
                      _formatDate(schedule.date),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${schedule.time}  •  ${schedule.description}',
                      style: const TextStyle(fontSize: 15),
                    ),
                    trailing: Text(
                      status.label,
                      style: TextStyle(
                        color: status.color,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return DateFormat('dd/MM/yyyy').format(date);
  }

  _HistoryStatus _statusFor(String status) {
    switch (status) {
      case 'diminum':
        return const _HistoryStatus('diminum', Colors.green, Icons.check);
      case 'ditunda':
        return const _HistoryStatus(
          'ditunda',
          Colors.orange,
          Icons.snooze_outlined,
        );
      case 'terlewat':
        return const _HistoryStatus(
          'terlewat',
          Colors.red,
          Icons.error_outline,
        );
      default:
        return const _HistoryStatus(
          'belum_terkonfirmasi',
          AppColors.muted,
          Icons.help_outline,
        );
    }
  }

  String _statusValue(MedicationSchedule schedule, List<DoseLog> logs) {
    for (final log in logs.reversed) {
      if (log.scheduleId == schedule.id) return log.status;
    }
    return schedule.status;
  }
}

class _HistoryStatus {
  const _HistoryStatus(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;
}
