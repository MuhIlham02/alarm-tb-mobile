import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile_pasien/data/repositories/mock_patient_repository.dart';
import 'package:mobile_pasien/logic/app_provider.dart';
import 'package:mobile_pasien/main.dart';

void main() {
  testWidgets('Pasien dapat aktivasi, menyetujui data, dan membuka beranda', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final provider = AppProvider(MockPatientRepository(preferences));
    await provider.initialize();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: provider, child: const PatientApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Kode aktivasi'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'abcd-efgh');
    await tester.tap(find.text('LANJUTKAN'));
    await tester.pumpAndSettle();
    expect(find.text('Pelindungan data kesehatan'), findsOneWidget);

    await tester.ensureVisible(find.text('SAYA SETUJU'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SAYA SETUJU'));
    await tester.pumpAndSettle();
    expect(find.text('Halo, Sutrisno'), findsOneWidget);
    expect(find.text('SUDAH MINUM'), findsOneWidget);
    expect(find.text('Tunda 10 Menit'), findsOneWidget);
    expect(find.text('OAT KDT Fase Intensif'), findsNWidgets(2));

    await tester.scrollUntilVisible(
      find.text('LIHAT RIWAYAT 30 HARI'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('LIHAT RIWAYAT 30 HARI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('LIHAT RIWAYAT 30 HARI'));
    await tester.pumpAndSettle();
    expect(find.text('Riwayat 30 Hari'), findsOneWidget);
    expect(find.text('terlewat'), findsWidgets);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.notifications_active_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Panduan Pengingat'), findsOneWidget);
    expect(find.text('Xiaomi / Redmi'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Samsung'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Samsung'), findsOneWidget);
  });
}
