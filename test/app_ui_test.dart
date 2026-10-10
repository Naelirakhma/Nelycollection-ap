import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nelycollectionapk/main.dart';
import 'package:nelycollectionapk/theme/app_theme.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> setViewport(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('home customer fits a compact phone viewport', (tester) async {
    await setViewport(tester, const Size(360, 640));
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const CustomerShell()),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('order tracking fits a compact phone viewport', (tester) async {
    await setViewport(tester, const Size(360, 640));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: OrderDetailPage({
          'id': 'lokal-1',
          'jenis': 'jahit',
          'item_nama': 'Jahit Kebaya',
          'proses': 2,
          'total': 350000,
          'dp': 175000,
          'status_bayar': 'Terverifikasi',
          'detail': const {},
          'ukuran': const {},
          'tanggal_butuh': '2026-11-01',
        }),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('registration validates WhatsApp before contacting backend', (
    tester,
  ) async {
    await setViewport(tester, const Size(360, 640));
    Session.reset();
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const AuthPage()),
    );

    await tester.tap(find.text('Belum punya akun? Daftar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Pelanggan Uji');
    await tester.enterText(find.byType(TextField).at(1), '0812-NELY');
    await tester.ensureVisible(find.text('Daftar').first);
    await tester.tap(find.text('Daftar').first);
    await tester.pump();

    expect(find.text('Masukkan nomor WhatsApp yang valid.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('registration rejects a mismatched password confirmation', (
    tester,
  ) async {
    await setViewport(tester, const Size(360, 640));
    Session.reset();
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const AuthPage()),
    );

    await tester.tap(find.text('Belum punya akun? Daftar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Pelanggan Uji');
    await tester.enterText(find.byType(TextField).at(1), '081234567890');
    await tester.enterText(find.byType(TextField).at(2), 'uji@example.com');
    await tester.enterText(find.byType(TextField).at(3), 'Nely2026!');
    await tester.enterText(find.byType(TextField).at(4), 'Nely2027!');
    await tester.ensureVisible(find.text('Daftar').first);
    await tester.tap(find.text('Daftar').first);
    await tester.pump();

    expect(find.text('Konfirmasi password tidak sama.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('payment offers only BRI, cash, and QRIS barcode', (
    tester,
  ) async {
    await setViewport(tester, const Size(360, 640));
    final oldBriNumber = Repo.info['bri_account_number'];
    final oldBriName = Repo.info['bri_account_name'];
    final oldQrisUrl = Repo.info['qris_image_url'];
    addTearDown(() {
      Repo.info['bri_account_number'] = oldBriNumber;
      Repo.info['bri_account_name'] = oldBriName;
      Repo.info['qris_image_url'] = oldQrisUrl;
    });
    Repo.info['bri_account_number'] = '';
    Repo.info['bri_account_name'] = '';
    Repo.info['qris_image_url'] = '';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PaymentPage({
          'id': 'lokal-payment',
          'item_nama': 'Jahit Kebaya',
          'dp': 100000,
          'total': 200000,
        }),
      ),
    );

    expect(find.text('BRI'), findsOneWidget);
    expect(find.text('Tunai'), findsOneWidget);
    expect(find.text('QRIS'), findsOneWidget);
    expect(find.text('Belum diatur'), findsNWidgets(2));
    expect(
      find.textContaining('Bayar tunai langsung di toko.'),
      findsOneWidget,
    );
    expect(find.textContaining('transfer ke'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin portal exposes the main management areas', (tester) async {
    await setViewport(tester, const Size(360, 640));
    Session.role = 'admin';
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const AdminShell()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dashboard Admin'), findsOneWidget);
    expect(find.text('Pesanan'), findsOneWidget);
    expect(find.text('Pembayaran'), findsOneWidget);
    expect(find.text('Katalog'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home and tracking fit a large viewport', (tester) async {
    await setViewport(tester, const Size(800, 1000));
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const CustomerShell()),
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: OrderDetailPage({
          'id': 'lokal-2',
          'jenis': 'sewa',
          'item_nama': 'Kebaya Modern',
          'proses': 1,
          'total': 250000,
          'dp': 100000,
          'status_bayar': 'Belum Bayar',
          'detail': const {},
          'ukuran': const {},
          'tanggal_sewa': '2026-11-01',
          'tanggal_kembali': '2026-11-02',
        }),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalog Save stores a demo item before closing', (tester) async {
    await setViewport(tester, const Size(360, 640));
    Session.reset();
    Session.role = 'admin';
    final originalIds = Repo.jasa.map((item) => item['id']).toSet();
    addTearDown(
      () => Repo.jasa.removeWhere((item) => !originalIds.contains(item['id'])),
    );

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const AdminCatalogPage()),
    );
    await tester.tap(find.text('＋ Tambah'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Uji Simpan');
    await tester.enterText(find.byType(TextField).at(1), '25000');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(Repo.jasa.any((item) => item['nama'] == 'Uji Simpan'), isTrue);
    expect(find.text('Katalog berhasil disimpan ke server.'), findsNothing);
    expect(find.text('Tersimpan sementara dalam Mode Demo.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
