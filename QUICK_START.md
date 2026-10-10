# 🚀 QUICK START - NELY Collection APK (PRODUCTION)

**APK File:** `build/app/outputs/flutter-apk/app-release.apk` (53.7 MB)  
**Status:** ✅ READY TO INSTALL & DEPLOY

---

## ⚡ 3-STEP SETUP (15 Menit)

### STEP 1️⃣: Jalankan Migrasi SQL (5 menit)
**Tempat:** [Supabase Dashboard](https://app.supabase.com) → Project NELY Collection → SQL Editor

**Salin & jalankan 3 file ini BERURUTAN:**

**File 1:**
```sql
-- Copy dari: supabase/migrations/202610100935_add_catalog_images.sql
-- Paste ke SQL Editor, jalankan
```

**File 2:**
```sql
-- Copy dari: supabase/migrations/202610101003_fix_admin_crud_policies.sql
-- Paste ke SQL Editor, jalankan
```

**File 3:**
```sql
-- Copy dari: supabase/migrations/202610101611_add_store_payment_methods.sql
-- Paste ke SQL Editor, jalankan
```

✅ **Verifikasi:** Tidak ada error di SQL Editor

---

### STEP 2️⃣: Setup Admin Account (5 menit)

**A. Install APK di Android Phone:**
```bash
# Via Android Studio
flutter install build/app/outputs/flutter-apk/app-release.apk

# Via ADB (jika punya ADB)
adb install build/app/outputs/flutter-apk/app-release.apk
```

**B. Buka aplikasi → Register sebagai Admin:**
- Email: `admin@nelystore.com` (sesuai email pemilik)
- Password: Gunakan password kuat (min 8 char: uppercase, lowercase, number, symbol)
- Nama: `Admin NELY`
- WhatsApp: `628816715599` (nomor toko)
- Confirm Password: Ulangi password yang sama
- Tap **Daftar**

**C. Set Admin Role via SQL Editor:**
```sql
UPDATE public.profiles
SET role = 'admin'
WHERE id = (SELECT id FROM auth.users WHERE email = 'admin@nelystore.com');
```

✅ **Verifikasi:** Baris berubah = 1 row (bukan 0)

---

### STEP 3️⃣: Atur Info Toko (5 menit)

**Di APK (sebagai admin):**
1. Tap profile (kanan bawah)
2. Tap **Edit Info Toko**
3. Isi:
   - ✅ Nama Toko
   - ✅ Alamat
   - ✅ Jam Operasional
   - ✅ Nomor Rekening BRI + Nama Pemilik
   - ✅ Gambar Barcode QRIS (format JPEG/PNG, max 5MB)
4. Tap **Simpan**

✅ **Verifikasi:** Tidak ada error, info tersimpan

---

## 🎯 TESTING CHECKLIST

### ✅ CRUD Katalog Works:
- [ ] Login sebagai admin
- [ ] Tab **Katalog**
- [ ] Tap `+` Tambah layanan baru
- [ ] Isi: nama, harga, deskripsi, pilih gambar
- [ ] Tap **Simpan**
- [ ] Harus tampil di list katalog
- [ ] Edit item → ubah data → Simpan (harus berhasil)
- [ ] Hapus item → konfirmasi → hilang dari list

### ✅ CRUD Pesanan Works:
- [ ] Logout → Login sebagai customer (akun baru)
- [ ] Tap layanan atau menu
- [ ] Buat pesanan baru
- [ ] Pilih metode pembayaran (BRI / Tunai / QRIS)
- [ ] Tap **Lanjut**
- [ ] Pesanan harus tersimpan

### ✅ Admin Dashboard:
- [ ] Login admin
- [ ] Lihat dashboard (statistik pesanan, pendapatan)
- [ ] Tab **Pembayaran** → lihat pesanan pending
- [ ] Tap pesanan → verifikasi/tolak

### ✅ Session Persistence:
- [ ] Login (email + password)
- [ ] Close aplikasi 100%
- [ ] Buka aplikasi lagi
- [ ] Harus langsung masuk (TANPA login lagi)

---

## 🔧 TROUBLESHOOTING

### APK Tidak Bisa Install
```bash
# Uninstall dulu
adb uninstall com.example.nely_collection

# Install ulang
flutter install build/app/outputs/flutter-apk/app-release.apk
```

### Admin Role Tidak Jadi
1. SQL query harus mengembalikan `1 row changed`
2. Jika `0 rows`, profil belum terbuat
3. Solusi: Tunggu 10 detik setelah register, coba SQL lagi
4. atau: Cek di Supabase Dashboard → Authentication → verify email sudah confirmed

### CRUD Tidak Berfungsi
1. Cek: Migrasi SQL sudah dijalankan? (Lihat di SQL Editor history)
2. Cek: Admin role sudah diset? (Query: `SELECT role FROM profiles WHERE email='admin@...'`)
3. Cek: Storage bucket terbuat? (Supabase → Storage → `nely-uploads`)
4. Jika semua OK tapi masih error → screenshot error → kirim ke developer

### Gambar Tidak Tampil
- Format harus JPEG/PNG/WebP
- Ukuran < 5 MB
- Cek di Supabase Storage bucket `nely-uploads`

---

## 📲 DEPLOYMENT

### Untuk Customer:
1. APK tersedia di folder: `build/app/outputs/flutter-apk/app-release.apk`
2. Kirim ke customer via:
   - ✅ Email (attachment)
   - ✅ WhatsApp
   - ✅ Google Drive link
   - ✅ Play Store (kalau mau publish)

### Instruksi Customer:
- Download APK
- Buka File Manager → tap APK → Install
- Jika ada warning "Unknown source" → Tap **Install Anyway**
- Buka aplikasi → Daftar/Login → Order

---

## 📞 CONTACT

WhatsApp: **+62-881-671-5599**

---

**✅ Setup selesai? APK siap dideploy!**

Waktu total: ~15 menit (1× hanya untuk setup pertama)
