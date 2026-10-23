# GAPTEX

**Gaptex** adalah ekstensi untuk Spotify Desktop di Windows, dengan fitur **Anti-Reshuffle** dan **AdBlock eksperimental**.

**Versi:** 0.3.0 · Windows 10/11 · Prototipe

## Instalasi Windows

1. Instal Spotify Desktop dari [website resminya](https://www.spotify.com/download/windows/) (bukan Microsoft Store). Buka, login, dan biarkan sekitar 60 detik.
2. Buka **Windows PowerShell** biasa (tanpa Administrator).
3. Tempel perintah ini, lalu tekan **Enter**:

```powershell
irm https://raw.githubusercontent.com/efendiyhy/gaptex/main/install-online.ps1 | iex
```

4. Ikuti petunjuk yang ditampilkan. Jika selesai, buka Spotify dan klik **foto profil kanan atas → Gaptex**.

Jika PowerShell memblokir menjalankan skrip, Anda boleh menjalankan ini **hanya pada sesi PowerShell saat itu**, lalu ulangi perintah pemasangan:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
```

**Catatan:** Pemasangan menggunakan **Spicetify CLI resmi** sebagai komponen integrasi. Kode dan lisensinya tetap milik proyek tersebut; baca [pemberitahuan pihak ketiga](docs/THIRD_PARTY_NOTICES.md). Installer akan mengunduhnya dari situs resmi jika belum ada dan memeriksa pembaruan saat sudah terpasang. Tidak perlu Node.js atau Git.

## Fitur

| Fitur | Keterangan |
| --- | --- |
| **Anti-Reshuffle** | Mempertahankan status tombol shuffle sesuai pilihan ON/OFF. Tidak menjamin urutan antrean server. |
| **AdBlock (eksperimental)** | Menyembunyikan sejumlah elemen iklan dan mencoba menonaktifkan pengelola iklan yang tersedia. Tidak menjamin iklan audio hilang. |

## Jika instalasi gagal

Jika muncul pesan `Spotify cannot be backed up at this state`, instalasi Spotify dalam keadaan yang tidak bisa dibackup. **Jangan terus mengulangi perintah.** Uninstall aplikasi Spotify melalui Windows Settings, pasang ulang dari website resmi, buka dan login sekitar 60 detik, kemudian ulangi pemasangan Gaptex. File/playlist akun tidak dihapus, tetapi unduhan offline mungkin perlu diunduh lagi.

Untuk diagnosis:

```powershell
Get-Content "$env:LOCALAPPDATA\Gaptex\logs\install.log" -Tail 40
```

Petunjuk lanjut: [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

## Uninstall

Dari folder source ZIP:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\uninstall.ps1
```

## Pengembangan

```bash
npm test
```

Pengujian JavaScript dapat dilakukan tanpa akun Spotify, tetapi keberhasilan aktivasi tetap harus diuji di Windows dengan Spotify Desktop yang sesuai.

## Lisensi

Kode Gaptex: MIT. Gaptex tidak terafiliasi dengan Spotify atau Spicetify. Harap perhatikan ketentuan layanan Spotify dan atribusi pihak ketiga.
