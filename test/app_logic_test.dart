import 'package:flutter_test/flutter_test.dart';
import 'package:nelycollectionapk/main.dart';

void main() {
  setUp(() {
    Session.reset();
    Repo.pesanan.clear();
  });

  tearDown(() => Repo.pesanan.clear());

  group('format helpers', () {
    test('formats Indonesian rupiah amounts', () {
      expect(rp(350000), 'Rp350.000');
      expect(rp(1234567.8), 'Rp1.234.568');
      expect(rp(-1500), 'Rp-1.500');
    });

    test('converts numeric values safely', () {
      expect(iv(12.9), 12);
      expect(iv('42'), 42);
      expect(iv('not a number'), 0);
    });
  });

  group('authentication validation', () {
    test('accepts a well-formed email and rejects malformed addresses', () {
      expect(emailValidationError('user.name@example.co.id'), isNull);
      expect(emailValidationError(' user@example.com '), isNull);
      expect(emailValidationError(''), isNotNull);
      expect(emailValidationError('user@localhost'), isNotNull);
      expect(emailValidationError('user..name@example.com'), isNotNull);
      expect(emailValidationError('user@-example.com'), isNotNull);
    });

    test('requires a strong password for sign-in and registration', () {
      expect(passwordValidationError('Nely2026!'), isNull);
      expect(passwordValidationError('short1!'), isNotNull);
      expect(passwordValidationError('alllowercase1!'), isNotNull);
      expect(passwordValidationError('ALLUPPERCASE1!'), isNotNull);
      expect(passwordValidationError('NoDigits!!'), isNotNull);
      expect(passwordValidationError('NoSymbol123'), isNotNull);
      expect(passwordValidationError('Has Space1!'), isNotNull);
    });

    test('validates WhatsApp numbers with common formatting', () {
      expect(whatsappValidationError('0812 3456 7890'), isNull);
      expect(whatsappValidationError('+62 (812) 3456-7890'), isNull);
      expect(whatsappValidationError(''), isNotNull);
      expect(whatsappValidationError('1234'), isNotNull);
      expect(whatsappValidationError('0812-NELY'), isNotNull);
    });

    test(
      'records BRI compatibly and displays only supported payment methods',
      () {
        expect(paymentRecordValue('BRI'), 'Transfer');
        expect(paymentRecordValue('QRIS'), 'QRIS');
        expect(paymentDisplayValue('Transfer'), 'BRI');
        expect(
          paymentMethodsSummary({
            'bri_account_number': '1234567890',
            'bri_account_name': 'NELY Collection',
            'qris_image_url': 'https://example.com/qris.png',
          }),
          'BRI: 1234567890 a.n. NELY Collection\nTunai\nQRIS',
        );
        expect(
          paymentMethodsSummary(const {}),
          'BRI (nomor rekening belum diatur)\n'
          'Tunai\n'
          'QRIS (barcode belum tersedia)',
        );
      },
    );
  });

  group('catalog image validation', () {
    test('accepts supported images with matching file extensions', () {
      expect(imageMimeType('sample.jpg', [0xff, 0xd8, 0xff]), 'image/jpeg');
      expect(
        imageMimeType('sample.png', [
          0x89,
          0x50,
          0x4e,
          0x47,
          0x0d,
          0x0a,
          0x1a,
          0x0a,
        ]),
        'image/png',
      );
      expect(
        imageMimeType('sample.webp', [
          ...'RIFF'.codeUnits,
          0,
          0,
          0,
          0,
          ...'WEBP'.codeUnits,
        ]),
        'image/webp',
      );
    });

    test('rejects mismatched image extensions and non-image files', () {
      expect(imageMimeType('sample.png', [0xff, 0xd8, 0xff]), isNull);
      expect(imageMimeType('sample.jpg', [0, 1, 2, 3]), isNull);
    });

    test('returns only absolute HTTP image URLs', () {
      expect(
        catalogImageUrl({'image_url': 'https://example.com/photo.jpg'}),
        'https://example.com/photo.jpg',
      );
      expect(catalogImageUrl({'foto_url': '/photo.jpg'}), isNull);
    });
  });

  group('order status', () {
    test('reports the quote and customer approval states', () {
      expect(
        statusText({'jenis': 'jahit', 'proses': 0, 'total': 0}),
        'Menunggu Penawaran',
      );
      expect(
        statusText({'jenis': 'jahit', 'proses': 0, 'total': 250000}),
        'Menunggu Persetujuan',
      );
    });

    test('requires payment verification before further progress', () {
      expect(
        statusText({
          'jenis': 'sewa',
          'proses': 1,
          'total': 150000,
          'status_bayar': 'Belum Bayar',
        }),
        'Menunggu Pembayaran',
      );
      expect(
        statusText({
          'jenis': 'sewa',
          'proses': 1,
          'total': 150000,
          'status_bayar': 'Menunggu Verifikasi',
        }),
        'Menunggu Verifikasi',
      );
    });

    test('marks the final stage complete', () {
      expect(
        statusText({
          'jenis': 'sewa',
          'proses': sewaSteps.length - 1,
          'total': 150000,
        }),
        'Selesai',
      );
    });
  });

  test('demo customer orders are stored locally and returned', () async {
    final order = await Repo.addPesanan({
      'jenis': 'jahit',
      'item_nama': 'Jahit Dress',
      'detail': {'warna': 'Maroon'},
    });

    expect(order['id'], startsWith('lokal-'));
    expect(order['status_bayar'], 'Belum Bayar');
    expect(order['customer_nama'], 'Tamu');
    expect(Repo.pesanan, contains(order));
  });

  test('demo admin catalog CRUD updates the visible list', () async {
    Session.role = 'admin';
    final items = <Map<String, dynamic>>[];

    await Repo.saveCatalog('jasa_jahit', items, {
      'nama': 'Jahit Kebaya Custom',
      'harga_awal': 500000,
    }, null);
    expect(items, hasLength(1));
    expect(items.single['id'], startsWith('lokal-'));

    final item = items.single;
    await Repo.saveCatalog('jasa_jahit', items, {
      'nama': 'Jahit Kebaya Premium',
    }, item);
    expect(item['nama'], 'Jahit Kebaya Premium');

    await Repo.deleteCatalog('jasa_jahit', items, item);
    expect(items, isEmpty);
  });

  test('new catalog rows include the required table defaults', () {
    expect(catalogCreateDefaults('jasa_jahit'), {'emoji': '', 'aktif': true});
    expect(catalogCreateDefaults('kebaya'), {
      'emoji': '',
      'aktif': true,
      'status': 'Tersedia',
    });
    expect(catalogCreateDefaults('galeri'), {
      'emoji': '',
      'bisa_referensi': true,
    });
    expect(() => catalogCreateDefaults('profiles'), throwsArgumentError);
  });

  test('customers cannot use the admin catalog repository methods', () async {
    final items = <Map<String, dynamic>>[];

    await expectLater(
      Repo.saveCatalog('jasa_jahit', items, {'nama': 'Tidak diizinkan'}, null),
      throwsStateError,
    );
  });

  test('demo admin can update a demo order locally', () async {
    Session.role = 'admin';
    final order = await Repo.addPesanan({
      'jenis': 'jahit',
      'item_nama': 'Jahit Kebaya',
    });

    await Repo.updatePesanan(order, {'total': 450000, 'dp': 200000});

    expect(order['total'], 450000);
    expect(order['dp'], 200000);
    expect(order['id'], startsWith('lokal-'));
  });
}
