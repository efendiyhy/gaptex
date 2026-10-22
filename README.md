# Gaptex

**Musik lebih nyaman. Shuffle lebih terkendali.**

**Gaptex** adalah ekstensi ringan untuk **Spotify Desktop** yang membantu menghadirkan pengalaman mendengarkan musik lebih nyaman melalui dua fitur utama: **AdBlock** dan **Anti-Reshuffle**. Gaptex dirancang sederhana, tanpa akun tambahan, tanpa langganan, dan tanpa konfigurasi yang rumit.

> **Versi:** 0.1.0 (prototipe) · **Platform utama:** Windows · **Lisensi:** MIT
>
> Gaptex masih dalam tahap pengujian. Efektivitas fitur dapat berbeda tergantung versi Spotify. Gaptex tidak memberikan akses Premium dan tidak menjamin semua iklan audio dapat diblokir.

## Fitur

| Fitur | Manfaat | Perlu diketahui |
|---|---|---|
| **AdBlock** | Berupaya mengurangi gangguan iklan dan menyembunyikan elemen iklan pada tampilan Spotify. | Penyaringan bersifat *best effort*. Sebagian iklan, khususnya iklan audio, mungkin tetap muncul. |
| **Anti-Reshuffle** | Mempertahankan pilihan mode shuffle **ON** atau **OFF** ketika statusnya berubah. | Mengunci tombol shuffle **bukan** berarti mengunci urutan playlist atau antrean lagu yang dikendalikan Spotify. |

### Keunggulan Gaptex

- **Ringan:** fitur inti berada dalam satu file ekstensi, `gaptex.js`.
- **Praktis:** pemasangan melalui installer PowerShell untuk Windows.
- **Tanpa akun baru:** gunakan akun Spotify Anda seperti biasa.
- **Privasi:** pengaturan Gaptex tersimpan secara lokal; ekstensi ini tidak mengirim telemetri ke server Gaptex.
- **Open source:** source code tersedia untuk dipelajari dan dikembangkan.

## Cara install di Windows

**Yang diperlukan:** Windows, Spotify Desktop yang sudah terpasang, dan koneksi internet jika komputer perlu mengunduh komponen pendukung saat pemasangan pertama.

1. **Pasang Spotify Desktop**, lalu buka dan login terlebih dahulu (untuk instalasi baru, biarkan terbuka sekitar satu menit). Setelah itu, tutup Spotify.
2. **Unduh Gaptex** dari halaman [GitHub Releases](https://github.com/efendiyhy/gaptex/releases) jika rilis sudah diterbitkan. Alternatifnya, pada halaman repository pilih **Code → Download ZIP**.
3. **Ekstrak ZIP**. Masuk ke folder yang berisi `install.ps1` dan `gaptex.js`.
4. **Buka PowerShell** di folder tersebut: klik kanan area kosong folder lalu pilih **Open in Terminal**.
5. **Jalankan installer:**

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
   ```

6. Jika komponen pendukung belum ada, installer akan **meminta persetujuan Anda** untuk memasangnya melalui Windows Package Manager. Ikuti petunjuk yang tampil.
7. Setelah proses selesai, **buka kembali Spotify Desktop**. Klik **menu profil** untuk mengakses pengaturan Gaptex.

> **Catatan instalasi:** Gaptex menggunakan komponen integrasi desktop pihak ketiga yang diperlukan agar ekstensi dapat berjalan di Spotify. Komponen itu **bukan** bagian dari file `gaptex.js`; installer Windows akan memeriksa dan menawarkan pemasangannya jika belum tersedia. Installer dapat membutuhkan koneksi internet pada tahap tersebut, dan prosesnya belum diuji di semua konfigurasi Windows. Periksa isi `install.ps1` sebelum menjalankannya.

**Tidak perlu memasang Node.js atau Git** untuk menggunakan Gaptex.

## Cara menggunakan

Setelah Gaptex aktif, buka menu profil Spotify Desktop dan pilih:

- **Gaptex · AdBlock:** aktifkan/nonaktifkan upaya penyaringan iklan.
- **Gaptex · Anti-Reshuffle:** aktifkan/nonaktifkan penguncian status shuffle.
- **Gaptex · Shuffle yang dikunci: OFF/ON:** pilih apakah shuffle harus dipertahankan dalam keadaan mati atau menyala. Nilai awalnya **OFF**.

Pengaturan akan disimpan secara lokal. Sebagian perubahan mungkin memerlukan restart Spotify.

## Cara update

Unduh versi terbaru, ekstrak, lalu jalankan kembali `install.ps1`. Installer mengganti file ekstensi sebelumnya dan menerapkan konfigurasi terbaru. Tidak perlu menghapus versi lama terlebih dahulu.

## Cara uninstall

Buka PowerShell pada folder Gaptex dan jalankan:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\uninstall.ps1
```

Skrip menghapus ekstensi Gaptex dari konfigurasi Spotify Desktop dan menghapus file ekstensi lokalnya. **Komponen pendukung pihak ketiga tidak ikut dihapus**, karena mungkin digunakan ekstensi lain.

## Tanya jawab

**Apakah Gaptex gratis?**  
Ya. Gaptex merupakan proyek open-source dengan lisensi MIT.

**Apakah Gaptex mengaktifkan Spotify Premium?**  
Tidak. Gaptex tidak mengubah status langganan atau hak akses akun Anda.

**Apakah semua iklan pasti hilang?**  
Tidak. AdBlock beroperasi dengan pendekatan *best effort* dan mungkin tidak berfungsi pada semua versi Spotify.

**Apakah Anti-Reshuffle membuat antrean lagu tidak pernah berubah?**  
Tidak. Fitur ini mempertahankan **status shuffle ON/OFF**, bukan menyimpan atau memaksakan urutan antrean lagu tertentu.

**Mengapa Gaptex tidak muncul?**  
Pastikan installer selesai tanpa error, tutup lalu buka ulang Spotify, dan coba jalankan installer lagi. Jika instalasi komponen pendukung gagal, periksa apakah `winget` tersedia di PowerShell dan koneksi internet aktif.

**Mengapa installer gagal saat pemasangan pertama?**  
Pastikan Spotify Desktop sudah pernah dibuka dan Anda sudah login. Pada beberapa sistem, pembaruan Spotify atau perubahan API aplikasi dapat menyebabkan kegagalan kompatibilitas.

## Untuk pengembang

Kode sumber berada di [github.com/efendiyhy/gaptex](https://github.com/efendiyhy/gaptex). Pengujian kode lokal (opsional) memerlukan Node.js 18+:

```bash
npm run check
npm test
```

## Lisensi dan disclaimer

Gaptex didistribusikan dengan **[MIT License](LICENSE)** dan merupakan proyek independen yang **tidak berafiliasi dengan Spotify**. Spotify adalah merek dagang milik pemiliknya masing-masing. Penggunaan ekstensi sepenuhnya menjadi tanggung jawab pengguna dan harus mematuhi ketentuan layanan yang berlaku.

Untuk rincian arsitektur dan batasan implementasi, lihat [catatan teknis](docs/IMPLEMENTATION.md).
