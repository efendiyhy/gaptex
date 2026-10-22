# Gaptex 0.1.2 — catatan teknis

Gaptex adalah ekstensi independen berbentuk `gaptex.js` untuk Spotify Desktop. Ia **masih memakai Spicetify CLI dan API ekstensi JS secara internal**. Kredensial, kode biner, dan lisensi perangkat lunak pihak ketiga tidak termasuk dalam paket source Gaptex. Lihat [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Mekanisme pemasangan

- `install-online.ps1` mengunduh `gaptex.js` dari repository resmi (branch `main`).
- Installer mencari komponen runtime lokal; jika belum ditemukan, ia meminta persetujuan untuk menginstal paket via winget.
- Installer menambahkan `gaptex.js` ke daftar ekstensi dan mencoba menerapkannya. Output detail disimpan ke `%LOCALAPPDATA%\Gaptex\logs\install.log` untuk debugging.
- Aktivasi mencoba `apply` terlebih dahulu, lalu `backup apply` untuk pemasangan awal. Tidak menghapus backup lama secara otomatis.
- `install.ps1` melakukan prosedur serupa dari ZIP lokal.
- `uninstall.ps1` menghapus ekstensi Gaptex tetapi tidak menghapus runtime bersama.

## Kemampuan dan batasan

- AdBlock mencoba menggunakan UI selectors serta API ad manager internal yang tersedia. Pemblokiran iklan audio tidak dapat dijamin.
- Anti-Reshuffle menjaga *status shuffle*, bukan menyimpan antrean lagu.
- Tidak melakukan intersepsi HTTPS, pemalsuan status Premium, atau pengunduhan kode ekstensi pihak ketiga.
- Ekstensi dan installer belum diuji langsung pada semua versi Windows/Spotify. Uji manual wajib dilakukan sebelum klaim kompatibilitas produksi.

## Uji manual yang perlu dilakukan

1. Instal di Windows yang belum memiliki runtime integrasi dan pastikan prompt persetujuan muncul.
2. Ulangi instalasi pada Windows yang sudah memiliki runtime dan backup yang valid.
3. Pastikan tiga menu Gaptex ada pada menu profil Spotify.
4. Aktif/nonaktif AdBlock, restart Spotify, dan verifikasi dampak pada antarmuka dan audio secara terpisah.
5. Nyalakan Anti-Reshuffle, pilih OFF/ON, ubah status shuffle, dan cek apakah mode dikembalikan.
6. Jalankan uninstaller dan cek tidak ada menu Gaptex tertinggal.

Refs: https://spicetify.app/docs/customization/extensions/ ; https://github.com/spicetify/cli
