# Catatan teknis Gaptex 0.1.0

## Scope

- Platform: Spotify Desktop (Windows/Linux/macOS) dan Spicetify yang masih mendukung API ekstensi JS biasa.
- Hanya dua fitur: penyaringan iklan UI/manager dan menjaga status tombol shuffle.
- Tidak ada patch berkas Spotify, pemalsuan status langganan Premium, penangkapan token, proxy HTTPS, injeksi web request global, atau perubahan playback stream.

## AdBlock

1. Tambahkan CSS selektor iklan yang relatif semantik (mis. `[data-testid]`).
2. Jika `Spicetify.Platform.AdManagers` tersedia, panggil fungsi `disable()` pada manager yang diketahui dan `disableLeaderboard()` bila ada.
3. Coba mengubah flag `ads` menjadi `0` melalui ProductState API internal; **tidak** menyamar sebagai akun Premium. Jika tersedia, bersihkan slot iklan lewat konektor ad-slot.
4. Ulangi secara berkala karena Spotify dapat mengaktifkan kembali manager setelah state berubah.
5. Jika API tidak tersedia, hanya lapisan UI yang akan bekerja. Tidak ada keberhasilan audio blocking yang dapat diasumsikan.

## Anti-Reshuffle

- Default: `antiReshuffle=true`, `preferredShuffle=false`.
- Event `songchange` + pemeriksaan setiap 3 detik membandingkan `Player.getShuffle()` dengan preferensi.
- Jika berbeda, panggil `Player.setShuffle(preferredShuffle)`, dengan jeda antarpanggilan untuk menghindari spam.
- **Tidak** mengganti `Queue.nextTracks` atau otomatis mengacak antrean. Queue semacam itu dikelola oleh Spotify dan pengubahan agresif rentan mengacaukan perangkat lain.

## Known limitations

- Respons `setShuffle()` tidak selalu bermakna Spotify mengizinkan kontrol bebas pada semua jenis akun.
- AdManagers, class CSS, dan menu dapat berubah antarversi.
- Pengaturan disimpan dalam Spicetify LocalStorage, bukan sistem cloud.
- Spicetify v3 package system tidak identik dengan mekanisme manual ekstensi JS; paket ini ditargetkan untuk instalasi manual yang didokumentasikan Spicetify.

## Real-device test matrix (belum dijalankan)

1. Jalankan di Spotify Desktop Windows dengan Spicetify yang kompatibel.
2. Cek menu profil berisi ketiga entri Gaptex dan status tersimpan setelah restart.
3. Pada akun uji, nyalakan lagu dan pastikan shuffle mode dikembalikan bila disetel berbeda.
4. Validasi iklan UI serta iklan audio secara terpisah (jangan menganggap keduanya setara).
5. Matikan Gaptex dan pastikan tidak ada efek lain; lakukan restart untuk manajer iklan.
6. Uji kompatibilitas ulang seusai update Spotify/Spicetify.

## Refs

- https://spicetify.app/docs/customization/extensions/
- https://spicetify.app/docs/development/api-wrapper/methods/player/
- https://spicetify.app/docs/development/api-wrapper/methods/platform/
- https://github.com/rxri/spicetify-extensions
