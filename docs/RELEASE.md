# Release Gaptex 0.1.5

- Installer offline/online menggunakan logika aktivasi yang sama.
- Menampilkan animasi visual statis ASCII kucing dan teks besar EK INSTRUMENTATION, dengan warna berbeda per baris.
- Membersihkan terminal ketika installer dimulai; menyesuaikan lebar teks pada terminal yang lebih sempit.
- Menghentikan proses Spotify sebelum konfigurasi/penerapan.
- Memisahkan stdout dan stderr program eksternal di Windows PowerShell 5.1.
- Mencoba `apply` dahulu, lalu `backup apply` jika backup belum ada.
- Meminta persetujuan sebelum `restore backup apply` ketika backup tidak sinkron.
- Menampilkan isi log asli jika aktivasi tetap gagal.
- Komponen pihak ketiga tetap diungkapkan dalam dokumen lisensi.

**Catatan:** Ini adalah paket source yang diuji secara statis dan menggunakan tes JavaScript otomatis. Belum ada uji end-to-end pada Spotify Desktop di Windows nyata.
