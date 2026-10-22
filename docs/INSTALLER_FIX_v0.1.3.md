# Gaptex v0.1.3 — PowerShell installer fix

## Akar masalah

Pada Windows PowerShell 5.1, operator `*>>` dapat mengubah output `stderr` milik aplikasi eksternal menjadi `NativeCommandError` apabila `$ErrorActionPreference` bernilai `Stop`. Ini dapat menghentikan installer sebelum nilai exit code program diperiksa.

## Solusi

- `install-online.ps1`, `install.ps1`, dan `uninstall.ps1` kini menjalankan komponen eksternal menggunakan `Start-Process` dengan pemisahan output standar dan error ke berkas sementara.
- Output disalin ke `%LOCALAPPDATA%\Gaptex\logs\install.log` (atau `uninstall.log`), dan berkas sementara dibersihkan.
- Status berhasil/gagal didasarkan pada `ExitCode`, bukan keberadaan output `stderr`.
- Proses otomatis memulai dengan `apply`, baru mencoba `backup apply` jika diperlukan, tanpa menghapus backup lama.

## Diagnosis di PowerShell

```powershell
Get-Content "$env:LOCALAPPDATA\Gaptex\logs\install.log" -Tail 40
```

## Batasan pengujian

Perubahan telah diperiksa secara statis dan pengujian JavaScript dijalankan di lingkungan pengembangan. Eksekusi PowerShell 5.1 dan kompatibilitas Spotify Desktop tetap perlu diuji pada Windows sesungguhnya.
