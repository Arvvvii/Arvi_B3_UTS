# Dokumentasi Frontend UI/UX (Desain Sistem)

Aplikasi dibangun tidak hanya dengan mengutamakan performa fungsi, tapi juga estetika modern berbasis pedoman **Material Design 3 (M3)** dari Google yang dimodifikasi.

## Konsep Desain Utama

1.  **Glassmorphism (Efek Kaca Buram)**
    *   Beberapa kartu (*Card*), *Header*, dan dialog menggunakan efek *blur* translusen (`BackdropFilter` pada Flutter) dipadukan dengan opasitas warna semi-transparan. Efek ini memberikan kedalaman spasial (*depth*) yang mewah dan rasa aplikasi premium iOS/macOS.
2.  **Bento Grid Layout**
    *   Pada halaman Dashboard (terutama untuk Admin/Helpdesk), metrik dan statistik disajikan dalam format **Bento Grid**—berupa blok-blok asimetris membulat (rounded box) yang menyesuaikan dengan luas kontainer (responsif). Format ini sangat ramah mata dan membantu hierarki informasi.
3.  **Warna & Tipografi**
    *   **Font Family:** Menggunakan font dari package `google_fonts` (misalnya Inter atau Poppins) yang memberikan keterbacaan tinggi di ukuran layar kecil.
    *   **Color Scheme:** Mengandalkan `ColorScheme.fromSeed` atau warna kustom *dark/light mode* harmonis, menjauhi warna dasar generik. Kontras diperhitungkan matang untuk pedoman *Accessibility*.
4.  **Lucide Icons**
    *   Memanfaatkan paket `lucide_icons` yang bersudut lengkung dan elegan, menghindari ikon-ikon kaku bawaan *Material Icons* klasik.

## Hirarki Halaman (Screen Flow)

1.  **Splash & Auth Screens**
    *   **Login / Register Page:** Memuat gambar *header banner* lokal (`assets/logindeadline.jpg` dan `assets/registerbp.jpeg`). Menggunakan *TextFormField* melengkung (`OutlineInputBorder` radius 16px).
2.  **Main Dashboard (List Tiket)**
    *   Memiliki area informasi singkat di bagian atas (menggunakan UI Bento).
    *   *ListView/SliverList* di bawahnya untuk *infinite scrolling* tiket.
    *   *Floating Action Button (FAB)* besar dengan efek bayangan dan animasi hover/tap, yang menggunakan skema **Conditional Visibility** (hanya di-render jika role yang login adalah 'User').
3.  **Detail Ticket Screen**
    *   **Header Section:** Menampilkan Judul, Badge Status (berwarna warni: Hijau untuk Resolved, Kuning/Orange untuk In Progress, Merah/Biru untuk Open), dan Nama Pelapor.
    *   **Attachment Card:** Pratinjau *thumbnail* gambar (jika ada) menggunakan *Rounded Image Loader*.
    *   **Activity Timeline Stepper:** Komponen khusus (custom widget) berupa garis vertikal dengan titik-titik bulatan (*nodes*) yang menghubungkan setiap tahap penyelesaian, beserta tanggal waktu yang di-format human-readable (`intl` package).
    *   **Sticky Action Area:** Tombol-tombol "Update Status" dan "Assign Staff" yang mengambang di bawah (bagi peran yang diizinkan) agar mudah dijangkau jempol (ergonomis UX).

## Micro-Interactions
*   Setiap tombol interaktif (ElevatedButton, IconButton) dilengkapi respon sentuhan (*InkWell ripple*).
*   *Skeleton Loading* digunakan sebagai pengganti *loading spinner* bulat (CircularProgressIndicator) saat data API masih di-*fetch*, sehingga pengguna tidak merasa ada kekosongan (*jank*) pada layar.
