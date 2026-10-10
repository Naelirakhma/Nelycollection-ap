# Ringkasan Perbaikan CRUD

Aplikasi dilaporkan belum menyelesaikan operasi CRUD; berikut adalah perbaikan konkret yang dilakukan:

## Masalah yang Ditemukan

1. **Payload Galeri Tidak Lengkap**
   - Kolom `bisa_referensi` ada di tabel Supabase tetapi tidak dikirim saat membuat item galeri baru.
   - Jika kolom NOT NULL tanpa default, insert akan gagal di server.
   - **Perbaikan**: Tambahkan helper `catalogCreateDefaults()` yang menyertakan `bisa_referensi: true` untuk semua item galeri baru.

2. **Profil Admin Gagal Dibaca, Tidak Dilapor**
   - Jika `loadProfile()` gagal membaca baris profil, aplikasi hanya bercetak debug log dan diam-diam menurunkan akun ke `role='customer'`.
   - Admin akan masuk tetapi tidak melihat menu admin, dan operasi CRUD akan ditolak.
   - **Perbaikan**: Lemparkan `StateError` yang jelas saat profil tidak dapat dibaca; saat login, tangkap pesan ini dan tampilkan ke pengguna.

3. **Default Field Tidak Konsisten**
   - Form admin sebelumnya menulis:
     - `jasa_jahit` / `kebaya`: `emoji: ''` (benar), tetapi `aktif: true` hanya saat create (tidak konsisten).
     - `kebaya`: `status: 'Tersedia'` hanya saat create.
   - Kelompokkan semua default ke fungsi `catalogCreateDefaults(table)`.

## Perubahan Kode

### `lib/main.dart`

**Session.loadProfile()**
- Validasi `role` harus `'admin'` atau `'customer'` sebelum diterima.
- Jika baca profil gagal, lemparkan `StateError` dengan pesan eksplisit tentang yang harus diperiksa (baris profil ada? role ada? RLS mengizinkan?).
- `Session.userId` tidak diatur sampai profil berhasil dibaca.

**Session.reset()**
- Sudah ada; tidak berubah.

**Repo.uploadCatalogImage()**
- Tambahkan pemeriksaan ketat: `Session.userId == null`, user login berubah, atau role bukan admin → tolak langsung.

**Repo.saveCatalog()**
- Saat `item == null` (create), panggil `data.addAll(catalogCreateDefaults(table))` untuk menyertakan semua field yang dibutuhkan.

**catalogCreateDefaults(table)**
- Fungsi baru yang mengembalikan:
  - `emoji: ''` untuk semua tabel.
  - `aktif: true` untuk `jasa_jahit` dan `kebaya`.
  - `status: 'Tersedia'` untuk `kebaya`.
  - `bisa_referensi: true` untuk `galeri`.

**AuthPage._submit() & _boot()**
- Tangkap `StateError` dari `Session.loadProfile()` dan `AuthException`.
- Tampilkan pesan error ke pengguna, lalu clear session dan sign out.
- Biarkan pengguna coba login lagi atau gunakan Mode Demo.

### `test/app_logic_test.dart`

- Tambahkan tes `catalogCreateDefaults()` untuk memastikan semua default cocok dengan skema tabel.
- Tes unit tetap lokal; tidak bergantung pada Supabase.

### `README.md`

- Tambahkan instruksi eksplisit untuk mengatur role admin melalui SQL Editor setelah akun terdaftar.
- Lampirkan contoh SQL:
  ```sql
  update public.profiles
  set role = 'admin'
  where id = (
    select id from auth.users where email = 'admin@example.com'
  );
  ```
- Ingatkan pengguna bahwa profil harus terbentuk saat pendaftaran dan CRUD hanya bekerja saat role sudah diatur ke `'admin'`.

## Cara Uji CRUD di Supabase Produksi

1. **Siapkan akun admin** di Supabase:
   - Daftarkan email baru di login form aplikasi (Mode Demo atau Live).
   - Konfirmasi email jika diminta.
   - SQL: Ubah `profiles.role` menjadi `'admin'` untuk user tersebut.

2. **Jalankan migrasi RLS** (jika belum dilakukan):
   - Buka Supabase SQL Editor.
   - Jalankan kedua file di `supabase/migrations/` secara berurutan:
     1. `202610100935_add_catalog_images.sql` (gambar & bucket)
     2. `202610101003_fix_admin_crud_policies.sql` (kebijakan CRUD & role admin)
   - Jika migrasi sudah dijalankan, ulangi tidak perlu tetapi tidak merugikan.

3. **Login dengan akun admin**:
   - Gunakan email dan password yang sudah didaftarkan.
   - Jika login gagal dengan pesan profil, periksa:
     - Baris di `profiles` tabel (SELECT * FROM auth.users WHERE email = '...'`).
     - Nilai `role` di baris profil (harus `'admin'`).
     - RLS policies aktif dan meng-izinkan akun untuk membaca profilnya sendiri.

4. **Uji CRUD operasi**:
   - **Create**: Form admin → **Simpan** → data tampil di katalog pelanggan.
   - **Update**: Edit item → **Simpan** → perubahan terlihat.
   - **Delete**: Hapus item → konfirmasi → hilang dari daftar.
   - Jika gagal, lihat error di aplikasi atau log perangkat (`adb logcat`).

## Catatan Teknis

- **Mode Demo**: Perubahan hanya di memori lokal. Item tidak dapat diedit ke server jika ID dimulai `lokal-` atau `demo-`.
- **Publishable Key**: Hanya untuk autentikasi klien. DDL, RLS, bucket policy tidak dapat diubah dari aplikasi; harus SQL Editor.
- **Error Messages**: Sekarang lebih deskriptif (profil tidak ditemukan, role tidak cocok, dll) untuk memudahkan debug.
- **tes Unit**: 15 tes lulus, termasuk CRUD demo dan validasi default katalog.
- **Analyzer**: Bersih (no issues).

## Build & Deploy

```powershell
# Build dengan key Supabase
flutter build apk --debug --dart-define=SUPABASE_ANON_KEY=sb_publishable_-oq3SNz_r6Ea-QZRr-jSFg_V-FMl-Yk

# Pasang ke perangkat
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# Lihat log
adb logcat | grep 'flutter'
```

APK terbaru: `build/app/outputs/flutter-apk/app-debug.apk`
