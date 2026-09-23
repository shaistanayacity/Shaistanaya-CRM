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


## Database (Supabase)

Aplikasi sudah tersambung ke project Supabase **Shaistanaya City CRM** (`config.js`), dan skema dari `supabase/schema.sql` sudah dijalankan di sana.

Menambah anggota tim CS:

1. **Authentication → Users → Add user**: buat akun dengan email + password.
2. **SQL Editor**: daftarkan emailnya sebagai anggota tim:
   ```sql
   insert into public.team_members (email) values ('nama@contoh.com');
   ```

Hanya email yang ada di `team_members` yang bisa membaca atau mengubah data lead (dijaga Row Level Security). Menghapus akses: `delete from public.team_members where email = 'nama@contoh.com';`

Disarankan juga mematikan pendaftaran publik di **Authentication → Sign In / Providers → Allow new users to sign up**.

Kalau `config.js` dikosongkan, aplikasi jalan dalam mode lokal (data di browser saja).

## Deploy

Karena statis, bisa langsung di-deploy ke Vercel, Netlify, atau GitHub Pages dari root repo ini.
