# Release Gaptex 0.1.6 — Diagnostik instalasi

- Tetap menggunakan banner warna-warni EK INSTRUMENTATION dan gambar kucing.
- Membedakan instalasi Spotify rusak/tidak bisa dibackup dari backup belum tersedia.
- Tidak lagi menjalankan `backup apply` secara sia-sia setelah pesan `cannot be backed up at this state`.
- Menampilkan instruksi instalasi ulang Spotify Desktop yang aman, tanpa otomatis menghapus aplikasi/data.
- Upaya menormalkan log keluaran command (ANSI/Unicode) yang pada versi lama menjadi karakter acak.
- Instalasi online/offline tetap memakai satu engine `install.ps1`.
- Komponen pihak ketiga tetap tercantum dalam notice.

**Batasan pengujian:** Uji statis, pemeriksaan struktur, dan pengujian JS. Belum diuji di Spotify Desktop nyata pada Windows.
