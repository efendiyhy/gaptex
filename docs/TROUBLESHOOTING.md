# Gaptex – diagnosis instalasi

## Lokasi log

`%LOCALAPPDATA%\Gaptex\logs\install.log`

```powershell
Get-Content "$env:LOCALAPPDATA\Gaptex\logs\install.log" -Tail 60
```

## Prinsip pemulihan

- Installer menutup proses Spotify sebelum mengubah file aplikasinya.
- Instalasi baru mempersiapkan backup, sedangkan instalasi yang sudah ada mencoba `apply` dahulu.
- Backup yang tidak sinkron ditangani hanya setelah konfirmasi eksplisit. Memulihkan backup dapat mengganti modifikasi Spotify dari pihak lain.
- Jika versi Spotify tidak didukung, installer tidak mengklaim sukses atau melakukan pemulihan berulang.
- Jangan hapus folder konfigurasi dan backup secara manual sebagai langkah pertama.

## Makna pesan

| Pesan | Tindakan |
|---|---|
| `Spotify version mismatch` | Periksa dukungan versi Spotify dan pembaruan runtime; tidak selalu dapat diperbaiki otomatis. |
| `You haven't backed up` | Installer mencoba menyiapkan backup awal. |
| `Preprocessed Spotify data is outdated` | Installer meminta izin pemulihan backup dan apply ulang. |
| `After clearing backup, Spotify cannot be backed up again` | Backup baru tidak dapat dibuat sebelum memulihkan Spotify ke kondisi semula. |
| `Cannot find prefs` | Pastikan Spotify Desktop pernah dibuka dan Anda sudah login. Periksa jenis instalasi Spotify. |
| `Access denied` | Periksa izin direktori Spotify. Jangan langsung menjalankan semua perintah sebagai administrator tanpa diagnosis. |

CLI dokumentasi: <https://spicetify.app/docs/cli/commands> dan <https://spicetify.app/docs/faq>.

## Mengirim laporan bug

Sertakan versi Windows, versi Spotify, status apakah Spotify diinstal dari Microsoft Store atau installer web, versi komponen integrasi, dan 30–60 baris terakhir log **setelah disensor**. Jangan kirim password, token, atau path pribadi tanpa disensor.
