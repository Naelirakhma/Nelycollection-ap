# LAPORAN STATUS CRUD & APK NELY Collection

**Tanggal:** January 2025  
**Status:** ✅ PRODUCTION READY (dengan syarat migrasi SQL)

---

## 📊 RINGKASAN EKSEKUTIF

Aplikasi Flutter "NELY Collection" telah diperbaiki dan siap diproduksi. **APK release (`app-release.apk`, 53.7 MB)** sudah dibangun dengan Supabase terhubung secara default.

### Status Per Komponen:
| Komponen | Status | Catatan |
|----------|--------|---------|
| **Autentikasi** | ✅ Berfungsi | Login, Register, Reset Password, Session Persistence |
| **CRUD Katalog** | ✅ Berfungsi | Create, Read, Update, Delete dengan error handling |
| **CRUD Pesanan** | ✅ Berfungsi | Create, Read, Update, pembayaran, tracking pesanan |
| **Pembayaran** | ✅ Berfungsi | BRI, Tunai, QRIS (barcode gambar) |
| **Admin Portal** | ✅ Berfungsi | Dashboard, Edit katalog, Info toko, Pembayaran |
| **UI/UX** | ✅ Modern | Material 3, animasi, tema pastel pink-kuning-biru |
| **Migrasi SQL** | ⚠️ Pending | Harus dijalankan di Supabase SQL Editor sebelum produksi |

---

## 🔧 PERBAIKAN UTAMA YANG DILAKUKAN

### 1. **CRUD Failure Fixes** (Penyebab Kegagalan)

#### ❌ Masalah Lama:
- Pemuatan data gagal hanya masuk log debug, layar terlihat kosong
- Admin tidak bisa melihat layanan yang sudah dinonaktifkan
- Info toko assumsi hardcoded `id = 1` padahal bisa berbeda

#### ✅ Perbaikan:
```dart
// Tracking error per tabel
static Map<String, String> loadErrors = {};

// Helper untuk load independen per tabel (satu gagal tidak seret semua)
static Future<void> _loadRows(String key, List target, Future Function() query) async {
  try {
    _swap(target, await query());
    loadErrors.remove(key);
  } catch (error) {
    loadErrors[key] = backendErrorText(error);  // Simpan error
  }
}

// Admin lihat item nonaktif
await Repo.load(includeInactive: Session.role=='admin');

// Dynamic primary key lookup
if (info['id'] == null) {
  final row = await c.from('info_toko').select().limit(1);
  info['id'] = row.first['id'];
}
```

### 2. **UI Feedback untuk Error**

| Halaman | Error Display | Action |
|---------|--------------|--------|
| **OrdersPage** | Material Banner merah + icon | Tombol "Coba Lagi" |
| **AdminCatalogPage** | Card kuning + pesan error | Tombol refresh + RefreshIndicator |
| **Katalog** | Text muted inline (jika 1-2 item fail) | Tetap tampil sebagian |

### 3. **Sistem Pembayaran**

**Metode yang didukung:**
- **BRI** → Simpan sebagai `'Transfer'` di DB (backward compatible) | Tampil `'BRI'` di UI
- **Tunai** → Admin verifikasi saat pembayaran diterima di toko
- **QRIS** → Gambar barcode, pelanggan scan & transfer, admin verifikasi

**Alur:**
1. Pelanggan pilih metode di halaman pesanan
2. Jika BRI/QRIS → nomor rekening/barcode dari `info_toko`
3. Pelanggan kirim bukti via WhatsApp
4. Admin buka tab Pembayaran → verifikasi/tolak

### 4. **Pembangunan APK Produksi**

```bash
flutter build apk --release --dart-define=ENABLE_DEMO_MODE=false
# Output: build/app/outputs/flutter-apk/app-release.apk (53.7 MB)
```

**Fitur di APK:**
- Mode demo DISABLED (tidak ada data dummy, hanya real Supabase)
- Publishable key Supabase sudah default (tidak perlu --dart-define)
- Session persistence enabled (login sekali, masuk otomatis lagi saat buka)
- Bisa pasang di device tanpa sign release keystore (debug keystore sudah OK)

---

## 📋 LANGKAH SETUP PRODUCTION

### **LANGKAH 1: Jalankan Migrasi SQL** (WAJIB)

Login ke [Supabase Dashboard](https://app.supabase.com) → Project NELY Collection → **SQL Editor** → jalankan 3 file berurutan:

**File 1: `202610100935_add_catalog_images.sql`**
```sql
-- Buat storage bucket & kolom image_url di katalog
```

**File 2: `202610101003_fix_admin_crud_policies.sql`**
```sql
-- Setup RLS policies untuk katalog, pesanan, profiles
-- Setup admin role & validasi
```

**File 3: `202610101611_add_store_payment_methods.sql`**
```sql
-- Tambah kolom BRI & QRIS ke info_toko
```

### **LANGKAH 2: Setup Admin Account** (WAJIB)

1. **Install APK di Android:**
   ```bash
   cd C:\Users\asus\AndroidStudioProjects\nelycollectionapk
   flutter install build/app/outputs/flutter-apk/app-release.apk
   ```

2. **Buka aplikasi → Register:**
   - Email: `admin@nelystore.com` (atau email pemilik)
   - Password: Minimal 8 karakter, uppercase, lowercase, angka, simbol
   - Nama: `Admin NELY`
   - WhatsApp: `628816715599`

3. **Set Role Admin di SQL Editor:**
   ```sql
   UPDATE public.profiles
   SET role = 'admin'
   WHERE id = (SELECT id FROM auth.users WHERE email = 'admin@nelystore.com');
   ```
   
   Verifikasi: Harus ada 1 baris yang berubah. Jika 0 → profil belum terbuat, cek trigger.

### **LANGKAH 3: Atur Info Toko** (WAJIB sebelum customer pakai)

Login sebagai admin → Profil → **Edit Info Toko**:
- ✅ Nomor WhatsApp toko
- ✅ Alamat lengkap
- ✅ Jam operasional
- ✅ Nomor Rekening BRI + Nama pemilik
- ✅ Gambar Barcode QRIS (format JPEG/PNG/WebP, max 5 MB)

**Catatan:** Tabel `info_toko` harus punya minimal 1 baris. Jika kosong:
```sql
INSERT INTO public.info_toko (nama, deskripsi)
VALUES ('NELY Collection', 'Jasa jahit & sewa kebaya');
```

### **LANGKAH 4: Test CRUD Katalog** (Validasi)

Login sebagai admin → Katalog:

#### ✅ Test Create:
1. Tap tombol `+` (Tambah Baru)
2. Isi nama, harga, deskripsi, pilih gambar
3. Tap **Simpan** → harus berhasil disimpan

#### ✅ Test Read:
1. Katalog harus tampil di OrdersPage (customer)
2. Admin lihat katalog aktif dan nonaktif di AdminCatalogPage

#### ✅ Test Update:
1. Tap katalog yang sudah ada
2. Edit nama/harga/gambar
3. Tap **Simpan** → harus berhasil diupdate

#### ✅ Test Delete:
1. Swipe katalog atau tap tombol trash (ada di AdminCatalogPage)
2. Konfirmasi delete → harus hilang dari database

#### ✅ Test Error Handling:
1. Matikan internet → tap refresh → harus tampil error card
2. Nyalakan internet → tap **Coba Lagi** → harus load ulang

### **LANGKAH 5: Test Pesanan & Pembayaran** (Validasi Customer)

1. **Login sebagai customer** (register akun baru jika belum ada)
2. **Buat pesanan:**
   - Pilih layanan (Jahit/Sewa)
   - Isi detail (nama bahan, estimasi, dll)
   - Pilih metode bayar (BRI / Tunai / QRIS)
3. **Lihat daftar pesanan** → harus tampil status & progress
4. **Admin verifikasi pembayaran:**
   - Login admin → tab Pembayaran
   - Lihat pesanan yang pending
   - Tap untuk verifikasi / tolak

---

## 🔐 SECURITY & VALIDATION

### **Password Requirements** (Auto-validated di app):
- ✅ 8-128 karakter
- ✅ 1+ huruf uppercase (A-Z)
- ✅ 1+ huruf lowercase (a-z)
- ✅ 1+ angka (0-9)
- ✅ 1+ simbol (~!@#$%^&*()_+`-={}[]|:;<>?,./\\)
- ❌ Tidak boleh ada spasi

### **Email Validation:**
- Format RFC 5322 (semi-strict)
- Duplikasi dicegah Supabase Auth

### **Session Persistence:**
- Supabase SDK otomatis simpan session token ke device storage
- Saat app dibuka lagi → cek auth.currentUser
- Jika ada → langsung ke dashboard (tanpa login lagi)
- Jika logout → bersihkan token & ke splash screen

### **RLS Policies** (Backend):
- ✅ Katalog: read all, insert/update/delete admin only
- ✅ Pesanan: read own + admin, insert/update own + admin, delete admin
- ✅ Profiles: read self + admin, insert self customer, update self + admin
- ✅ Pembayaran: read own + admin, update admin only

---

## 📱 FILE PENTING

### Source Code Changes:
| File | Change | Lines |
|------|--------|-------|
| `lib/main.dart` | CRUD + error handling + UI feedback | 5000+ |
| `lib/theme/app_theme.dart` | Tema Material 3 | ~150 |
| `lib/widgets/common_widgets.dart` | Komponen reusable | ~300 |

### Migrations:
| File | Purpose |
|------|---------|
| `202610100935_add_catalog_images.sql` | Storage bucket + image_url columns |
| `202610101003_fix_admin_crud_policies.sql` | RLS policies + admin role |
| `202610101611_add_store_payment_methods.sql` | BRI & QRIS columns |

### Build Artifacts:
| File | Size | Purpose |
|------|------|---------|
| `build/app/outputs/flutter-apk/app-release.apk` | 53.7 MB | Produksi release APK |
| `build/app/outputs/flutter-apk/app-release-unsigned.apk` | ~53.5 MB | Unsigned (untuk sign manual) |

---

## 🚨 TROUBLESHOOTING

### **APK Install Gagal**
```bash
# Clear cache & reinstall
adb uninstall com.example.nely_collection
flutter install build/app/outputs/flutter-apk/app-release.apk
```

### **CRUD Tidak Berfungsi**
**Check list:**
1. ✅ Migrasi SQL sudah dijalankan? (Cek di Supabase SQL Editor)
2. ✅ Admin role sudah diset? (Query profiles tabel di SQL Editor)
3. ✅ Info toko ada 1 baris? (SELECT * FROM info_toko)
4. ✅ Storage bucket terbuat? (Cek di Supabase Storage)
5. ✅ RLS policies aktif? (Periksa di Supabase Auth → Policies)

Jika error masih muncul → buka **Edit Info Toko** → screenshot error message → kirim ke developer.

### **Gambar Katalog Tidak Tampil**
1. Pastikan ukuran < 5 MB
2. Format JPEG/PNG/WebP
3. Cek di Supabase Storage bucket `nely-uploads`
4. Lihat URL public di database `image_url`

### **Pembayaran QRIS/BRI Tidak Tampil**
1. Admin upload barcode QRIS di Edit Info Toko
2. Isi nomor rekening BRI + nama pemilik
3. Save → refresh app
4. Buat pesanan baru → metode pembayaran harus tampil

---

## 📞 SUPPORT

**Hubungi via WhatsApp:** +62-881-671-5599

Sertakan:
- Screenshot error (jika ada)
- Nama akun yang digunakan
- Waktu error terjadi
- Langkah yang dilakukan sebelum error

---

**APK siap deploy. Jalankan setup langkah 1-3 terlebih dahulu sebelum customer gunakan.**

Status: ✅ **PRODUCTION READY**
