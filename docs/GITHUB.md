# Publikasi ke GitHub

Simpan salinan repository lama. Hapus file dokumentasi lama yang tidak lagi berlaku (misalnya `docs/RELEASE.md`) bila ada; jangan hapus `.git`. Lalu salin seluruh isi paket ke root repository `https://github.com/efendiyhy/gaptex` setelah menyimpan pekerjaan lama. Tidak perlu mengikutsertakan `cli-main.zip` atau executable Spicetify.

```powershell
git status
git add -A
git commit -m "Rebuild Gaptex v0.3.0 on official Spicetify CLI"
git pull --rebase origin main
git push origin main
```

Pastikan GitHub Actions (terutama pengecekan PowerShell di Windows) lulus. Setelah push, periksa file `install-online.ps1` dan `install.ps1` pada branch `main`, lalu uji perintah instalasi PowerShell pada Spotify Desktop baru yang telah dibuka dan login. Buat GitHub Release menggunakan arsip pengguna jika diinginkan.
