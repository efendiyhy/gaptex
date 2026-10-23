# Pemecahan masalah Gaptex

## Pesan `cannot be backed up at this state`

Penyebab: file Spotify telah dimodifikasi / berada pada keadaan yang tidak dapat dibackup CLI. Menutup Spotify saja tidak memperbaikinya. Instal ulang **aplikasi Spotify Desktop**, buka dan login selama sekitar 60 detik, tutup, lalu jalankan ulang installer. Jangan hapus akun/playlist; unduhan offline dapat perlu diunduh lagi.

## Pesan `Please restore first then backup`

Artinya ada backup lama. Untuk pemeriksaan manual di PowerShell:

```powershell
spicetify restore
spicetify backup apply
```

**Peringatan:** `restore` menghapus modifikasi Spicetify yang sedang aktif. Konfigurasi tema/ekstensi biasanya masih tersimpan, tetapi tindakan ini bisa memengaruhi ekstensi lainnya. Installer Gaptex tidak melakukannya otomatis.

## `Spicetify CLI belum ditemukan`

Buka PowerShell baru lalu jalankan `spicetify -v`. Jika tidak terdeteksi, lihat instalasi Spicetify resmi: https://spicetify.app/docs/getting-started .

## Gaptex tidak muncul di menu profil

Jalankan:

```powershell
spicetify config
spicetify apply
```

Pastikan daftar `extensions` mengandung `gaptex.js`. Periksa log DevTools (`Ctrl + Shift + I`) untuk `[Gaptex]`.

## Log berisi informasi sensitif

Sebelum membagikan log, hapus token, nama komputer, direktori pribadi, dan informasi akun.
