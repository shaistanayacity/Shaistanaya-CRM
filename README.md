# Shaistanaya CRM

Log lead & CS untuk tim digital marketing Shaistanaya: catat lead yang masuk dari Instagram, Facebook, Website, dan WhatsApp, pantau waktu respon (target 15 menit), dan gerakkan lead lewat tahap **Masuk → Direspon → Follow Up → Janjian (Survey) → Deal**.

## Fitur

- **Dashboard** — total lead, % sudah direspon, jumlah survey, rata-rata waktu respon, tren harian/mingguan, distribusi sumber, conversion rate per sumber, unit paling diminati, sebaran domisili, dan alur (funnel) lead.
- **Semua Lead** — filter per sumber, tahap (termasuk "Prospek Aktif" dan "Butuh Follow Up ≥2 hari"), minat, rentang tanggal, dan pencarian nama/no. telp. Export CSV.
- **Input Lead** — form lead baru + daftar lead yang masuk hari ini.
- **Playbook** — strategi, contoh script pembuka, dan hal yang harus dihindari di tiap tahap, plus catatan "Fokus Jual" per unit (Cluster Sierra & Montana) yang otomatis tampil di detail lead.
- Klik baris lead untuk ubah tahap, lihat strategi, dan tambah catatan follow up.

## Menjalankan

Aplikasinya berupa satu halaman statis (`index.html` + `config.js`), tanpa build step.

```bash
npx serve .        # atau: python3 -m http.server
```

Tanpa konfigurasi, aplikasi berjalan di **mode lokal**: data disimpan di `localStorage` browser, cocok untuk mencoba.

## Menyambungkan ke Supabase (data dipakai bersama satu tim)

1. Buat project di [Supabase](https://supabase.com).
2. Buka **SQL Editor**, jalankan isi `supabase/schema.sql`.
3. Di **Authentication → Users**, tambahkan akun email + password untuk tiap anggota tim CS. (Matikan pendaftaran publik di **Authentication → Sign In / Providers** supaya hanya akun yang kamu buat yang bisa masuk.)
4. Salin **Project URL** dan **anon/publishable key** dari **Project Settings → API** ke `config.js`.

Setelah itu aplikasi akan menampilkan halaman login, dan semua anggota tim melihat data lead yang sama. Tabel dilindungi Row Level Security: hanya user yang sudah login yang bisa membaca atau menulis.

## Deploy

Karena statis, bisa langsung di-deploy ke Vercel, Netlify, atau GitHub Pages dari root repo ini.
