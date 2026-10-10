import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'theme/app_theme.dart';
import 'widgets/common_widgets.dart';

// ====================== KONFIGURASI ======================
const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://kbxcqfjhycwajuderddo.supabase.co',
);
const supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_-oq3SNz_r6Ea-QZRr-jSFg_V-FMl-Yk',
  ),
);
const enableDemoMode = bool.fromEnvironment(
  'ENABLE_DEMO_MODE',
  defaultValue: true,
);
const storageBucket = String.fromEnvironment(
  'SUPABASE_STORAGE_BUCKET',
  defaultValue: 'nely-uploads',
);
const storeMapsUrl = 'https://maps.app.goo.gl/GhsNfoGrtaYerH8i7';
const waNumber = String.fromEnvironment(
  'NELY_WHATSAPP',
  defaultValue: '628816715599',
);
const maxImageBytes = 5 * 1024 * 1024;

const burgundy = AppColors.ink;
const gold = AppColors.yellowText;
const cream = AppColors.background;
const rose = AppColors.pinkPastel;
const plumLight = AppColors.pinkStrong;

const jahitSteps = [
  'Pengajuan diterima',
  'Penawaran disetujui',
  'Pembayaran terverifikasi',
  'Persiapan bahan',
  'Pemotongan',
  'Penjahitan',
  'Fitting',
  'Finishing',
  'Siap diambil/dikirim',
  'Selesai',
];
const sewaSteps = [
  'Pengajuan diterima',
  'Ketersediaan dikonfirmasi',
  'Pembayaran terverifikasi',
  'Kebaya disiapkan',
  'Serah terima',
  'Digunakan',
  'Dikembalikan',
  'Pemeriksaan kondisi',
  'Selesai',
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabasePublishableKey,
      );
    } catch (error, stackTrace) {
      debugPrint('Supabase initialization failed: $error\n$stackTrace');
    }
  } else {
    debugPrint(
      'Supabase credentials are not configured; authenticated features are unavailable.',
    );
  }
  if (!enableDemoMode) Repo.clearDemoData();
  runApp(const NelyApp());
}

SupabaseClient? get db {
  try {
    return Supabase.instance.client;
  } catch (_) {
    return null;
  }
}

// ====================== HELPER ======================
int iv(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
String two(int n) => n.toString().padLeft(2, '0');
String ymd(DateTime t) => '${t.year}-${two(t.month)}-${two(t.day)}';

String? emailValidationError(String value) {
  final email = value.trim();
  if (email.isEmpty) return 'Email wajib diisi.';
  if (email.length > 254) return 'Email terlalu panjang.';
  final parts = email.split('@');
  if (parts.length != 2) return 'Masukkan alamat email yang valid.';
  final local = parts[0];
  final domain = parts[1];
  if (local.isEmpty ||
      local.length > 64 ||
      local.startsWith('.') ||
      local.endsWith('.') ||
      local.contains('..')) {
    return 'Masukkan alamat email yang valid.';
  }
  final localPattern = RegExp(r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+$");
  if (!localPattern.hasMatch(local)) {
    return 'Masukkan alamat email yang valid.';
  }
  final labels = domain.split('.');
  if (labels.length < 2 ||
      labels.any(
        (label) =>
            label.isEmpty ||
            label.length > 63 ||
            !RegExp(r'^[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?$')
                .hasMatch(label),
      ) ||
      !RegExp(r'^[A-Za-z]{2,63}$').hasMatch(labels.last)) {
    return 'Masukkan alamat email yang valid.';
  }
  return null;
}

String? passwordValidationError(String password) {
  if (password.length < 8) return 'Password minimal 8 karakter.';
  if (password.length > 128) return 'Password maksimal 128 karakter.';
  if (!RegExp(r'[a-z]').hasMatch(password)) {
    return 'Password harus memiliki huruf kecil.';
  }
  if (!RegExp(r'[A-Z]').hasMatch(password)) {
    return 'Password harus memiliki huruf besar.';
  }
  if (!RegExp(r'[0-9]').hasMatch(password)) {
    return 'Password harus memiliki angka.';
  }
  if (!RegExp(r"""[^A-Za-z0-9\s]""").hasMatch(password)) {
    return 'Password harus memiliki simbol, misalnya ! atau @.';
  }
  if (RegExp(r'\s').hasMatch(password)) {
    return 'Password tidak boleh mengandung spasi.';
  }
  return null;
}

String? whatsappValidationError(String value) {
  final number = value.trim();
  if (number.isEmpty) return 'Nomor WhatsApp wajib diisi.';
  if (!RegExp(r'^\+?[0-9][0-9\s().-]*$').hasMatch(number)) {
    return 'Masukkan nomor WhatsApp yang valid.';
  }
  final digits = number.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 8 || digits.length > 15) {
    return 'Nomor WhatsApp harus berisi 8 sampai 15 angka.';
  }
  return null;
}

String authErrorText(AuthException error) {
  final message = error.message.toLowerCase();
  if (message.contains('invalid login credentials')) {
    return 'Email atau password salah.';
  }
  if (message.contains('email not confirmed')) {
    return 'Email belum dikonfirmasi. Periksa kotak masuk email Anda.';
  }
  if (message.contains('already registered') ||
      message.contains('user already exists')) {
    return 'Email sudah terdaftar. Silakan masuk.';
  }
  if (message.contains('too many requests') || message.contains('rate limit')) {
    return 'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.';
  }
  if (message.contains('signup is disabled')) {
    return 'Pendaftaran sedang dinonaktifkan. Hubungi admin toko.';
  }
  return 'Autentikasi gagal. Periksa data dan koneksi, lalu coba lagi.';
}

String paymentRecordValue(String method) => switch (method) {
  'BRI' => 'Transfer',
  'QRIS' => 'QRIS',
  'Tunai' => 'Tunai',
  _ => throw ArgumentError.value(
    method,
    'method',
    'Metode pembayaran tidak didukung.',
  ),
};

String paymentDisplayValue(dynamic method) => switch (method) {
  'Transfer' => 'BRI',
  'QRIS' => 'QRIS',
  'Tunai' => 'Tunai',
  _ => '-',
};

String paymentMethodsSummary(Map<String, dynamic> info) {
  final briNumber = '${info['bri_account_number'] ?? ''}'.trim();
  final briName = '${info['bri_account_name'] ?? ''}'.trim();
  final qrisUrl = '${info['qris_image_url'] ?? ''}'.trim();
  var briSummary = 'BRI: $briNumber';
  if (briName.isNotEmpty) briSummary += ' a.n. $briName';
  return [
    briNumber.isEmpty ? 'BRI (nomor rekening belum diatur)' : briSummary,
    'Tunai',
    'QRIS${qrisUrl.isEmpty ? ' (barcode belum tersedia)' : ''}',
  ].join('\n');
}

String rp(num n) {
  final s = n.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return 'Rp$b';
}

bool isLocal(dynamic id) =>
    '$id'.startsWith('demo') || '$id'.startsWith('lokal');

void snack(BuildContext c, String m) {
  ScaffoldMessenger.of(c).showSnackBar(
    SnackBar(
      content: Text(m),
      behavior: SnackBarBehavior.floating,
      backgroundColor: burgundy,
    ),
  );
}

String backendErrorText(Object error) {
  final details = error.toString();
  if (details.contains('42501') ||
      details.toLowerCase().contains('row-level security')) {
    return 'Akses database ditolak. Pastikan migrasi CRUD sudah dijalankan '
        'dan role akun sesuai. Detail: $details';
  }
  if (details.contains('PGRST116')) {
    return 'Data yang akan diubah tidak ditemukan atau tidak dapat diakses. '
        'Muat ulang data dan periksa kebijakan Supabase. Detail: $details';
  }
  if (details.contains('23502') || details.contains('23503')) {
    return 'Data belum memenuhi aturan kolom database. Detail: $details';
  }
  if (details.contains('42703') || details.contains('PGRST204')) {
    return 'Skema database belum sesuai dengan aplikasi. Jalankan migrasi '
        'yang diperlukan. Detail: $details';
  }
  return details;
}

Future<T?> go<T>(BuildContext c, Widget p) => Navigator.push<T>(
  c,
  PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 450),
    pageBuilder: (_, a, b) => p,
    transitionsBuilder: (_, a, b, child) => SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
      child: FadeTransition(opacity: a, child: child),
    ),
  ),
);

Future<bool> openWa(
  BuildContext ctx, [
  String msg = 'Halo NELY Collection',
]) async {
  final u = Uri.parse(
    'https://wa.me/$waNumber?text=${Uri.encodeComponent(msg)}',
  );
  try {
    final ok = await launchUrl(u, mode: LaunchMode.externalApplication);
    if (!ok && ctx.mounted) snack(ctx, 'WhatsApp tidak bisa dibuka.');
    return ok;
  } catch (error, stackTrace) {
    debugPrint('Unable to open WhatsApp: $error\n$stackTrace');
    if (ctx.mounted) snack(ctx, 'WhatsApp tidak bisa dibuka.');
    return false;
  }
}

Future<bool> openStoreMaps(BuildContext ctx) async {
  try {
    final opened = await launchUrl(
      Uri.parse(storeMapsUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && ctx.mounted) snack(ctx, 'Google Maps tidak bisa dibuka.');
    return opened;
  } catch (error, stackTrace) {
    debugPrint('Unable to open store location: $error\n$stackTrace');
    if (ctx.mounted) snack(ctx, 'Google Maps tidak bisa dibuka.');
    return false;
  }
}

List<String> stepsOf(Map o) => o['jenis'] == 'sewa' ? sewaSteps : jahitSteps;

IconData iconForCategory(String category) => switch (category) {
  'jasa_jahit' => Icons.content_cut_rounded,
  'kebaya' => Icons.checkroom_rounded,
  'galeri' => Icons.photo_library_outlined,
  'pengalaman_toko' => Icons.auto_stories_outlined,
  'pesanan' => Icons.receipt_long_outlined,
  _ => Icons.storefront_outlined,
};

String? imageMimeType(String fileName, List<int> bytes) {
  final extension = fileName.split('.').last.toLowerCase();
  final isJpeg =
      bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff;
  final isPng =
      bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0d &&
      bytes[5] == 0x0a &&
      bytes[6] == 0x1a &&
      bytes[7] == 0x0a;
  final isWebp =
      bytes.length >= 12 &&
      String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP';
  if (isJpeg && (extension == 'jpg' || extension == 'jpeg')) {
    return 'image/jpeg';
  }
  if (isPng && extension == 'png') return 'image/png';
  if (isWebp && extension == 'webp') return 'image/webp';
  return null;
}

String? catalogImageUrl(Map<dynamic, dynamic> item) {
  for (final key in ['image_url', 'foto_url']) {
    final value = item[key];
    final uri = value is String ? Uri.tryParse(value) : null;
    if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
      return value;
    }
  }
  return null;
}

Map<String, dynamic> catalogCreateDefaults(String table) {
  if (!const {'jasa_jahit', 'kebaya', 'galeri'}.contains(table)) {
    throw ArgumentError.value(table, 'table', 'Tabel katalog tidak didukung.');
  }
  return {
    'emoji': '',
    if (table == 'jasa_jahit' || table == 'kebaya') 'aktif': true,
    if (table == 'kebaya') 'status': 'Tersedia',
    if (table == 'galeri') 'bisa_referensi': true,
  };
}

Widget catalogArtwork(
  Map<dynamic, dynamic> item,
  String category, {
  double size = 56,
}) => CatalogArtwork(
  imageUrl: catalogImageUrl(item),
  fallbackIcon: iconForCategory(category),
  size: size,
);

String statusText(Map o) {
  final st = stepsOf(o);
  final p = iv(o['proses']);
  if (p >= st.length - 1) return 'Selesai';
  if (iv(o['total']) == 0) return 'Menunggu Penawaran';
  if (p == 0) return 'Menunggu Persetujuan';
  if (o['status_bayar'] == 'Menunggu Verifikasi') return 'Menunggu Verifikasi';
  if (o['status_bayar'] != 'Terverifikasi') return 'Menunggu Pembayaran';
  return st[(p + 1).clamp(0, st.length - 1)];
}

Color statusColor(String s) {
  if (s == 'Selesai' || s == 'Terverifikasi') return AppColors.blueText;
  if (s.startsWith('Menunggu') || s == 'Belum Bayar') {
    return AppColors.yellowText;
  }
  if (s == 'Ditolak') return AppColors.pinkText;
  return AppColors.ink;
}

// ====================== DATA / REPO ======================
class Session {
  static String? userId;
  static String nama = 'Tamu';
  static String wa = '';
  static String role = 'customer';

  static Future<bool> loadProfile() async {
    final c = db;
    final u = c?.auth.currentUser;
    if (c == null || u == null) return false;
    userId = u.id;
    nama = u.userMetadata?['nama']?.toString() ?? u.email ?? 'Sahabat Nely';
    wa = u.userMetadata?['no_wa']?.toString() ?? '';
    role = 'customer';
    try {
      var p = await c.from('profiles').select().eq('id', u.id).maybeSingle();
      if (p == null) {
        await c.from('profiles').insert({
          'id': u.id,
          'nama': nama,
          'no_wa': wa,
          'role': 'customer',
        });
        p = await c.from('profiles').select().eq('id', u.id).single();
      }
      final profileRole = p['role']?.toString();
      if (profileRole != 'admin' && profileRole != 'customer') {
        throw StateError('Role profil tidak dikenal.');
      }
      nama = p['nama']?.toString() ?? 'Sahabat Nely';
      wa = p['no_wa']?.toString() ?? '';
      role = profileRole!;
      return true;
    } catch (error, stackTrace) {
      debugPrint('Unable to load user profile: $error\n$stackTrace');
      return false;
    }
  }

  static void reset() {
    userId = null;
    nama = 'Tamu';
    wa = '';
    role = 'customer';
  }
}

class Repo {
  static final Map<String, String> loadErrors = {};
  static final List<Map<String, dynamic>> jasa = [
    {
      'id': 'demo-j1',
      'nama': 'Jahit Dress',
      'deskripsi': 'Dress pesta custom sesuai ukuran tubuhmu',
      'harga_awal': 350000,
      'estimasi': '7-14 hari',
      'emoji': '👗',
    },
    {
      'id': 'demo-j2',
      'nama': 'Jahit Kebaya',
      'deskripsi': 'Kebaya modern & tradisional, bisa tambah payet/bordir',
      'harga_awal': 500000,
      'estimasi': '10-14 hari',
      'emoji': '👘',
    },
    {
      'id': 'demo-j3',
      'nama': 'Rok & Blouse',
      'deskripsi': 'Setelan rok dan blouse rapi untuk kerja/acara',
      'harga_awal': 150000,
      'estimasi': '5-7 hari',
      'emoji': '🎀',
    },
    {
      'id': 'demo-j4',
      'nama': 'Seragam & Batik',
      'deskripsi': 'Seragam keluarga, kantor, atau instansi',
      'harga_awal': 250000,
      'estimasi': '7-10 hari',
      'emoji': '🧵',
    },
    {
      'id': 'demo-j5',
      'nama': 'Permak Baju',
      'deskripsi': 'Kecilkan, panjangkan, ganti ritsleting',
      'harga_awal': 35000,
      'estimasi': '2-3 hari',
      'emoji': '✂️',
    },
  ];
  static final List<Map<String, dynamic>> kebaya = [
    {
      'id': 'demo-k1',
      'nama': 'Kebaya Brokat Maroon',
      'warna': 'Maroon',
      'harga_sewa': 150000,
      'deposit': 100000,
      'status': 'Tersedia',
      'lingkar_dada': 92,
      'lingkar_pinggang': 76,
      'panjang_kebaya': 60,
      'panjang_lengan': 55,
      'emoji': '👘',
    },
    {
      'id': 'demo-k2',
      'nama': 'Kebaya Kutubaru Gold',
      'warna': 'Emas',
      'harga_sewa': 175000,
      'deposit': 100000,
      'status': 'Tersedia',
      'lingkar_dada': 96,
      'lingkar_pinggang': 80,
      'panjang_kebaya': 62,
      'panjang_lengan': 56,
      'emoji': '✨',
    },
    {
      'id': 'demo-k3',
      'nama': 'Kebaya Modern Cream',
      'warna': 'Krem',
      'harga_sewa': 140000,
      'deposit': 75000,
      'status': 'Tersedia',
      'lingkar_dada': 88,
      'lingkar_pinggang': 72,
      'panjang_kebaya': 58,
      'panjang_lengan': 54,
      'emoji': '🤍',
    },
    {
      'id': 'demo-k4',
      'nama': 'Kebaya Wisuda Sage',
      'warna': 'Hijau Sage',
      'harga_sewa': 160000,
      'deposit': 100000,
      'status': 'Dipesan',
      'lingkar_dada': 90,
      'lingkar_pinggang': 74,
      'panjang_kebaya': 60,
      'panjang_lengan': 55,
      'emoji': '🎓',
    },
  ];
  static final List<Map<String, dynamic>> galeri = [
    {
      'id': 'demo-g1',
      'judul': 'Dress Satin Elegan',
      'kategori': 'Dress',
      'emoji': '👗',
    },
    {
      'id': 'demo-g2',
      'judul': 'Kebaya Payet Mewah',
      'kategori': 'Kebaya',
      'emoji': '👘',
    },
    {
      'id': 'demo-g3',
      'judul': 'Blouse Renda Manis',
      'kategori': 'Blouse',
      'emoji': '🎀',
    },
    {
      'id': 'demo-g4',
      'judul': 'Gamis Modern',
      'kategori': 'Gamis',
      'emoji': '🌸',
    },
    {
      'id': 'demo-g5',
      'judul': 'Kebaya Wisuda Klasik',
      'kategori': 'Kebaya',
      'emoji': '🎓',
    },
    {
      'id': 'demo-g6',
      'judul': 'Rok Plisket Anggun',
      'kategori': 'Rok',
      'emoji': '💃',
    },
  ];
  static final List<Map<String, dynamic>> pengalaman = [
    {
      'emoji': '📖',
      'judul': 'Cerita Perjalanan NELY',
      'isi': 'Berawal dari satu mesin jahit kecil, kini melayani banyak pelanggan.',
    },
    {
      'emoji': '🧵',
      'judul': 'Dokumentasi Proses Jahit',
      'isi': 'Dari pola, pemotongan, sampai finishing dikerjakan teliti.',
    },
    {
      'emoji': '🌟',
      'judul': 'Hasil Pekerjaan',
      'isi': 'Kumpulan kebaya dan dress hasil karya NELY Collection.',
    },
    {
      'emoji': '💖',
      'judul': 'Testimoni Pelanggan',
      'isi': 'Cerita bahagia dari pelanggan yang mengizinkan ditampilkan.',
    },
  ];
  static Map<String, dynamic> info = {
    'nama': 'NELY Collection',
    'deskripsi': 'Butik jasa jahit & sewa kebaya dengan sentuhan budaya Jawa. Dikerjakan rapi, dari hati.',
    'alamat': '93J2+R52, Ciwuntu, Sumingkir, Kec. Jeruklegi, Kabupaten Cilacap, Jawa Tengah 53274',
    'jam_buka': 'Senin - Sabtu, 09.00 - 17.00',
    'metode_bayar': 'BRI, Tunai, QRIS',
    'bri_account_number': '',
    'bri_account_name': '',
    'qris_image_url': '',
    'ketentuan': 'DP minimal 50% untuk jasa jahit. Pembatalan setelah pemotongan kain tidak dapat dikembalikan. Sewa kebaya wajib deposit dan dikembalikan sesuai tanggal.',
  };
  static final List<Map<String, dynamic>> pesanan = [];

  static void clearDemoData() {
    jasa.clear();
    kebaya.clear();
    galeri.clear();
    pengalaman.clear();
    pesanan.clear();
    info = {
      'nama': 'NELY Collection',
      'deskripsi': '',
      'alamat': '',
      'jam_buka': '',
      'metode_bayar': '',
      'bri_account_number': '',
      'bri_account_name': '',
      'qris_image_url': '',
      'ketentuan': '',
    };
  }

  static Future<String> uploadCatalogImage(
    String table,
    String fileName,
    Uint8List bytes,
  ) async {
    final client = db;
    if (client == null || client.auth.currentUser == null) {
      throw StateError('Masuk sebagai admin untuk mengunggah gambar.');
    }
    if (Session.userId == null ||
        client.auth.currentUser!.id != Session.userId ||
        Session.role != 'admin') {
      throw StateError('Hanya admin yang dapat mengunggah gambar katalog.');
    }
    if (!const {'jasa_jahit', 'kebaya', 'galeri'}.contains(table)) {
      throw ArgumentError.value(
        table,
        'table',
        'Tabel katalog tidak didukung.',
      );
    }
    if (bytes.length > maxImageBytes) {
      throw const FormatException('Ukuran gambar maksimal 5 MB.');
    }
    final mimeType = imageMimeType(fileName, bytes);
    if (mimeType == null) {
      throw const FormatException('Gunakan gambar JPEG, PNG, atau WebP.');
    }
    final extension = switch (mimeType) {
      'image/jpeg' => 'jpg',
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => throw const FormatException('Format gambar tidak didukung.'),
    };
    final path =
        'catalog/$table/${DateTime.now().microsecondsSinceEpoch}.$extension';
    try {
      await client.storage
          .from(storageBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: false),
          );
      return client.storage.from(storageBucket).getPublicUrl(path);
    } catch (error, stackTrace) {
      debugPrint('Unable to upload catalog image: $error\n$stackTrace');
      rethrow;
    }
  }

  static Future<String> uploadPaymentQrImage(
    String fileName,
    Uint8List bytes,
  ) async {
    final client = db;
    final user = client?.auth.currentUser;
    if (client == null ||
        user == null ||
        Session.userId != user.id ||
        Session.role != 'admin') {
      throw StateError('Masuk sebagai admin untuk mengunggah barcode QRIS.');
    }
    if (bytes.length > maxImageBytes) {
      throw const FormatException('Ukuran barcode maksimal 5 MB.');
    }
    final mimeType = imageMimeType(fileName, bytes);
    if (mimeType == null) {
      throw const FormatException(
        'Gunakan gambar barcode JPEG, PNG, atau WebP.',
      );
    }
    final extension = switch (mimeType) {
      'image/jpeg' => 'jpg',
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => throw const FormatException('Format gambar tidak didukung.'),
    };
    final path =
        'payments/qris/${DateTime.now().microsecondsSinceEpoch}.$extension';
    try {
      await client.storage
          .from(storageBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: false),
          );
      return client.storage.from(storageBucket).getPublicUrl(path);
    } catch (error, stackTrace) {
      debugPrint('Unable to upload QRIS barcode: $error\n$stackTrace');
      rethrow;
    }
  }

  static void _swap(List<Map<String, dynamic>> l, dynamic rows) {
    final r = List<Map<String, dynamic>>.from(
      (rows as List).map((e) => Map<String, dynamic>.from(e)),
    );
    l
      ..clear()
      ..addAll(r);
  }

  static Future<void> _loadRows(
    String key,
    List<Map<String, dynamic>> target,
    Future<dynamic> Function() query,
  ) async {
    try {
      _swap(target, await query());
      loadErrors.remove(key);
    } catch (error, stackTrace) {
      loadErrors[key] = backendErrorText(error);
      debugPrint('Unable to load $key: $error\n$stackTrace');
    }
  }

  static Future<void> load({bool includeInactive = false}) async {
    final c = db;
    if (c == null) return;
    await Future.wait([
      _loadRows(
        'jasa_jahit',
        jasa,
        () async => includeInactive
            ? await c.from('jasa_jahit').select()
            : await c.from('jasa_jahit').select().eq('aktif', true),
      ),
      _loadRows(
        'kebaya',
        kebaya,
        () async => includeInactive
            ? await c.from('kebaya').select()
            : await c.from('kebaya').select().eq('aktif', true),
      ),
      _loadRows('galeri', galeri, () async => await c.from('galeri').select()),
      _loadRows(
        'pengalaman_toko',
        pengalaman,
        () async => await c.from('pengalaman_toko').select(),
      ),
    ]);
    try {
      final i = await c.from('info_toko').select().order('id').limit(1);
      if ((i as List).isNotEmpty) {
        info = Map<String, dynamic>.from(i.first);
        loadErrors.remove('info_toko');
      } else {
        loadErrors['info_toko'] =
            'Baris informasi toko belum dibuat di tabel info_toko.';
      }
    } catch (error, stackTrace) {
      loadErrors['info_toko'] = backendErrorText(error);
      debugPrint('Unable to load shop information: $error\n$stackTrace');
    }
  }

  static Future<void> loadPesanan() async {
    final c = db;
    if (c == null || c.auth.currentUser == null) return;
    try {
      final r = await c
          .from('pesanan')
          .select()
          .order('created_at', ascending: false);
      final remote = List<Map<String, dynamic>>.from(
        (r as List).map((e) => Map<String, dynamic>.from(e)),
      );
      final lokal = pesanan.where((o) => isLocal(o['id'])).toList();
      pesanan
        ..clear()
        ..addAll(remote)
        ..addAll(lokal);
      loadErrors.remove('pesanan');
    } catch (error, stackTrace) {
      loadErrors['pesanan'] = backendErrorText(error);
      debugPrint('Unable to load orders: $error\n$stackTrace');
    }
  }

  static Future<Map<String, dynamic>> addPesanan(Map<String, dynamic> o) async {
    final data = {
      ...o,
      'user_id': Session.userId,
      'customer_nama': Session.nama,
      'customer_wa': Session.wa,
      'total': 0,
      'dp': 0,
      'proses': 0,
      'status_bayar': 'Belum Bayar',
    };
    final c = db;
    if (Session.userId != null && c == null) {
      throw StateError(
        'Tidak dapat terhubung ke server untuk menyimpan pesanan.',
      );
    }
    if (c != null && Session.userId != null) {
      try {
        final r = await c.from('pesanan').insert(data).select().single();
        final saved = Map<String, dynamic>.from(r);
        pesanan.insert(0, saved);
        return saved;
      } catch (error, stackTrace) {
        debugPrint('Unable to create order: $error\n$stackTrace');
        rethrow;
      }
    }
    data['id'] = 'lokal-${DateTime.now().millisecondsSinceEpoch}';
    data['created_at'] = DateTime.now().toIso8601String();
    pesanan.insert(0, data);
    return data;
  }

  static Future<void> updatePesanan(
    Map<String, dynamic> o,
    Map<String, dynamic> ch,
  ) async {
    final c = db;
    final user = c?.auth.currentUser;
    if (Session.userId == null) {
      if (!isLocal(o['id'])) {
        o['id'] = 'lokal-${DateTime.now().microsecondsSinceEpoch}';
      }
      o.addAll(ch);
      return;
    }
    if (user == null) {
      throw StateError('Sesi login tidak tersedia. Silakan login kembali.');
    }
    if (Session.role != 'admin' && o['user_id'] != Session.userId) {
      throw StateError('Anda tidak memiliki akses untuk mengubah pesanan ini.');
    }
    if (c == null) {
      throw StateError(
        'Tidak dapat terhubung ke server untuk memperbarui pesanan.',
      );
    }
    if (isLocal(o['id'])) {
      throw StateError(
        'Pesanan demo tidak dapat disimpan ke database. Muat ulang data.',
      );
    }
    if (user.id != Session.userId) {
      throw StateError('Sesi login berubah. Silakan login kembali.');
    }
    try {
      final updated = await c
          .from('pesanan')
          .update(ch)
          .eq('id', o['id'])
          .select()
          .single();
      o
        ..clear()
        ..addAll(Map<String, dynamic>.from(updated));
    } catch (error, stackTrace) {
      debugPrint('Unable to update order: $error\n$stackTrace');
      rethrow;
    }
  }

  static Future<void> saveCatalog(
    String table,
    List<Map<String, dynamic>> list,
    Map<String, dynamic> data,
    Map<String, dynamic>? item,
  ) async {
    final c = db;
    const allowedTables = {'jasa_jahit', 'kebaya', 'galeri'};
    if (!allowedTables.contains(table)) {
      throw ArgumentError.value(
        table,
        'table',
        'Tabel katalog tidak didukung.',
      );
    }
    if (Session.role != 'admin') {
      throw StateError('Hanya admin yang dapat mengelola katalog.');
    }
    final user = c?.auth.currentUser;
    if (Session.userId == null) {
      if (item == null) {
        list.add({
          'id': 'lokal-${DateTime.now().microsecondsSinceEpoch}',
          ...data,
        });
      } else {
        if (!isLocal(item['id'])) {
          item['id'] = 'lokal-${DateTime.now().microsecondsSinceEpoch}';
        }
        item.addAll(data);
      }
      return;
    }
    if (user == null) {
      throw StateError('Sesi login tidak tersedia. Silakan login kembali.');
    }
    if (user.id != Session.userId) {
      throw StateError('Sesi login berubah. Silakan login kembali.');
    }
    if (c == null) {
      throw StateError(
        'Tidak dapat terhubung ke server untuk menyimpan katalog.',
      );
    }
    if (item != null) {
      if (isLocal(item['id'])) {
        throw StateError(
          'Item demo tidak dapat disimpan ke database. Muat ulang data.',
        );
      }
      try {
        final updated = await c
            .from(table)
            .update(data)
            .eq('id', item['id'])
            .select()
            .single();
        item
          ..clear()
          ..addAll(Map<String, dynamic>.from(updated));
      } catch (error, stackTrace) {
        debugPrint('Unable to update $table catalog item: $error\n$stackTrace');
        rethrow;
      }
      return;
    }
    try {
      final created = await c.from(table).insert(data).select().single();
      list.add(Map<String, dynamic>.from(created));
    } catch (error, stackTrace) {
      debugPrint('Unable to create $table catalog item: $error\n$stackTrace');
      rethrow;
    }
  }

  static Future<void> deleteCatalog(
    String table,
    List<Map<String, dynamic>> list,
    Map<String, dynamic> item,
  ) async {
    final c = db;
    if (!const {'jasa_jahit', 'kebaya', 'galeri'}.contains(table)) {
      throw ArgumentError.value(
        table,
        'table',
        'Tabel katalog tidak didukung.',
      );
    }
    if (Session.role != 'admin') {
      throw StateError('Hanya admin yang dapat mengelola katalog.');
    }
    final user = c?.auth.currentUser;
    if (Session.userId == null) {
      list.remove(item);
      return;
    }
    if (user == null) {
      throw StateError('Sesi login tidak tersedia. Silakan login kembali.');
    }
    if (user.id != Session.userId) {
      throw StateError('Sesi login berubah. Silakan login kembali.');
    }
    if (c == null) {
      throw StateError(
        'Tidak dapat terhubung ke server untuk menghapus katalog.',
      );
    }
    if (isLocal(item['id'])) {
      throw StateError(
        'Item demo tidak dapat dihapus dari database. Muat ulang data.',
      );
    }
    try {
      await c.from(table).delete().eq('id', item['id']).select('id').single();
    } catch (error, stackTrace) {
      debugPrint('Unable to delete $table catalog item: $error\n$stackTrace');
      rethrow;
    }
    list.remove(item);
  }

  static Future<void> saveInfo(Map<String, dynamic> ch) async {
    if (Session.role != 'admin') {
      throw StateError('Hanya admin yang dapat mengubah informasi toko.');
    }
    final c = db;
    final user = c?.auth.currentUser;
    if (Session.userId == null) {
      info.addAll(ch);
      return;
    }
    if (user == null) {
      throw StateError('Sesi login tidak tersedia. Silakan login kembali.');
    }
    if (user.id != Session.userId) {
      throw StateError('Sesi login berubah. Silakan login kembali.');
    }
    if (c == null) {
      throw StateError(
        'Tidak dapat terhubung ke server untuk menyimpan informasi toko.',
      );
    }
    try {
      final cachedId = info['id'];
      final row = cachedId == null
          ? await c
                .from('info_toko')
                .select('id')
                .order('id')
                .limit(1)
                .maybeSingle()
          : {'id': cachedId};
      if (row == null) {
        throw StateError(
          'Baris informasi toko belum dibuat di tabel info_toko. '
          'Tambahkan satu baris toko di Supabase lalu coba lagi.',
        );
      }
      final updated = await c
          .from('info_toko')
          .update(ch)
          .eq('id', row['id'])
          .select()
          .single();
      info
        ..clear()
        ..addAll(Map<String, dynamic>.from(updated));
    } catch (error, stackTrace) {
      debugPrint('Unable to update shop information: $error\n$stackTrace');
      rethrow;
    }
  }
}

Future<void> showSuccess(BuildContext ctx, String title, String sub) =>
    showDialog(
      context: ctx,
      builder: (c) => Dialog(
        backgroundColor: cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 56,
                color: burgundy,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: burgundy,
                ),
              ),
              const SizedBox(height: 6),
              Text(sub, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Selesai'),
              ),
            ],
          ),
        ),
      ),
    );

// ====================== APP ======================
class NelyApp extends StatelessWidget {
  const NelyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'NELY Collection',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: const SplashPage(),
  );
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambient;
  bool _motionInitialized = false;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    );
    _boot();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_motionInitialized) {
      _motionInitialized = true;
      if (!MediaQuery.disableAnimationsOf(context)) {
        _ambient.repeat(reverse: true);
      }
    } else if (MediaQuery.disableAnimationsOf(context)) {
      _ambient.stop();
      _ambient.value = 0;
    } else if (!_ambient.isAnimating) {
      _ambient.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ambient.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    final profileReady = await Session.loadProfile();
    await Repo.load(includeInactive: Session.role == 'admin');
    await Repo.loadPesanan();
    if (!mounted) return;
    final Widget next = Session.userId == null
        ? const AuthPage()
        : (Session.role == 'admin'
              ? const AdminShell()
              : const CustomerShell());
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, b) => next,
        transitionsBuilder: (_, a, b, c) =>
            FadeTransition(opacity: a, child: c),
      ),
    );
    if (Session.userId != null && !profileReady && mounted) {
      snack(
        context,
        'Sesi tetap aktif. Profil belum tersinkron; periksa akses profil Supabase.',
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Stack(
        children: [
          Positioned(
            right: -54,
            top: -52,
            child: _ambientCircle(
              190,
              AppColors.pinkPastel,
              const Offset(0, -8),
            ),
          ),
          Positioned(
            left: -60,
            bottom: -64,
            child: _ambientCircle(
              210,
              AppColors.bluePastel,
              const Offset(0, 10),
            ),
          ),
          Positioned(
            right: 28,
            bottom: 156,
            child: _ambientCircle(
              44,
              AppColors.yellowPastel,
              const Offset(0, -5),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandMark(size: 124),
                  const SizedBox(height: 22),
                  Pop(
                    child: Text(
                      'NELY Collection',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall
                          ?.copyWith(fontSize: 40),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'JASA JAHIT & SEWA KEBAYA',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.pinkText,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 22),
                  StitchLine(animation: _ambient),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: 116,
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      color: AppColors.blueStrong,
                      backgroundColor: AppColors.bluePastel,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Ukur, pesan, dan lacak jahitan dari ponsel.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _ambientCircle(double size, Color color, Offset movement) =>
      AnimatedBuilder(
        animation: _ambient,
        builder: (_, child) => Transform.translate(
          offset: movement * _ambient.value,
          child: child,
        ),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      );
}

// ====================== AUTH ======================
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool register = false, loading = false, hide = true;
  final nama = TextEditingController(),
      wa = TextEditingController(),
      email = TextEditingController(),
      pass = TextEditingController(),
      confirmPass = TextEditingController();

  @override
  void dispose() {
    nama.dispose();
    wa.dispose();
    email.dispose();
    pass.dispose();
    confirmPass.dispose();
    super.dispose();
  }

  void _enter() {
    final Widget p = Session.role == 'admin'
        ? const AdminShell()
        : const CustomerShell();
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, b) => p,
        transitionsBuilder: (_, a, b, c) =>
            FadeTransition(opacity: a, child: c),
      ),
    );
  }

  Future<void> _submit() async {
    if (loading) return;
    if (register) {
      final name = nama.text.trim();
      if (name.length < 2 || name.length > 80) {
        snack(context, 'Nama lengkap harus terdiri dari 2 sampai 80 karakter.');
        return;
      }
      final phoneError = whatsappValidationError(wa.text);
      if (phoneError != null) {
        snack(context, phoneError);
        return;
      }
    }
    if (register && confirmPass.text != pass.text) {
      snack(context, 'Konfirmasi password tidak sama.');
      return;
    }
    final emailError = emailValidationError(email.text);
    if (emailError != null) {
      snack(context, emailError);
      return;
    }
    final passwordError = passwordValidationError(pass.text);
    if (passwordError != null) {
      snack(context, passwordError);
      return;
    }
    final c = db;
    if (c == null) {
      snack(
        context,
        enableDemoMode
            ? 'Supabase belum terhubung. Silakan gunakan Mode Demo.'
            : 'Server Supabase belum terhubung. Periksa koneksi dan konfigurasi aplikasi.',
      );
      return;
    }
    setState(() => loading = true);
    try {
      if (register) {
        final response = await c.auth.signUp(
          email: email.text.trim(),
          password: pass.text,
          data: {'nama': nama.text.trim(), 'no_wa': wa.text.trim()},
        );
        if (response.session == null) {
          if (mounted) {
            snack(
              context,
              'Pendaftaran berhasil. Konfirmasi email Anda, lalu masuk dengan akun tersebut.',
            );
            setState(() {
              register = false;
              pass.clear();
            });
          }
          return;
        }
      } else {
        await c.auth.signInWithPassword(
          email: email.text.trim(),
          password: pass.text,
        );
      }
      final profileReady = await Session.loadProfile();
      await Repo.load(includeInactive: Session.role == 'admin');
      await Repo.loadPesanan();
      if (mounted) {
        _enter();
        if (!profileReady) {
          snack(
            context,
            'Anda masuk sebagai pelanggan sementara; profil belum dapat dibaca. '
            'Periksa migrasi akses profil Supabase.',
          );
        }
      }
    } on AuthException catch (e) {
      debugPrint('Authentication rejected: ${e.message}');
      if (mounted) snack(context, authErrorText(e));
    } on StateError catch (e) {
      debugPrint('Unable to establish authenticated profile: $e');
      try {
        await c.auth.signOut();
      } catch (signOutError, stackTrace) {
        debugPrint('Unable to clear invalid login: $signOutError\n$stackTrace');
      }
      Session.reset();
      if (mounted) snack(context, e.message);
    } catch (error, stackTrace) {
      debugPrint('Authentication request failed: $error\n$stackTrace');
      if (mounted) {
        snack(
          context,
          'Koneksi ke server bermasalah: ${backendErrorText(error)}',
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _forgot() async {
    final emailError = emailValidationError(email.text);
    if (emailError != null) {
      snack(context, emailError);
      return;
    }
    final c = db;
    if (c == null) {
      snack(context, 'Layanan akun sedang tidak tersedia. Coba lagi nanti.');
      return;
    }
    try {
      await c.auth.resetPasswordForEmail(email.text.trim());
      if (mounted) {
        snack(context, 'Tautan reset password dikirim ke email Anda.');
      }
    } catch (error, stackTrace) {
      debugPrint('Unable to send password reset email: $error\n$stackTrace');
      if (mounted) snack(context, 'Gagal mengirim. Cek email dan koneksi ya.');
    }
  }

  void _demo(String role) {
    if (!enableDemoMode) return;
    Session.userId = null;
    Session.nama = role == 'admin' ? 'Admin Demo' : 'Tamu Demo';
    Session.wa = '081234567890';
    Session.role = role;
    _enter();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 10),
          const Center(child: BrandMark(size: 96)),
          const SizedBox(height: 14),
          Center(
            child: Text(
              register ? 'Buat akun NELY Collection' : 'Selamat datang kembali',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: burgundy,
              ),
            ),
          ),
          const SizedBox(height: 22),
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            child: Column(
              children: [
                if (register) ...[
                  TextField(
                    controller: nama,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    decoration: const InputDecoration(
                      labelText: 'Nama lengkap',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: wa,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    decoration: const InputDecoration(
                      labelText: 'No. WhatsApp',
                      hintText: 'Contoh: 081234567890',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: pass,
            obscureText: hide,
            autofillHints: [
              register ? AutofillHints.newPassword : AutofillHints.password,
            ],
            textInputAction: TextInputAction.done,
            onSubmitted: loading ? null : (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              helperText:
                  'Min. 8 karakter: huruf besar-kecil, angka, dan simbol.',
              helperMaxLines: 2,
              suffixIcon: IconButton(
                icon: Icon(hide ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => hide = !hide),
              ),
            ),
          ),
          if (register) ...[
            const SizedBox(height: 12),
            TextField(
              controller: confirmPass,
              obscureText: hide,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              onSubmitted: loading ? null : (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Konfirmasi password',
                prefixIcon: Icon(Icons.lock_reset_outlined),
              ),
            ),
          ],
          if (!register)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: loading ? null : _forgot,
                child: const Text('Lupa password?'),
              ),
            ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: loading ? null : _submit,
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(register ? 'Daftar' : 'Masuk'),
          ),
          TextButton(
            onPressed: loading
                ? null
                : () => setState(() => register = !register),
            child: Text(
              register ? 'Sudah punya akun? Masuk' : 'Belum punya akun? Daftar',
            ),
          ),
          if (enableDemoMode) ...[
            const Divider(height: 30),
            OutlinedButton.icon(
              onPressed: () => _demo('customer'),
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Coba Mode Demo (Customer)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _demo('admin'),
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: const Text('Coba Mode Demo (Admin)'),
            ),
          ],
        ],
      ),
    ),
  );
}

// ====================== CUSTOMER SHELL ======================
class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});
  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int i = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(goTab: (t) => setState(() => i = t)),
      const JasaListPage(),
      const KebayaListPage(),
      const GaleriPage(),
      const ProfilPage(),
    ];
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(key: ValueKey(i), child: pages[i]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: i,
        onDestinationSelected: (v) => setState(() => i = v),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.design_services_outlined),
            label: 'Jahit',
          ),
          NavigationDestination(
            icon: Icon(Icons.checkroom_outlined),
            label: 'Sewa',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_rounded),
            label: 'Galeri',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final void Function(int) goTab;
  const HomePage({super.key, required this.goTab});

  Widget _tile(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
    int index,
    Color tone,
  ) => Pop(
    i: index,
    child: Bouncy(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tone,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 26, color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final currentOrders = Repo.pesanan.where(
      (order) =>
          (Session.userId == null || order['user_id'] == Session.userId) &&
          iv(order['proses']) < stepsOf(order).length - 1,
    );
    final Map<String, dynamic>? runningOrder = currentOrders.isEmpty
        ? null
        : currentOrders.first;
    final services = [
      (
        Icons.content_cut_outlined,
        'Jasa Jahit',
        () => goTab(1),
        AppColors.pinkPastel,
      ),
      (
        Icons.checkroom_outlined,
        'Sewa Kebaya',
        () => goTab(2),
        AppColors.bluePastel,
      ),
      (
        Icons.photo_library_outlined,
        'Galeri',
        () => goTab(3),
        AppColors.yellowPastel,
      ),
      (
        Icons.receipt_long_outlined,
        'Riwayat',
        () => go(context, const OrdersPage()),
        AppColors.pinkPastel,
      ),
    ];
    final quickLinks = [
      (
        Icons.storefront_outlined,
        'Informasi Toko',
        () => go(context, const InfoTokoPage()),
      ),
      (
        Icons.auto_stories_outlined,
        'Pengalaman Toko',
        () => go(context, const PengalamanPage()),
      ),
      (Icons.chat_bubble_outline, 'WhatsApp', () => openWa(context)),
      (
        Icons.help_outline,
        'Cara Pesan',
        () => showSuccess(
          context,
          'Cara Pesan',
          'Pilih layanan, isi detail dan ukuran, tunggu penawaran, lalu pantau progres pesanan.',
        ),
      ),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat datang di',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.muted),
                    ),
                    Text(
                      'NELY Collection',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    Text(
                      Session.nama,
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(color: AppColors.pinkText),
                    ),
                  ],
                ),
              ),
              Material(
                color: AppColors.surface,
                shape: const CircleBorder(
                  side: BorderSide(color: AppColors.border),
                ),
                child: IconButton(
                  tooltip: 'Profil',
                  onPressed: () => goTab(4),
                  icon: const Icon(Icons.person_outline, color: AppColors.ink),
                  constraints: const BoxConstraints.tightFor(
                    width: 48,
                    height: 48,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          nCard(
            color: AppColors.pinkPastel,
            pad: const EdgeInsets.all(22),
            onTap: () => goTab(1),
            child: Stack(
              children: [
                Positioned(
                  right: -8,
                  bottom: -30,
                  child: Icon(
                    Icons.circle,
                    size: 86,
                    color: AppColors.yellowStrong.withValues(alpha: .65),
                  ),
                ),
                Positioned(
                  right: 22,
                  bottom: -40,
                  child: Icon(
                    Icons.circle,
                    size: 72,
                    color: AppColors.blueStrong.withValues(alpha: .55),
                  ),
                ),
                Positioned(
                  right: 4,
                  top: 0,
                  child: Icon(
                    Icons.content_cut_outlined,
                    size: 34,
                    color: AppColors.pinkText.withValues(alpha: .75),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'JASA JAHIT & SEWA KEBAYA',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.pinkText,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 260),
                      child: Text(
                        'Jahitan pas, tampil memukau',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(fontSize: 32, height: 1),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: () => goTab(1),
                      child: const Text('Pesan Sekarang'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          sectionTitle('Layanan Kami'),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 24) / 4;
              return Wrap(
                spacing: 8,
                runSpacing: 14,
                children: [
                  for (var index = 0; index < services.length; index++)
                    SizedBox(
                      width: width,
                      child: _tile(
                        context,
                        services[index].$1,
                        services[index].$2,
                        services[index].$3,
                        index,
                        services[index].$4,
                      ),
                    ),
                ],
              );
            },
          ),
          if (runningOrder != null) ...[
            sectionTitle('Pesanan Berjalan'),
            nCard(
              onTap: () => go(context, OrderDetailPage(runningOrder)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.yellowPastel,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          iconForCategory(
                            runningOrder['jenis'] == 'sewa'
                                ? 'kebaya'
                                : 'jasa_jahit',
                          ),
                          color: AppColors.yellowText,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${runningOrder['item_nama'] ?? 'Pesanan'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'Estimasi selesai ${runningOrder['tanggal_butuh'] ?? runningOrder['tanggal_kembali'] ?? '-'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      tag(statusText(runningOrder), AppColors.blueText),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value:
                          ((iv(runningOrder['proses']) + 1) /
                                  stepsOf(runningOrder).length)
                              .clamp(0.0, 1.0),
                      minHeight: 8,
                      color: AppColors.pinkAccent,
                      backgroundColor: AppColors.field,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tahap ${iv(runningOrder['proses']) + 1} dari ${stepsOf(runningOrder).length}  ·  Lihat detail',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
          sectionTitle('Koleksi Pilihan'),
          SizedBox(
            height: 176,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: Repo.jasa.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, index) {
                final service = Repo.jasa[index];
                final tones = [
                  AppColors.pinkPastel,
                  AppColors.yellowPastel,
                  AppColors.bluePastel,
                ];
                return Pop(
                  i: index,
                  child: SizedBox(
                    width: 156,
                    child: nCard(
                      onTap: () => go(context, JasaDetailPage(service)),
                      pad: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SizedBox(
                              width: double.infinity,
                              child: CatalogArtwork(
                                imageUrl: catalogImageUrl(service),
                                fallbackIcon: Icons.checkroom_outlined,
                                background: tones[index % tones.length],
                                size: 128,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${service['nama'] ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          Text(
                            'Mulai ${rp(iv(service['harga_awal']))}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.pinkText,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          sectionTitle('Informasi & Bantuan'),
          GridView.builder(
            itemCount: quickLinks.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.8,
            ),
            itemBuilder: (context, index) => nCard(
              onTap: quickLinks[index].$3,
              pad: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    quickLinks[index].$1,
                    color: index == 2 ? AppColors.whatsapp : AppColors.pinkText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      quickLinks[index].$2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Jasa Jahit ----------
class JasaListPage extends StatelessWidget {
  const JasaListPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Jasa Jahit'),
      automaticallyImplyLeading: false,
    ),
    body: ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: Repo.jasa.length,
      separatorBuilder: (_, i) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final j = Repo.jasa[i];
        return Pop(
          i: i,
          child: nCard(
            onTap: () => go(context, JasaDetailPage(j)),
            child: Row(
              children: [
                catalogArtwork(j, 'jasa_jahit', size: 62),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        j['nama'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        j['deskripsi'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'mulai ${rp(iv(j['harga_awal']))}',
                        style: const TextStyle(
                          color: gold,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class JasaDetailPage extends StatelessWidget {
  final Map<String, dynamic> j;
  const JasaDetailPage(this.j, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(j['nama'])),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(child: catalogArtwork(j, 'jasa_jahit', size: 180)),
        const SizedBox(height: 14),
        Pop(
          child: nCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  j['nama'],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: burgundy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(j['deskripsi'] ?? ''),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    tag('Mulai ${rp(iv(j['harga_awal']))}', gold),
                    tag('Estimasi: ${j['estimasi'] ?? '-'}', burgundy),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Pop(
          i: 2,
          child: nCard(
            color: rose,
            child: const Text(
              'Harga final ditentukan admin setelah meninjau ukuran, model, dan bahan yang dipilih.',
            ),
          ),
        ),
        const SizedBox(height: 22),
        ElevatedButton(
          onPressed: () => go(context, OrderJahitPage(jasa: j)),
          child: const Text('Mulai Pemesanan'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.whatsapp,
            side: const BorderSide(color: AppColors.whatsapp),
          ),
          onPressed: () =>
              openWa(context, 'Halo, saya mau tanya soal ${j['nama']}'),
          child: const Text('Tanya via WhatsApp'),
        ),
      ],
    ),
  );
}

// ---------- Form Pesan Jahit ----------
class OrderJahitPage extends StatefulWidget {
  final Map<String, dynamic> jasa;
  final String? referensi;
  const OrderJahitPage({super.key, required this.jasa, this.referensi});
  @override
  State<OrderJahitPage> createState() => _OrderJahitPageState();
}

class _OrderJahitPageState extends State<OrderJahitPage> {
  static const ukuranMap = {
    'Dress': [
      'Lingkar dada',
      'Lingkar pinggang',
      'Lingkar pinggul',
      'Lebar bahu',
      'Panjang badan',
      'Panjang lengan',
      'Lingkar lengan',
      'Panjang dress',
    ],
    'Kebaya': [
      'Lingkar dada',
      'Lingkar pinggang',
      'Lingkar pinggul',
      'Lebar bahu',
      'Panjang badan depan',
      'Panjang badan belakang',
      'Panjang lengan',
      'Lingkar pergelangan',
      'Lingkar leher',
    ],
    'Rok': ['Lingkar pinggang', 'Lingkar pinggul', 'Panjang rok'],
    'Blouse': [
      'Lingkar dada',
      'Lingkar pinggang',
      'Lebar bahu',
      'Panjang badan',
      'Panjang lengan',
      'Lingkar leher',
    ],
    'Celana': [
      'Lingkar pinggang',
      'Lingkar pinggul',
      'Panjang celana',
      'Lingkar paha',
    ],
  };
  static const extras = [
    'Renda',
    'Bordir',
    'Payet',
    'Furing',
    'Lengan custom',
    'Kerah custom',
  ];
  static const titles = [
    'Detail Pakaian',
    'Ukuran Tubuh',
    'Model & Referensi',
    'Jadwal & Pengiriman',
    'Review',
  ];

  final pc = PageController();
  int step = 0, jumlah = 1;
  String jenis = 'Dress', ambil = 'Ambil di toko';
  final warna = TextEditingController(),
      bahan = TextEditingController(),
      catatan = TextEditingController();
  final Map<String, TextEditingController> uk = {};
  final Set<String> ex = {};
  bool unggah = false, sending = false;
  DateTime? tgl;
  String? ref;

  @override
  void initState() {
    super.initState();
    ref = widget.referensi;
  }

  @override
  void dispose() {
    pc.dispose();
    warna.dispose();
    bahan.dispose();
    catatan.dispose();
    for (final controller in uk.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController ctl(String f) =>
      uk.putIfAbsent('$jenis|$f', () => TextEditingController());

  void _to(int s) {
    setState(() => step = s);
    pc.animateToPage(
      s,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _next() {
    if (step == 3 && tgl == null) {
      snack(context, 'Pilih tanggal kebutuhan terlebih dahulu.');
      return;
    }
    if (step == 4) {
      _submit();
    } else {
      _to(step + 1);
    }
  }

  Map<String, String> get ukuran => {
    for (final f in ukuranMap[jenis]!)
      if (ctl(f).text.trim().isNotEmpty) f: '${ctl(f).text.trim()} cm',
  };

  Future<void> _submit() async {
    setState(() => sending = true);
    try {
      await Repo.addPesanan({
        'jenis': 'jahit',
        'item_nama': widget.jasa['nama'],
        'detail': {
          'jenis_pakaian': jenis,
          'warna': warna.text.trim(),
          'bahan': bahan.text.trim(),
          'jumlah': jumlah,
          'tambahan': ex.toList(),
          'catatan': catatan.text.trim(),
          'referensi': ref ?? (unggah ? 'Diminta via WhatsApp' : '-'),
          'metode_ambil': ambil,
        },
        'ukuran': ukuran,
        'tanggal_butuh': ymd(tgl!),
      });
      if (!mounted) return;
      await showSuccess(
        context,
        'Pesanan berhasil dikirim',
        'Admin akan memeriksa pesanan dan mengirimkan penawaran harga.',
      );
      if (!mounted) return;
      if (unggah) {
        await openWa(
          context,
          'Halo NELY, saya akan mengirim foto referensi untuk ${widget.jasa['nama']}.',
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (error, stackTrace) {
      debugPrint('Unable to submit sewing order: $error\n$stackTrace');
      if (mounted) {
        snack(context, 'Pesanan gagal disimpan: ${backendErrorText(error)}');
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Widget _chips(
    List<String> items,
    bool Function(String) sel,
    void Function(String) tap,
  ) => Wrap(
    spacing: 8,
    runSpacing: 4,
    children: [
      for (final e in items)
        ChoiceChip(
          label: Text(e),
          selected: sel(e),
          selectedColor: rose,
          onSelected: (_) => tap(e),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      // 0
      ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Jenis pakaian',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          _chips(
            ukuranMap.keys.toList(),
            (e) => e == jenis,
            (e) => setState(() => jenis = e),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: warna,
            decoration: const InputDecoration(
              labelText: 'Warna yang diinginkan',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: bahan,
            decoration: const InputDecoration(
              labelText: 'Bahan (brokat, satin, katun...)',
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text(
                'Jumlah',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              IconButton.filledTonal(
                onPressed: () =>
                    setState(() => jumlah = jumlah > 1 ? jumlah - 1 : 1),
                icon: const Icon(Icons.remove),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  '$jumlah',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => setState(() => jumlah++),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
      // 1
      ListView(
        padding: const EdgeInsets.all(20),
        children: [
          nCard(
            color: rose,
            child: Text(
              'Ukuran untuk $jenis (dalam cm). Kosongkan jika belum tahu; admin akan membantu.',
            ),
          ),
          const SizedBox(height: 12),
          for (final f in ukuranMap[jenis]!)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: ctl(f),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: f, suffixText: 'cm'),
              ),
            ),
        ],
      ),
      // 2
      ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Tambahan model',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          _chips(
            extras,
            ex.contains,
            (e) => setState(() => ex.contains(e) ? ex.remove(e) : ex.add(e)),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: catatan,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Catatan request (model lengan, kerah, panjang...)',
            ),
          ),
          const SizedBox(height: 14),
          if (ref != null)
            nCard(
              color: rose,
              child: Row(
                children: [
                  const Icon(Icons.image_outlined),
                  Expanded(child: Text('Referensi: $ref')),
                  IconButton(
                    onPressed: () => setState(() => ref = null),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              await openWa(
                context,
                'Halo NELY, saya ingin mengirim foto referensi untuk ${widget.jasa['nama']}.',
              );
              if (mounted) setState(() => unggah = true);
            },
            icon: Icon(unggah ? Icons.check_circle : Icons.chat_rounded),
            label: Text(
              unggah
                  ? 'WhatsApp dibuka untuk foto referensi'
                  : 'Kirim foto referensi via WhatsApp',
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final pick = await showModalBottomSheet<String>(
                context: context,
                builder: (c) => ListView(
                  children: [
                    for (final g in Repo.galeri)
                      ListTile(
                        leading: Icon(
                          iconForCategory('galeri'),
                          color: burgundy,
                        ),
                        title: Text(g['judul']),
                        onTap: () => Navigator.pop(c, g['judul']),
                      ),
                  ],
                ),
              );
              if (pick != null) setState(() => ref = pick);
            },
            icon: const Icon(Icons.photo_library_rounded),
            label: const Text('Pilih dari Galeri'),
          ),
        ],
      ),
      // 3
      ListView(
        padding: const EdgeInsets.all(20),
        children: [
          nCard(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 14)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (d != null) setState(() => tgl = d);
            },
            child: Row(
              children: [
                const Icon(Icons.calendar_month_outlined, color: burgundy),
                const SizedBox(width: 12),
                Text(
                  tgl == null ? 'Pilih tanggal dibutuhkan' : ymd(tgl!),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pengambilan / pengiriman',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          _chips(
            ['Ambil di toko', 'Dikirim ke alamat'],
            (e) => e == ambil,
            (e) => setState(() => ambil = e),
          ),
        ],
      ),
      // 4
      ListView(
        padding: const EdgeInsets.all(20),
        children: [
          nCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.jasa['nama'],
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: burgundy,
                  ),
                ),
                const Divider(),
                Text('Jenis: $jenis  •  Jumlah: $jumlah'),
                Text(
                  'Warna: ${warna.text.isEmpty ? '-' : warna.text}  •  Bahan: ${bahan.text.isEmpty ? '-' : bahan.text}',
                ),
                Text('Tambahan: ${ex.isEmpty ? '-' : ex.join(', ')}'),
                Text('Catatan: ${catatan.text.isEmpty ? '-' : catatan.text}'),
                Text('Referensi: ${ref ?? (unggah ? 'Foto customer' : '-')}'),
                Text('Tanggal: ${tgl == null ? '-' : ymd(tgl!)}  •  $ambil'),
                const Divider(),
                const Text(
                  'Ukuran:',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                if (ukuran.isEmpty)
                  const Text('Belum diisi')
                else
                  for (final e in ukuran.entries)
                    Text('• ${e.key}: ${e.value}'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Setelah dikirim, admin akan memeriksa dan memberikan penawaran harga.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('${step + 1}/5 • ${titles[step]}')),
      body: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: (step + 1) / 5),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (_, v, w) => LinearProgressIndicator(
              value: v.clamp(0.0, 1.0),
              minHeight: 6,
              color: gold,
              backgroundColor: rose,
            ),
          ),
          Expanded(
            child: PageView(
              controller: pc,
              physics: const NeverScrollableScrollPhysics(),
              children: pages,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _to(step - 1),
                        child: const Text('Kembali'),
                      ),
                    ),
                  if (step > 0) const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: sending ? null : _next,
                      child: Text(step == 4 ? 'Kirim Pesanan' : 'Lanjut'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Sewa Kebaya ----------
class KebayaListPage extends StatelessWidget {
  const KebayaListPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Sewa Kebaya'),
      automaticallyImplyLeading: false,
    ),
    body: GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: Repo.kebaya.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: .82,
      ),
      itemBuilder: (_, i) {
        final k = Repo.kebaya[i];
        final ok = k['status'] == 'Tersedia';
        return Pop(
          i: i,
          child: nCard(
            onTap: () => go(context, KebayaDetailPage(k)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                catalogArtwork(k, 'kebaya', size: 112),
                const SizedBox(height: 8),
                Text(
                  k['nama'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${rp(iv(k['harga_sewa']))}/hari',
                  style: const TextStyle(
                    color: gold,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                tag(
                  k['status'] ?? '-',
                  ok ? Colors.green.shade700 : Colors.orange.shade800,
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class KebayaDetailPage extends StatefulWidget {
  final Map<String, dynamic> k;
  const KebayaDetailPage(this.k, {super.key});
  @override
  State<KebayaDetailPage> createState() => _KebayaDetailPageState();
}

class _KebayaDetailPageState extends State<KebayaDetailPage> {
  DateTimeRange? range;
  bool sending = false;

  Future<void> _sewa() async {
    final k = widget.k;
    if (k['status'] != 'Tersedia') {
      snack(context, 'Kebaya ini sedang tidak tersedia.');
      return;
    }
    if (range == null) {
      snack(
        context,
        'Pilih tanggal pemakaian dan pengembalian terlebih dahulu.',
      );
      return;
    }
    setState(() => sending = true);
    try {
      await Repo.addPesanan({
        'jenis': 'sewa',
        'item_nama': k['nama'],
        'detail': {
          'warna': k['warna'],
          'deposit': iv(k['deposit']),
          'harga_per_hari': iv(k['harga_sewa']),
          'hari': range!.duration.inDays + 1,
        },
        'ukuran': {},
        'tanggal_sewa': ymd(range!.start),
        'tanggal_kembali': ymd(range!.end),
      });
      if (!mounted) return;
      await showSuccess(
        context,
        'Pengajuan sewa berhasil dikirim',
        'Admin akan memeriksa ketersediaan dan mengirimkan total biaya.',
      );
      if (mounted) Navigator.pop(context);
    } catch (error, stackTrace) {
      debugPrint('Unable to submit rental order: $error\n$stackTrace');
      if (mounted) {
        snack(
          context,
          'Pengajuan sewa gagal disimpan: ${backendErrorText(error)}',
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.k;
    final hari = range == null ? 0 : range!.duration.inDays + 1;
    return Scaffold(
      appBar: AppBar(title: Text(k['nama'])),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(child: catalogArtwork(k, 'kebaya', size: 180)),
          const SizedBox(height: 10),
          Pop(
            child: nCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          k['nama'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: burgundy,
                          ),
                        ),
                      ),
                      tag(
                        k['status'] ?? '-',
                        k['status'] == 'Tersedia'
                            ? Colors.green.shade700
                            : Colors.orange.shade800,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Warna: ${k['warna'] ?? '-'}'),
                  Text(
                    'Sewa ${rp(iv(k['harga_sewa']))}/hari  •  Deposit ${rp(iv(k['deposit']))}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Pop(
            i: 2,
            child: nCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ukuran aktual kebaya',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text('Lingkar dada: ${k['lingkar_dada'] ?? '-'} cm'),
                  Text('Lingkar pinggang: ${k['lingkar_pinggang'] ?? '-'} cm'),
                  Text('Panjang kebaya: ${k['panjang_kebaya'] ?? '-'} cm'),
                  Text('Panjang lengan: ${k['panjang_lengan'] ?? '-'} cm'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          nCard(
            onTap: () async {
              final r = await showDateRangePicker(
                context: context,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (r != null) setState(() => range = r);
            },
            child: Row(
              children: [
                const Icon(Icons.calendar_month_outlined, color: burgundy),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    range == null
                        ? 'Pilih tanggal pakai → kembali'
                        : '${ymd(range!.start)}  →  ${ymd(range!.end)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          if (range != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: nCard(
                color: rose,
                child: Text(
                  'Estimasi: $hari hari × ${rp(iv(k['harga_sewa']))} = ${rp(hari * iv(k['harga_sewa']))}  (+ deposit ${rp(iv(k['deposit']))})',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: sending ? null : _sewa,
            child: const Text('Ajukan Sewa'),
          ),
        ],
      ),
    );
  }
}

// ---------- Galeri ----------
class GaleriPage extends StatelessWidget {
  const GaleriPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Galeri'),
      automaticallyImplyLeading: false,
    ),
    body: GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: Repo.galeri.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: .95,
      ),
      itemBuilder: (_, i) {
        final g = Repo.galeri[i];
        return Pop(
          i: i,
          child: nCard(
            onTap: () => showModalBottomSheet(
              context: context,
              backgroundColor: cream,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              builder: (c) => Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    catalogArtwork(g, 'galeri', size: 180),
                    Text(
                      g['judul'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: burgundy,
                      ),
                    ),
                    tag(g['kategori'] ?? '-', gold),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(c);
                        go(
                          context,
                          OrderJahitPage(
                            jasa: Repo.jasa.first,
                            referensi: g['judul'],
                          ),
                        );
                      },
                      child: const Text('Gunakan sebagai Referensi'),
                    ),
                  ],
                ),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                catalogArtwork(g, 'galeri', size: 112),
                const SizedBox(height: 8),
                Text(
                  g['judul'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                tag(g['kategori'] ?? '-', gold),
              ],
            ),
          ),
        );
      },
    ),
  );
}

// ---------- Info Toko & Pengalaman ----------
class InfoTokoPage extends StatelessWidget {
  const InfoTokoPage({super.key});
  @override
  Widget build(BuildContext context) {
    final i = Repo.info;
    Widget row(IconData e, String t, String v, int n) => Pop(
      i: n,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: nCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(e, size: 24, color: burgundy),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: burgundy,
                      ),
                    ),
                    Text(v),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Informasi Toko')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Center(child: BrandMark(size: 72)),
          const SizedBox(height: 10),
          Center(
            child: Text(
              i['nama'] ?? '',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: burgundy,
              ),
            ),
          ),
          const SizedBox(height: 14),
          row(
            Icons.info_outline_rounded,
            'Tentang Kami',
            '${i['deskripsi'] ?? ''}',
            0,
          ),
          row(Icons.location_on_outlined, 'Alamat', '${i['alamat'] ?? ''}', 1),
          row(
            Icons.schedule_rounded,
            'Jam Operasional',
            '${i['jam_buka'] ?? ''}',
            2,
          ),
          row(
            Icons.credit_card_outlined,
            'Metode Pembayaran',
            paymentMethodsSummary(i),
            3,
          ),
          row(
            Icons.description_outlined,
            'Ketentuan',
            '${i['ketentuan'] ?? ''}',
            4,
          ),
          OutlinedButton.icon(
            onPressed: () => openStoreMaps(context),
            icon: const Icon(Icons.map_rounded),
            label: const Text('Buka Lokasi Toko di Google Maps'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.whatsapp,
              foregroundColor: Colors.white,
            ),
            onPressed: () => openWa(context),
            icon: const Icon(Icons.chat_rounded),
            label: const Text('Chat WhatsApp'),
          ),
        ],
      ),
    );
  }
}

class PengalamanPage extends StatelessWidget {
  const PengalamanPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pengalaman Toko')),
    body: ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: Repo.pengalaman.length,
      separatorBuilder: (_, i) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final p = Repo.pengalaman[i];
        return Pop(
          i: i,
          child: nCard(
            child: Row(
              children: [
                Icon(
                  iconForCategory('pengalaman_toko'),
                  size: 32,
                  color: burgundy,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['judul'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: burgundy,
                        ),
                      ),
                      Text(p['isi'] ?? ''),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

// ====================== PESANAN / TRACKING / BAYAR ======================
class OrdersPage extends StatefulWidget {
  final bool admin, tab, paymentsOnly;
  const OrdersPage({
    super.key,
    this.admin = false,
    this.tab = false,
    this.paymentsOnly = false,
  });
  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  String filter = 'Semua';
  bool loadingOrders = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    if (mounted) setState(() => loadingOrders = true);
    await Repo.loadPesanan();
    if (mounted) setState(() => loadingOrders = false);
  }

  @override
  Widget build(BuildContext context) {
    final all = Repo.pesanan
        .where(
          (o) =>
              widget.admin ||
              Session.userId == null ||
              o['user_id'] == Session.userId,
        )
        .toList();
    final list = all
        .where(
          (o) => widget.paymentsOnly
              ? (iv(o['total']) > 0 ||
                    o['status_bayar'] == 'Menunggu Verifikasi' ||
                    o['status_bayar'] == 'Terverifikasi' ||
                    o['status_bayar'] == 'Ditolak')
              : (filter == 'Semua' ||
                    (filter == 'Jahit'
                        ? o['jenis'] == 'jahit'
                        : o['jenis'] == 'sewa')),
        )
        .where(
          (o) =>
              !widget.paymentsOnly ||
              filter == 'Semua' ||
              o['status_bayar'] == filter,
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.paymentsOnly
              ? 'Kelola Pembayaran'
              : (widget.admin ? 'Kelola Pesanan' : 'Riwayat Pesanan'),
        ),
        automaticallyImplyLeading: !widget.tab,
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: loadingOrders ? null : _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.admin)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final f
                      in widget.paymentsOnly
                          ? [
                              'Semua',
                              'Belum Bayar',
                              'Menunggu Verifikasi',
                              'Terverifikasi',
                              'Ditolak',
                            ]
                          : ['Semua', 'Jahit', 'Sewa'])
                    ChoiceChip(
                      label: Text(f),
                      selected: filter == f,
                      selectedColor: rose,
                      onSelected: (_) => setState(() => filter = f),
                    ),
                ],
              ),
            ),
          if (Repo.loadErrors['pesanan'] != null && !loadingOrders)
            MaterialBanner(
              content: Text(Repo.loadErrors['pesanan']!),
              leading: const Icon(Icons.cloud_off_outlined),
              actions: [
                TextButton(onPressed: _reload, child: const Text('Coba lagi')),
              ],
            ),
          Expanded(
            child: loadingOrders
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const BrandMark(size: 72),
                        const SizedBox(height: 14),
                        Text(
                          Repo.loadErrors['pesanan'] ??
                              (widget.paymentsOnly
                                  ? 'Belum ada pembayaran'
                                  : 'Belum ada pesanan'),
                          textAlign: TextAlign.center,
                        ),
                        if (Repo.loadErrors.containsKey('pesanan'))
                          TextButton.icon(
                            onPressed: _reload,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba lagi'),
                          ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    separatorBuilder: (_, i) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final o = list[i];
                      final st = statusText(o);
                      final n = stepsOf(o).length;
                      return Pop(
                        i: i,
                        child: nCard(
                          onTap: () async {
                            await go(
                              context,
                              OrderDetailPage(o, admin: widget.admin),
                            );
                            if (mounted) setState(() {});
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    iconForCategory(
                                      o['jenis'] == 'sewa'
                                          ? 'kebaya'
                                          : 'jasa_jahit',
                                    ),
                                    size: 26,
                                    color: burgundy,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      o['item_nama'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  tag(st, statusColor(st)),
                                ],
                              ),
                              if (widget.admin)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Pelanggan: ${o['customer_nama'] ?? '-'}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              if (widget.paymentsOnly) ...[
                                const SizedBox(height: 5),
                                Text(
                                  'Tagihan: ${iv(o['total']) == 0 ? 'Belum ditetapkan' : rp(iv(o['total']))}'
                                  '  ·  DP: ${rp(iv(o['dp']))}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  'Metode: ${paymentDisplayValue(o['metode_bayar'])}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                              const SizedBox(height: 10),
                              TweenAnimationBuilder<double>(
                                tween: Tween(
                                  begin: 0,
                                  end: (iv(o['proses']) + 1) / n,
                                ),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOutCubic,
                                builder: (_, v, w) => ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: v.clamp(0.0, 1.0),
                                    minHeight: 8,
                                    color: gold,
                                    backgroundColor: rose,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class OrderDetailPage extends StatefulWidget {
  final Map<String, dynamic> o;
  final bool admin;
  const OrderDetailPage(this.o, {super.key, this.admin = false});
  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Map<String, dynamic> get o => widget.o;

  Future<void> _upd(Map<String, dynamic> ch) async {
    try {
      await Repo.updatePesanan(o, ch);
      if (mounted) {
        setState(() {});
        snack(
          context,
          Session.userId == null
              ? 'Perubahan hanya tersimpan sementara dalam Mode Demo.'
              : 'Perubahan pesanan berhasil disimpan.',
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Unable to save order changes: $error\n$stackTrace');
      if (mounted) {
        snack(
          context,
          'Perubahan pesanan gagal disimpan: ${backendErrorText(error)}',
        );
      }
    }
  }

  Future<void> _setHarga() async {
    final t = TextEditingController(
      text: iv(o['total']) == 0 ? '' : '${iv(o['total'])}',
    );
    final d = TextEditingController(
      text: iv(o['dp']) == 0 ? '' : '${iv(o['dp'])}',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Tetapkan Harga'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: t,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Total (Rp)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: d,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'DP (Rp)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final totalText = t.text.trim();
    final dpText = d.text.trim();
    t.dispose();
    d.dispose();
    if (ok != true) return;
    final total = int.tryParse(totalText);
    final dp = int.tryParse(dpText);
    if (total == null || total <= 0 || dp == null || dp < 0 || dp > total) {
      if (mounted) {
        snack(
          context,
          'Masukkan total lebih dari 0 dan DP antara 0 sampai total.',
        );
      }
      return;
    }
    await _upd({'total': total, 'dp': dp});
  }

  Future<void> _maju() async {
    final n = stepsOf(o).length;
    final p = iv(o['proses']);
    if (p >= n - 1) return;
    if (p == 0) {
      snack(context, 'Menunggu pelanggan menyetujui penawaran.');
      return;
    }
    if (p + 1 >= 2 && o['status_bayar'] != 'Terverifikasi') {
      snack(context, 'Pembayaran harus terverifikasi sebelum melanjutkan.');
      return;
    }
    await _upd({'proses': p + 1});
  }

  @override
  Widget build(BuildContext context) {
    final steps = stepsOf(o);
    final p = iv(o['proses']);
    final det = Map<String, dynamic>.from(o['detail'] ?? {});
    final uk = Map<String, dynamic>.from(o['ukuran'] ?? {});
    final sb = '${o['status_bayar']}';
    final total = iv(o['total']);
    final tunai = o['metode_bayar'] == 'Tunai' && sb == 'Belum Bayar';
    final progress = (p + 1) / steps.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Lacak Pesanan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        children: [
          nCard(
            color: AppColors.pinkPastel,
            pad: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${o['item_nama'] ?? 'Pesanan NELY'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'No. pesanan ${o['id'] ?? '-'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (widget.admin)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Pelanggan: ${o['customer_nama'] ?? '-'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      const SizedBox(height: 10),
                      tag(statusText(o), AppColors.yellowText),
                      const SizedBox(height: 8),
                      Text(
                        o['jenis'] == 'sewa'
                            ? '${o['tanggal_sewa'] ?? '-'} – ${o['tanggal_kembali'] ?? '-'}'
                            : 'Estimasi selesai ${o['tanggal_butuh'] ?? '-'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ProgressRing(
                  value: progress,
                  label: '${p + 1}/${steps.length}',
                  caption: 'tahap',
                ),
              ],
            ),
          ),
          sectionTitle('Progres Pesanan'),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      _Dot(state: i < p ? 2 : (i == p ? 1 : 0)),
                      if (i < steps.length - 1)
                        Container(
                          width: 2,
                          height: 38,
                          color: i < p
                              ? AppColors.pinkStrong
                              : AppColors.border,
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            steps[i],
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: i == p
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: i == p
                                      ? AppColors.pinkText
                                      : (i < p
                                            ? AppColors.ink
                                            : AppColors.muted),
                                ),
                          ),
                          if (i > p)
                            Text(
                              'Menunggu',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          sectionTitle('Rincian'),
          nCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final e in det.entries)
                  if ('${e.value}'.isNotEmpty &&
                      '${e.value}' != '[]' &&
                      '${e.value}' != '-')
                    Text('• ${e.key}: ${e.value}'),
                if (uk.isNotEmpty) ...[
                  const Divider(),
                  const Text(
                    'Ukuran',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  for (final e in uk.entries) Text('• ${e.key}: ${e.value}'),
                ],
              ],
            ),
          ),
          sectionTitle('Pembayaran'),
          nCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total: ${total == 0 ? 'belum ditetapkan' : rp(total)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  'DP: ${rp(iv(o['dp']))}   •   Sisa: ${rp(total - iv(o['dp']))}',
                ),
                Text('Metode: ${paymentDisplayValue(o['metode_bayar'])}'),
                const SizedBox(height: 6),
                tag(sb, statusColor(sb)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!widget.admin) ...[
            if (total == 0)
              const Text(
                'Menunggu penawaran harga dari admin...',
                textAlign: TextAlign.center,
              ),
            if (total > 0 && p == 0)
              ElevatedButton(
                onPressed: () => _upd({'proses': 1}),
                child: const Text('Setujui Penawaran'),
              ),
            if (total > 0 &&
                p >= 1 &&
                (sb == 'Belum Bayar' || sb == 'Ditolak') &&
                o['metode_bayar'] != 'Tunai')
              ElevatedButton(
                onPressed: () async {
                  await go(context, PaymentPage(o));
                  if (mounted) setState(() {});
                },
                child: const Text('Bayar Sekarang'),
              ),
            if (sb == 'Ditolak')
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Pembayaran ditolak admin. Silakan kirim bukti pembayaran yang benar.',
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.whatsapp,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: () => openWa(
                context,
                'Halo, saya mau tanya pesanan ${o['item_nama']}',
              ),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Hubungi via WhatsApp'),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: _setHarga,
              child: const Text('Tetapkan Harga'),
            ),
            if (sb == 'Menunggu Verifikasi' || tunai) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                      ),
                      onPressed: () => _upd({
                        'status_bayar': 'Terverifikasi',
                        'proses': p < 2 ? 2 : p,
                      }),
                      child: Text(tunai ? 'Tunai Diterima' : 'Verifikasi'),
                    ),
                  ),
                  if (!tunai) const SizedBox(width: 8),
                  if (!tunai)
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                        ),
                        onPressed: () => _upd({'status_bayar': 'Ditolak'}),
                        child: const Text('Tolak'),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: p >= steps.length - 1 ? null : _maju,
              child: Text(
                p >= steps.length - 1
                    ? 'Pesanan Selesai'
                    : 'Tahap Berikutnya: ${steps[p + 1]}',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.whatsapp,
                side: const BorderSide(color: AppColors.whatsapp),
              ),
              onPressed: () => openWa(
                context,
                'Halo ${o['customer_nama'] ?? ''}, soal pesanan ${o['item_nama']}...',
              ),
              child: const Text('Hubungi Customer'),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int state; // 0 belum, 1 sedang, 2 selesai
  const _Dot({required this.state});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController c;

  @override
  void initState() {
    super.initState();
    c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  void _syncAnimation() {
    if (widget.state == 1 && !MediaQuery.disableAnimationsOf(context)) {
      if (!c.isAnimating) c.repeat(reverse: true);
    } else {
      c.stop();
      c.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _Dot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) _syncAnimation();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return AnimatedBuilder(
      animation: c,
      builder: (_, _) => SizedBox(
        width: 28,
        height: 28,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (s == 1 && c.isAnimating)
              Container(
                width: 12 + 16 * c.value,
                height: 12 + 16 * c.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.yellowStrong.withValues(alpha: 1 - c.value),
                ),
              ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: s == 2
                    ? AppColors.pinkStrong
                    : (s == 1 ? AppColors.yellowStrong : AppColors.surface),
                border: s == 0
                    ? const Border.fromBorderSide(
                        BorderSide(color: AppColors.border, width: 2),
                      )
                    : null,
              ),
              child: s == 2
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: AppColors.ink,
                    )
                  : (s == 1
                        ? const Icon(
                            Icons.circle,
                            size: 8,
                            color: AppColors.ink,
                          )
                        : null),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentPage extends StatefulWidget {
  final Map<String, dynamic> o;
  const PaymentPage(this.o, {super.key});
  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String m = 'Tunai';
  bool sending = false;

  Future<void> _bayar() async {
    if (m == 'BRI' &&
        '${Repo.info['bri_account_number'] ?? ''}'.trim().isEmpty) {
      snack(context, 'Nomor rekening BRI belum diatur admin.');
      return;
    }
    if (m == 'QRIS' &&
        catalogImageUrl({'image_url': Repo.info['qris_image_url']}) == null) {
      snack(context, 'Barcode QRIS belum diatur admin.');
      return;
    }
    setState(() => sending = true);
    try {
      await Repo.updatePesanan(widget.o, {
        'metode_bayar': paymentRecordValue(m),
        'status_bayar': m == 'Tunai' ? 'Belum Bayar' : 'Menunggu Verifikasi',
      });
      if (!mounted) return;
      if (m != 'Tunai') {
        await openWa(
          context,
          'Halo NELY, saya memilih pembayaran $m untuk pesanan '
          '${widget.o['item_nama']} '
          '(${rp(iv(widget.o['dp']) > 0 ? iv(widget.o['dp']) : iv(widget.o['total']))}). '
          'Saya akan mengirim bukti pembayaran melalui chat ini.',
        );
      }
      if (!mounted) return;
      if (m == 'Tunai') {
        await showSuccess(
          context,
          'Siap bayar di toko',
          'Admin akan mencatat pembayaran saat uang diterima.',
        );
      } else {
        await showSuccess(
          context,
          'Metode pembayaran dicatat',
          'Selesaikan pembayaran menggunakan $m, lalu kirim bukti melalui WhatsApp agar admin dapat memverifikasinya.',
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (error, stackTrace) {
      debugPrint('Unable to submit payment: $error\n$stackTrace');
      if (mounted) {
        snack(context, 'Pembayaran gagal dicatat: ${backendErrorText(error)}');
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.o;
    final bayar = iv(o['dp']) > 0 ? iv(o['dp']) : iv(o['total']);
    final info = Repo.info;
    final briNumber = '${info['bri_account_number'] ?? ''}'.trim();
    final briName = '${info['bri_account_name'] ?? ''}'.trim();
    final qrisImageUrl = '${info['qris_image_url'] ?? ''}'.trim();
    Widget opt(IconData e, String l, {bool available = true}) => Expanded(
      child: nCard(
        color: m == l ? rose : Colors.white,
        pad: const EdgeInsets.symmetric(vertical: 14),
        onTap: sending || !available ? null : () => setState(() => m = l),
        child: Column(
          children: [
            Icon(e, size: 28, color: available ? burgundy : AppColors.muted),
            Text(l, style: const TextStyle(fontWeight: FontWeight.w800)),
            if (!available)
              const Text(
                'Belum diatur',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: AppColors.muted),
              ),
          ],
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Center(
            child: Text(
              'Bayar ${rp(bayar)}',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: burgundy,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              opt(
                Icons.account_balance_outlined,
                'BRI',
                available: briNumber.isNotEmpty,
              ),
              const SizedBox(width: 8),
              opt(Icons.payments_outlined, 'Tunai'),
              const SizedBox(width: 8),
              opt(
                Icons.qr_code_2_outlined,
                'QRIS',
                available: catalogImageUrl({'image_url': qrisImageUrl}) != null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: KeyedSubtree(
              key: ValueKey(m),
              child: m == 'Tunai'
                  ? nCard(
                      child: const Text(
                        'Bayar tunai langsung di toko. Admin akan mencatat pembayaran setelah diterima.',
                      ),
                    )
                  : m == 'BRI'
                  ? nCard(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.account_balance_outlined,
                            size: 44,
                            color: burgundy,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Transfer Bank BRI',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            briNumber.isEmpty
                                ? 'Nomor rekening belum tersedia. Hubungi admin melalui WhatsApp.'
                                : briNumber,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: burgundy,
                            ),
                          ),
                          if (briName.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('a.n. $briName'),
                          ],
                        ],
                      ),
                    )
                  : nCard(
                      child: Column(
                        children: [
                          const Text(
                            'Pindai barcode QRIS berikut',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          if (qrisImageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                qrisImageUrl,
                                height: 240,
                                width: double.infinity,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => const Text(
                                  'Barcode QRIS gagal dimuat. Hubungi admin.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          else
                            const Text(
                              'Barcode QRIS belum diunggah admin. Hubungi admin melalui WhatsApp.',
                              textAlign: TextAlign.center,
                            ),
                          const SizedBox(height: 8),
                          Text('Jumlah pembayaran: ${rp(bayar)}'),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: sending ? null : _bayar,
            child: Text(
              m == 'Tunai'
                  ? 'Konfirmasi Bayar Tunai'
                  : 'Pilih $m dan kirim bukti via WhatsApp',
            ),
          ),
        ],
      ),
    );
  }
}

// ====================== PROFIL ======================
class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  Future<void> _editInfo(BuildContext context) async {
    final a = TextEditingController(text: '${Repo.info['alamat'] ?? ''}');
    final j = TextEditingController(text: '${Repo.info['jam_buka'] ?? ''}');
    final briNumber = TextEditingController(
      text: '${Repo.info['bri_account_number'] ?? ''}',
    );
    final briName = TextEditingController(
      text: '${Repo.info['bri_account_name'] ?? ''}',
    );
    var qrisImageUrl = '${Repo.info['qris_image_url'] ?? ''}';
    var saving = false;
    await showDialog<void>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setDialogState) => AlertDialog(
          title: const Text('Edit Informasi Toko'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: a,
                  decoration: const InputDecoration(labelText: 'Alamat'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: j,
                  decoration: const InputDecoration(
                    labelText: 'Jam operasional',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: briNumber,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nomor rekening BRI',
                    prefixIcon: Icon(Icons.account_balance_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: briName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nama pemilik rekening BRI',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Barcode QRIS',
                    style: Theme.of(c).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(height: 8),
                if (qrisImageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      qrisImageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const SizedBox(
                        height: 100,
                        child: Center(
                          child: Text('Gambar QRIS tidak dapat dimuat.'),
                        ),
                      ),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('Barcode belum ditambahkan.'),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: saving
                            ? null
                            : () async {
                                try {
                                  final image = await ImagePicker().pickImage(
                                    source: ImageSource.gallery,
                                  );
                                  if (image == null) return;
                                  setDialogState(() => saving = true);
                                  final imageUrl =
                                      await Repo.uploadPaymentQrImage(
                                        image.name,
                                        await image.readAsBytes(),
                                      );
                                  if (c.mounted) {
                                    setDialogState(() {
                                      qrisImageUrl = imageUrl;
                                      saving = false;
                                    });
                                  }
                                } catch (error, stackTrace) {
                                  debugPrint(
                                    'Unable to select QRIS barcode: '
                                    '$error\n$stackTrace',
                                  );
                                  if (c.mounted) {
                                    setDialogState(() => saving = false);
                                    snack(
                                      c,
                                      'Barcode QRIS gagal diunggah: '
                                      '${backendErrorText(error)}',
                                    );
                                  }
                                }
                              },
                        icon: const Icon(Icons.image_outlined),
                        label: Text(
                          qrisImageUrl.isEmpty
                              ? 'Pilih Barcode'
                              : 'Ganti Barcode',
                        ),
                      ),
                    ),
                    if (qrisImageUrl.isNotEmpty)
                      IconButton(
                        tooltip: 'Hapus barcode',
                        onPressed: saving
                            ? null
                            : () => setDialogState(() => qrisImageUrl = ''),
                        icon: const Icon(Icons.delete_outline),
                      ),
                  ],
                ),
                const Text(
                  'Format JPEG, PNG, atau WebP; maksimal 5 MB.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(c),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      setDialogState(() => saving = true);
                      try {
                        final accountNumber = briNumber.text.trim();
                        final accountDigits = accountNumber.replaceAll(
                          RegExp(r'\D'),
                          '',
                        );
                        if (accountNumber.isEmpty !=
                            briName.text.trim().isEmpty) {
                          throw const FormatException(
                            'Isi nomor rekening dan nama pemilik BRI bersamaan.',
                          );
                        }
                        if (accountNumber.isNotEmpty &&
                            (accountDigits.length < 8 ||
                                accountDigits.length > 16)) {
                          throw const FormatException(
                            'Nomor rekening BRI harus berisi 8 sampai 16 angka.',
                          );
                        }
                        await Repo.saveInfo({
                          'alamat': a.text.trim(),
                          'jam_buka': j.text.trim(),
                          'metode_bayar': 'BRI, Tunai, QRIS',
                          'bri_account_number': briNumber.text.trim(),
                          'bri_account_name': briName.text.trim(),
                          'qris_image_url': qrisImageUrl,
                        });
                        if (!c.mounted) return;
                        Navigator.pop(c);
                        if (context.mounted) {
                          snack(
                            context,
                            Session.userId == null
                                ? 'Informasi berubah sementara dalam Mode Demo.'
                                : 'Informasi toko diperbarui.',
                          );
                        }
                      } catch (error, stackTrace) {
                        debugPrint(
                          'Unable to save shop information: '
                          '$error\n$stackTrace',
                        );
                        if (context.mounted) {
                          snack(
                            c,
                            'Info toko gagal disimpan: ${backendErrorText(error)}',
                          );
                        }
                      } finally {
                        if (c.mounted) setDialogState(() => saving = false);
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    a.dispose();
    j.dispose();
    briNumber.dispose();
    briName.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await db?.auth.signOut();
    } catch (error, stackTrace) {
      debugPrint('Unable to sign out from Supabase: $error\n$stackTrace');
      if (context.mounted) {
        snack(context, 'Sesi lokal ditutup, tetapi server gagal dihubungi.');
      }
    }
    Session.reset();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthPage()),
        (r) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = Session.role == 'admin';
    Widget item(IconData e, String t, VoidCallback f, int i) => Pop(
      i: i,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: nCard(
          onTap: f,
          child: Row(
            children: [
              Icon(e, size: 24, color: burgundy),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  t,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Center(child: BrandMark(size: 72)),
          const SizedBox(height: 10),
          Center(
            child: Text(
              Session.nama,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: burgundy,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: tag(admin ? 'Admin' : 'Customer', gold),
            ),
          ),
          const SizedBox(height: 18),
          if (!admin)
            item(
              Icons.receipt_long_outlined,
              'Riwayat Pesanan',
              () => go(context, const OrdersPage()),
              0,
            ),
          item(
            Icons.storefront_outlined,
            'Informasi Toko',
            () => go(context, const InfoTokoPage()),
            1,
          ),
          item(
            Icons.auto_stories_outlined,
            'Pengalaman Toko',
            () => go(context, const PengalamanPage()),
            2,
          ),
          item(
            Icons.chat_outlined,
            'Hubungi via WhatsApp',
            () => openWa(context),
            3,
          ),
          if (admin)
            item(
              Icons.edit_outlined,
              'Edit Info Toko',
              () => _editInfo(context),
              4,
            ),
          item(Icons.logout_rounded, 'Keluar', () => _logout(context), 5),
        ],
      ),
    );
  }
}

// ====================== ADMIN ======================
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int i = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      AdminDash(goTab: (t) => setState(() => i = t)),
      const OrdersPage(admin: true, tab: true),
      const OrdersPage(admin: true, tab: true, paymentsOnly: true),
      const AdminCatalogPage(),
      const ProfilPage(),
    ];
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(key: ValueKey(i), child: pages[i]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: i,
        onDestinationSelected: (v) => setState(() => i = v),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Pesanan',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            label: 'Pembayaran',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Katalog',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}

class AdminDash extends StatefulWidget {
  final void Function(int) goTab;
  const AdminDash({super.key, required this.goTab});
  @override
  State<AdminDash> createState() => _AdminDashState();
}

class _AdminDashState extends State<AdminDash> {
  @override
  void initState() {
    super.initState();
    Repo.loadPesanan().then((_) {
      if (mounted) setState(() {});
    });
  }

  Widget stat(IconData e, String l, num v, int i, {bool money = false}) => Pop(
    i: i,
    child: nCard(
      onTap: () => widget.goTab(1),
      child: Column(
        children: [
          Icon(e, size: 30, color: burgundy),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: v.toDouble()),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, x, w) => Text(
              money ? rp(x) : x.round().toString(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: burgundy,
              ),
            ),
          ),
          Text(
            l,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final ps = Repo.pesanan;
    final baru = ps
        .where((o) => iv(o['total']) == 0 && iv(o['proses']) == 0)
        .length;
    final verif = ps
        .where((o) => o['status_bayar'] == 'Menunggu Verifikasi')
        .length;
    final jahit = ps
        .where(
          (o) =>
              o['jenis'] == 'jahit' &&
              iv(o['proses']) >= 3 &&
              iv(o['proses']) < jahitSteps.length - 2,
        )
        .length;
    final disewa = ps
        .where(
          (o) =>
              o['jenis'] == 'sewa' &&
              iv(o['proses']) >= 4 &&
              iv(o['proses']) < sewaSteps.length - 1,
        )
        .length;
    final nj = ps.where((o) => o['jenis'] == 'jahit').length;
    final ns = ps.where((o) => o['jenis'] == 'sewa').length;
    final dapat = ps
        .where((o) => o['status_bayar'] == 'Terverifikasi')
        .fold<int>(0, (a, o) => a + iv(o['total']));
    Widget bar(String l, int v, int max) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 50, child: Text(l)),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: max == 0 ? 0 : v / max),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, x, w) => ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: x.clamp(0.0, 1.0),
                  minHeight: 14,
                  color: gold,
                  backgroundColor: rose,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              ' $v',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(18, 24, 18, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bluePastel,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dashboard Admin',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Selamat datang, ${Session.nama}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const BrandMark(size: 60),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: MediaQuery.sizeOf(context).width < 400
                    ? 0.9
                    : 1.25,
                children: [
                  stat(
                    Icons.fiber_new_outlined,
                    'Pesanan baru / perlu penawaran',
                    baru,
                    0,
                  ),
                  stat(
                    Icons.receipt_long_outlined,
                    'Pembayaran perlu diverifikasi',
                    verif,
                    1,
                  ),
                  stat(Icons.content_cut_rounded, 'Sedang dijahit', jahit, 2),
                  stat(
                    Icons.checkroom_rounded,
                    'Kebaya sedang disewa',
                    disewa,
                    3,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Pop(
                i: 4,
                child: nCard(
                  color: rose,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        size: 30,
                        color: burgundy,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pendapatan terverifikasi',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: dapat.toDouble()),
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeOutCubic,
                              builder: (_, x, w) => Text(
                                rp(x),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: burgundy,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Pop(
                i: 5,
                child: nCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Laporan Pesanan',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: burgundy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      bar('Jahit', nj, nj > ns ? nj : ns),
                      bar('Sewa', ns, nj > ns ? nj : ns),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AdminCatalogPage extends StatefulWidget {
  const AdminCatalogPage({super.key});
  @override
  State<AdminCatalogPage> createState() => _AdminCatalogPageState();
}

class _AdminCatalogPageState extends State<AdminCatalogPage> {
  bool loadingCatalog = true;

  @override
  void initState() {
    super.initState();
    _reloadCatalog();
  }

  Future<void> _reloadCatalog() async {
    if (mounted) setState(() => loadingCatalog = true);
    await Repo.load(includeInactive: true);
    if (mounted) setState(() => loadingCatalog = false);
  }

  Future<void> _form(
    String table,
    List<Map<String, dynamic>> list, [
    Map<String, dynamic>? item,
  ]) async {
    final nameKey = table == 'galeri' ? 'judul' : 'nama';
    final priceKey = table == 'jasa_jahit'
        ? 'harga_awal'
        : (table == 'kebaya' ? 'harga_sewa' : null);
    const detailLabels = {
      'jasa_jahit': {
        'deskripsi': 'Deskripsi',
        'estimasi': 'Estimasi pengerjaan',
      },
      'kebaya': {
        'warna': 'Warna',
        'deposit': 'Deposit',
        'lingkar_dada': 'Lingkar dada (cm)',
        'lingkar_pinggang': 'Lingkar pinggang (cm)',
        'panjang_kebaya': 'Panjang kebaya (cm)',
        'panjang_lengan': 'Panjang lengan (cm)',
      },
      'galeri': {'kategori': 'Kategori'},
    };
    final fields = detailLabels[table] ?? const <String, String>{};
    final n = TextEditingController(text: item?[nameKey] ?? '');
    final h = TextEditingController(
      text: priceKey == null || item == null ? '' : '${iv(item[priceKey])}',
    );
    final detailControllers = {
      for (final key in fields.keys)
        key: TextEditingController(text: '${item?[key] ?? ''}'),
    };
    XFile? selectedImage;
    Uint8List? selectedImageBytes;
    bool saving = false;
    final currentImageUrl = catalogImageUrl(item ?? const {});
    Future<void> saveFromDialog(
      BuildContext dialogContext,
      StateSetter setDialogState,
    ) async {
      final name = n.text.trim();
      if (name.isEmpty) {
        snack(dialogContext, 'Nama/judul tidak boleh kosong.');
        return;
      }
      final data = <String, dynamic>{nameKey: name};
      if (priceKey != null) {
        final price = int.tryParse(h.text.trim());
        if (price == null || price <= 0) {
          snack(dialogContext, 'Harga harus berupa angka lebih dari 0.');
          return;
        }
        data[priceKey] = price;
      }
      for (final entry in fields.entries) {
        final value = detailControllers[entry.key]!.text.trim();
        final numeric =
            entry.key == 'deposit' ||
            entry.key.startsWith('lingkar_') ||
            entry.key.startsWith('panjang_');
        if (numeric && value.isNotEmpty) {
          final parsed = num.tryParse(value);
          if (parsed == null || parsed < 0) {
            snack(dialogContext, '${entry.value} harus berupa angka positif.');
            return;
          }
          data[entry.key] = parsed;
        } else {
          data[entry.key] = value;
        }
      }
      if (item == null) data.addAll(catalogCreateDefaults(table));

      setDialogState(() => saving = true);
      try {
        if (selectedImage != null && selectedImageBytes != null) {
          data['image_url'] = await Repo.uploadCatalogImage(
            table,
            selectedImage!.name,
            selectedImageBytes!,
          );
        }
        await Repo.saveCatalog(table, list, data, item);
        if (!mounted || !dialogContext.mounted) return;
        setState(() {});
        Navigator.pop(dialogContext, true);
        snack(
          context,
          Session.userId == null
              ? 'Tersimpan sementara dalam Mode Demo.'
              : 'Katalog berhasil disimpan ke server.',
        );
      } catch (error, stackTrace) {
        debugPrint('Unable to save catalog form: $error\n$stackTrace');
        if (dialogContext.mounted) {
          setDialogState(() => saving = false);
          snack(
            dialogContext,
            'Katalog/gambar gagal disimpan: ${backendErrorText(error)}',
          );
        }
      }
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setDialogState) => AlertDialog(
          title: Text(item == null ? 'Tambah Baru' : 'Edit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  height: 150,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: rose,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: selectedImageBytes != null
                      ? Image.memory(selectedImageBytes!, fit: BoxFit.cover)
                      : currentImageUrl != null
                      ? Image.network(
                          currentImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stackTrace) => const Icon(
                            Icons.broken_image_outlined,
                            size: 42,
                            color: burgundy,
                          ),
                        )
                      : Icon(iconForCategory(table), size: 42, color: burgundy),
                ),
                TextButton.icon(
                  onPressed: () async {
                    try {
                      final image = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                        maxWidth: 1800,
                        maxHeight: 1800,
                      );
                      if (image == null) return;
                      final bytes = await image.readAsBytes();
                      if (bytes.length > maxImageBytes) {
                        if (mounted) {
                          snack(context, 'Ukuran gambar maksimal 5 MB.');
                        }
                        return;
                      }
                      if (imageMimeType(image.name, bytes) == null) {
                        if (mounted) {
                          snack(
                            context,
                            'Gunakan gambar JPEG, PNG, atau WebP.',
                          );
                        }
                        return;
                      }
                      setDialogState(() {
                        selectedImage = image;
                        selectedImageBytes = bytes;
                      });
                    } catch (error, stackTrace) {
                      debugPrint(
                        'Unable to select catalog image: $error\n$stackTrace',
                      );
                      if (mounted) {
                        snack(
                          context,
                          'Tidak dapat membuka gambar dari galeri.',
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(
                    selectedImage == null ? 'Pilih Gambar' : 'Ganti Gambar',
                  ),
                ),
                TextField(
                  controller: n,
                  decoration: const InputDecoration(labelText: 'Nama / judul'),
                ),
                if (priceKey != null) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: h,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: table == 'kebaya'
                          ? 'Harga sewa / hari'
                          : 'Harga awal',
                    ),
                  ),
                ],
                for (final entry in fields.entries) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: detailControllers[entry.key],
                    keyboardType:
                        entry.key == 'deposit' ||
                            entry.key.startsWith('lingkar_') ||
                            entry.key.startsWith('panjang_')
                        ? TextInputType.number
                        : TextInputType.text,
                    decoration: InputDecoration(labelText: entry.value),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () => saveFromDialog(c, setDialogState),
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    n.dispose();
    h.dispose();
    for (final controller in detailControllers.values) {
      controller.dispose();
    }
    if (ok != true) return;
  }

  Widget _list(String table, List<Map<String, dynamic>> list) {
    final nameKey = table == 'galeri' ? 'judul' : 'nama';
    final loadError = Repo.loadErrors[table];
    return Stack(
      children: [
        if (loadingCatalog)
          const Center(child: CircularProgressIndicator())
        else if (list.isEmpty && loadError != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 44),
                  const SizedBox(height: 12),
                  Text(loadError, textAlign: TextAlign.center),
                  TextButton.icon(
                    onPressed: _reloadCatalog,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),
          )
        else
          RefreshIndicator(
            onRefresh: _reloadCatalog,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: list.length + (loadError == null ? 0 : 1),
              separatorBuilder: (_, i) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                if (loadError != null && i == 0) {
                  return nCard(
                    color: AppColors.yellowPastel,
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_outlined),
                        const SizedBox(width: 8),
                        Expanded(child: Text(loadError)),
                        IconButton(
                          tooltip: 'Coba lagi',
                          onPressed: _reloadCatalog,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                  );
                }
                final itemIndex = i - (loadError == null ? 0 : 1);
                final it = list[itemIndex];
                return Pop(
                  i: itemIndex,
                  child: nCard(
                    onTap: () => _form(table, list, it),
                    child: Row(
                      children: [
                        catalogArtwork(it, table, size: 58),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                it[nameKey] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (table == 'jasa_jahit')
                                Text(
                                  '${rp(iv(it['harga_awal']))}'
                                  '${it['aktif'] == false ? ' • Nonaktif' : ''}',
                                ),
                              if (table == 'kebaya')
                                Text(
                                  '${rp(iv(it['harga_sewa']))}/hari • ${it['status']}',
                                ),
                              if (table == 'galeri')
                                Text('${it['kategori'] ?? ''}'),
                            ],
                          ),
                        ),
                        if (table == 'kebaya')
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.swap_horiz_rounded),
                            onSelected: (s) async {
                              try {
                                await Repo.saveCatalog(table, list, {
                                  'status': s,
                                }, it);
                                if (mounted) {
                                  setState(() {});
                                  snack(
                                    context,
                                    Session.userId == null
                                        ? 'Status diperbarui sementara dalam Mode Demo.'
                                        : 'Status kebaya berhasil diperbarui.',
                                  );
                                }
                              } catch (error, stackTrace) {
                                debugPrint(
                                  'Unable to update rental status: $error\n$stackTrace',
                                );
                                if (mounted) {
                                  snack(
                                    context,
                                    'Status kebaya gagal disimpan: ${backendErrorText(error)}',
                                  );
                                }
                              }
                            },
                            itemBuilder: (_) => [
                              for (final s in [
                                'Tersedia',
                                'Dipesan',
                                'Disewa',
                                'Perawatan',
                              ])
                                PopupMenuItem(value: s, child: Text(s)),
                            ],
                          ),
                        if (table == 'jasa_jahit')
                          IconButton(
                            tooltip: it['aktif'] == false
                                ? 'Aktifkan layanan'
                                : 'Nonaktifkan layanan',
                            onPressed: () async {
                              final wasInactive = it['aktif'] == false;
                              try {
                                await Repo.saveCatalog(table, list, {
                                  'aktif': wasInactive,
                                }, it);
                                if (mounted) {
                                  setState(() {});
                                  snack(
                                    context,
                                    wasInactive
                                        ? 'Layanan diaktifkan kembali.'
                                        : 'Layanan dinonaktifkan.',
                                  );
                                }
                              } catch (error, stackTrace) {
                                debugPrint(
                                  'Unable to change service availability: '
                                  '$error\n$stackTrace',
                                );
                                if (mounted) {
                                  snack(
                                    context,
                                    'Status layanan gagal disimpan: '
                                    '${backendErrorText(error)}',
                                  );
                                }
                              }
                            },
                            icon: Icon(
                              it['aktif'] == false
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_rounded,
                            color: Colors.redAccent,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('Hapus item?'),
                                content: Text(
                                  'Hapus "${it[nameKey]}" dari katalog?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text('Batal'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text('Hapus'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm != true) return;
                            try {
                              await Repo.deleteCatalog(table, list, it);
                              if (mounted) {
                                setState(() {});
                                snack(
                                  context,
                                  Session.userId == null
                                      ? 'Item dihapus dari Mode Demo.'
                                      : 'Item berhasil dihapus dari katalog.',
                                );
                              }
                            } catch (error, stackTrace) {
                              debugPrint(
                                'Unable to delete catalog item: $error\n$stackTrace',
                              );
                              if (mounted) {
                                snack(context, 'Item gagal dihapus: $error');
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        Positioned(
          right: 18,
          bottom: 18,
          child: Bouncy(
            onTap: () => _form(table, list),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: burgundy,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                '＋ Tambah',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Katalog'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Muat ulang katalog',
            onPressed: loadingCatalog ? null : _reloadCatalog,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: const TabBar(
          labelColor: burgundy,
          indicatorColor: gold,
          tabs: [
            Tab(text: 'Jasa Jahit'),
            Tab(text: 'Kebaya'),
            Tab(text: 'Galeri'),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          _list('jasa_jahit', Repo.jasa),
          _list('kebaya', Repo.kebaya),
          _list('galeri', Repo.galeri),
        ],
      ),
    ),
  );
}
