# KabarKelas — Demo Web App

Demo aplikasi rapor digital dan manajemen akademik sekolah. Ini situs statis (satu file `index.html`), tanpa build dan tanpa server. **Demo belum terhubung ke Supabase**: semua data demo hidup di browser pengguna dan hilang saat tab ditutup atau dimuat ulang. Folder `supabase/` berisi skema awal untuk versi produksi (lihat bagian 7).

## Isi proyek

```
kabarkelas-demo/
├── index.html        Aplikasi lengkap (HTML + CSS + JavaScript)
├── _headers          Header keamanan dan cache untuk Netlify
├── favicon.svg       Ikon tab browser
├── robots.txt        Meminta mesin pencari tidak mengindeks demo
├── vendor/
│   ├── xlsx.full.min.js     SheetJS 0.18.5 (impor/ekspor Excel)
│   ├── qrcode.js            qrcode-generator 1.4.4 (kartu QR)
│   └── LICENSE-xlsx.txt     Lisensi SheetJS (Apache-2.0)
├── supabase/
│   └── schema.sql    Skema awal + Row Level Security (starter produksi)
├── .gitignore
└── README.md
```

Pustaka Excel dan QR sudah disalin ke `vendor/`, jadi aplikasi tidak bergantung pada CDN pihak ketiga.

---

## 1. Coba di komputer sendiri (opsional)

- Klik dua kali `index.html`, atau
- Di terminal pada folder proyek: `npx serve .` lalu buka alamat yang tampil (lebih aman untuk impor Excel dan kartu QR, karena keduanya memuat file dari `vendor/`).

---

## 2. Persiapan akun

1. Akun **GitHub** dan **GitHub Desktop** (masuk lewat *File → Options → Accounts*).
2. Akun **Netlify** (netlify.com). Cara termudah: *Sign up with GitHub*.
3. (Untuk produksi) Akun **Supabase** (supabase.com).

---

## 3. Unggah ke GitHub memakai GitHub Desktop

1. Ekstrak ZIP. Letakkan folder `kabarkelas-demo` di tempat yang mudah, misalnya `Documents/GitHub/kabarkelas-demo`.
2. GitHub Desktop → **File → Add local repository…** → pilih folder tersebut.
3. Jika muncul *"This directory does not appear to be a Git repository"*, klik **create a repository**, isi Name `kabarkelas-demo`, biarkan Git ignore dan License **None**, lalu **Create repository**.
4. Tab **Changes**: isi Summary `Versi awal demo KabarKelas` → **Commit to main**.
5. Klik **Publish repository**, centang **Keep this code private** (disarankan), lalu **Publish repository**.

---

## 4. Deploy ke Netlify

Ada dua cara. Untuk pemakaian rutin, pilih cara B.

### Cara A — tarik dan lepas (paling cepat, manual)
1. Buka **app.netlify.com/drop**.
2. Tarik folder `kabarkelas-demo` (yang berisi `index.html` di dalamnya) ke halaman itu.
3. Netlify langsung memberi alamat `*.netlify.app`. Pembaruan berikutnya harus diunggah ulang secara manual.

### Cara B — terhubung ke GitHub (otomatis tiap push)
1. Netlify → **Add new project** (atau *Add new site*) → **Import an existing project**.
2. Pilih **GitHub**, izinkan akses, lalu pilih repositori `kabarkelas-demo`.
   - Jika repositori tidak muncul, ubah izin aplikasi Netlify di GitHub (pilih repositori yang boleh diakses).
3. Pada konfigurasi build:
   - **Branch to deploy:** `main`
   - **Build command:** **kosongkan**
   - **Publish directory:** **kosongkan** (file ada di akar repositori)
4. Klik **Deploy**. Beberapa saat kemudian Anda mendapat alamat `*.netlify.app`.

### Alur pembaruan berikutnya (Cara B)
1. Ubah `index.html` (atau file lain).
2. GitHub Desktop: tulis Summary → **Commit to main** → **Push origin**.
3. Netlify otomatis membuat deploy baru (tab **Deploys**).

### Uji perubahan sebelum tayang
- GitHub Desktop → **Current Branch → New Branch** (misalnya `perbaikan-pengumuman`) → commit → push → buat Pull Request di GitHub.
- Netlify membuat **Deploy Preview** dengan alamat sendiri. Setelah sesuai, gabungkan ke `main`.
- Hemat kuota: setiap deploy produksi memakai kredit di paket gratis (lihat bagian 6), sedangkan deploy preview tidak. Kumpulkan beberapa perubahan sebelum menggabungkan ke `main`.

### Membatalkan deploy yang bermasalah
Netlify → **Deploys** → pilih deploy lama yang bagus → **Publish deploy**.

---

## 5. Domain sendiri (misalnya demo.desainindongmas.my.id)

1. Netlify → site Anda → **Domain management → Add a domain** → masukkan subdomain, misalnya `kabarkelas.desainindongmas.my.id`.
2. Ikuti instruksi DNS yang ditampilkan Netlify. Untuk subdomain biasanya berupa record **CNAME** ke alamat `*.netlify.app` situs Anda. Gunakan nilai persis yang ditampilkan di dashboard.
3. Tambahkan record itu di panel DNS tempat domain dikelola, tunggu propagasi (beberapa menit sampai beberapa jam).
4. Aktifkan HTTPS di Netlify (sertifikat otomatis setelah domain terverifikasi).

---

## 6. Paket Netlify dan batas gratis

Informasi di bawah berasal dari ringkasan pihak ketiga yang mengutip dokumentasi Netlify per pertengahan 2026. **Cek dashboard Netlify Anda untuk angka yang berlaku.**

- Paket gratis memakai sistem **kredit**: 300 kredit per bulan, dan batasnya keras. Jika kredit habis, situs dijeda sampai bulan berikutnya.
- Perkiraan biaya kredit: satu deploy produksi 15 kredit, transfer data 20 kredit per GB. Deploy Preview dan branch deploy tidak memakai kredit.
- Untuk demo ini (halaman sekitar 190 KB, pustaka Excel dan QR hanya dimuat saat dipakai), kuota gratis cukup untuk banyak kunjungan, tetapi jangan terlalu sering deploy ke produksi.
- Penggunaan komersial: sumber pihak ketiga menyebut paket gratis Netlify membolehkan penggunaan komersial, berbeda dengan paket Hobby Vercel. Konfirmasi di ketentuan resmi Netlify sebelum dipakai untuk menjual layanan.
- Perlindungan kata sandi untuk situs adalah fitur paket berbayar. Jika demo hanya untuk calon klien tertentu, pertimbangkan itu atau bagikan alamat yang tidak mudah ditebak.

---

## 7. Menyambungkan Supabase (rencana produksi)

Demo ini sengaja statis. Untuk produk yang dipakai sekolah sungguhan, Supabase dapat menjadi backend: database Postgres, login, dan penyimpanan file.

### Langkah awal
1. Supabase → **New project**. Pilih region terdekat (misalnya Singapura) untuk latensi lebih baik.
2. Buat project **DEV** lebih dulu. Jalankan `supabase/schema.sql` di **SQL Editor**.
3. Uji dengan beberapa akun berbeda peran (admin, guru, orang tua, security) untuk memastikan aturan akses bekerja sebelum menyentuh data nyata.

### Aturan kunci API (penting)
- **Publishable key** (`sb_publishable_...`, di proyek lama disebut anon key): boleh ditaruh di kode browser. Aman **hanya jika** Row Level Security aktif dan benar di semua tabel yang terbuka. `schema.sql` sudah mengaktifkannya.
- **Secret key** (`sb_secret_...`, di proyek lama `service_role`): melewati semua aturan RLS. **Jangan pernah** ditaruh di browser, di repositori GitHub, atau di `index.html`.
- Letakkan secret key hanya di server: **Netlify Functions** (isi lewat *Site configuration → Environment variables*) atau Supabase Edge Functions.
- Rotasi kunci segera di **Settings → API Keys** jika pernah bocor.

### Yang perlu disesuaikan saat Supabase dipakai
- **CSP di `_headers`:** tambahkan alamat project pada `connect-src`, misalnya `connect-src 'self' https://<project-ref>.supabase.co wss://<project-ref>.supabase.co`.
- **Login:** gunakan Supabase Auth; peran tiap akun disimpan di tabel `profiles`.
- **Foto dan lampiran:** simpan di bucket Storage **privat** dengan kebijakan per sekolah dan peran. Kompres foto sebelum diunggah.
- **Verifikasi QR dan notifikasi penting:** dilakukan di server (Edge Function atau Netlify Function), bukan hanya di browser.
- **Kebijakan privasi dan jejak audit:** wajib untuk data siswa (UU Pelindungan Data Pribadi).
- Cek batas paket gratis Supabase (misalnya kebijakan jeda proyek yang tidak aktif) sebelum dipakai di produksi.

`supabase/schema.sql` adalah titik awal, bukan produk jadi. Tinjau ulang kebijakan RLS-nya bersama kebutuhan nyata sekolah sebelum dipakai.

---

## 8. Keamanan dan privasi demo

- Tidak ada server atau database di demo. Data siswa, foto, lampiran, dan file Excel yang diunggah hanya diproses di browser pengguna dan **tidak dikirim ke server mana pun**.
- Jangan memakai **data siswa nyata** untuk demo ke calon klien.
- `robots.txt` dan header `X-Robots-Tag` meminta mesin pencari tidak mengindeks demo. Ini bukan pengaman akses.
- `_headers` memasang header keamanan (CSP, anti-iframe, nosniff, dll.). Jika suatu fitur berhenti jalan setelah deploy, buka Console browser (F12). Pesan yang menyebut *Content Security Policy* berarti aturan di `_headers` perlu dilonggarkan.

---

## 9. Pemecahan masalah

| Gejala | Penyebab umum | Solusi |
|---|---|---|
| GitHub Desktop tidak menampilkan perubahan | Folder yang dipilih salah | Pastikan repositori menunjuk ke folder yang berisi `index.html` |
| Netlify gagal build atau halaman kosong | Build command atau Publish directory terisi | Kosongkan keduanya; pastikan `index.html` ada di akar repositori |
| Header keamanan tidak terpasang | `_headers` tidak ikut ter-commit atau salah folder | Pastikan `_headers` berada di akar repositori, sejajar dengan `index.html` |
| Situs menampilkan "Site not available" | Kredit paket gratis habis | Tunggu bulan berikutnya atau naikkan paket |
| Setelah update tampilan masih lama | Cache browser | Muat ulang paksa: Ctrl+Shift+R (Windows) atau Cmd+Shift+R (Mac) |
| Unduh Excel tidak berjalan | `vendor/xlsx.full.min.js` tidak ikut ter-deploy | Pastikan folder `vendor/` ada di GitHub dan ikut ter-deploy |
| Kartu QR tampil sebagai gambar contoh | `vendor/qrcode.js` tidak termuat | Periksa file itu di GitHub dan tab Network di browser |
| Impor foto atau Excel gagal | File terlalu besar atau format salah | Foto maksimal 5 MB, lampiran 3 MB; format .xlsx, .xls, atau .csv |

---

## Lisensi pihak ketiga

- SheetJS (`vendor/xlsx.full.min.js`): Apache-2.0, lihat `vendor/LICENSE-xlsx.txt`.
- qrcode-generator (`vendor/qrcode.js`): MIT. Hak cipta Kazuhiko Arase; salinan lisensi tercantum di kepala file.
