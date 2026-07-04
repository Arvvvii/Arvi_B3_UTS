# Manual Book Penggunaan Aplikasi

Aplikasi **E-Ticketing Helpdesk & IT Support** membagi fiturnya berdasarkan 3 hak akses: **User (Pelapor)**, **Helpdesk (Teknisi)**, dan **Admin (Manager)**. Berikut panduan lengkap untuk menggunakan seluruh fitur sistem.

---

## A. Panduan untuk "User" (Karyawan / Pelapor)

Peran ini bertugas melaporkan kendala teknis (seperti laptop rusak, jaringan mati) ke tim IT.

1.  **Registrasi dan Login:**
    *   Buka aplikasi, jika belum memiliki akun tap **"Register"**. Isi Nama Lengkap, Email, dan Password. Peran *User* akan secara otomatis diberikan.
    *   Jika sudah punya akun, masukkan Email dan Password untuk Login.
2.  **Melihat Status Tiket Anda:**
    *   Pada halaman utama (Dashboard), Anda akan melihat rangkuman jumlah tiket Anda beserta banner besar **"Create New Ticket"** untuk membuat laporan baru.
    *   Di bagian bawah terdapat daftar tiket yang pernah Anda buat beserta statusnya (*Open*, *In Progress*, atau *Resolved*).
3.  **Membuat Tiket Keluhan Baru:**
    *   Tap tombol bulat **"+" (Floating Action Button)** di sudut bawah (hanya muncul untuk role User).
    *   Isi **Judul** kendala (contoh: "Wifi Ruang Rapat Mati").
    *   Isi **Deskripsi** detail kendala.
    *   *(Opsional)* Tap icon Kamera atau Galeri untuk mengunggah bukti foto atau **dokumen PDF**.
    *   Tap **Kirim/Submit**. Tiket akan masuk dengan status *Open*.
4.  **Membaca Balasan & Live Tracking:**
    *   Tap pada salah satu tiket di daftar. Anda dapat melihat jejak penyelesaian pada **Activity Timeline** secara *real-time*.
    *   Setiap perubahan status (misalnya dari *Open* ke *In Progress*) akan **langsung muncul** di layar Anda tanpa perlu menutup dan membuka halaman kembali.
    *   Anda dapat menambahkan komentar jika teknisi meminta keterangan tambahan. Komentar akan langsung muncul di timeline dalam hitungan detik.
5.  **Pull-to-Refresh (Jika Sinyal Buruk):**
    *   Jika koneksi internet sedang tidak stabil, Anda dapat **menarik layar ke bawah** pada halaman detail tiket untuk memaksa pembaruan data secara manual.
6.  **Notifikasi Push:**
    *   Anda akan menerima notifikasi di HP secara otomatis ketika:
        - Teknisi membalas komentar pada tiket Anda → **"💬 Komentar Baru pada Tiket #XXXXXXXX"**
        - Status tiket berubah → **"🔄 Status Update"** atau **"✅ Tiket Selesai"**

---

## B. Panduan untuk "Helpdesk" (Staff / Teknisi IT)

Peran ini tidak membuat tiket, melainkan menyelesaikan dan merespons tiket yang ditugaskan.

1.  **Melihat Daftar Tugas:**
    *   Saat Login, Helpdesk secara otomatis hanya akan melihat daftar tiket yang telah **ditugaskan (assigned)** secara khusus ke akun Helpdesk tersebut oleh Admin.
    *   Dashboard menampilkan metrik *Bento Grid* berupa statistik tiket "Assigned to Me" dan daftar tiket prioritas tinggi.
2.  **Berkomunikasi dengan Pelapor:**
    *   Tap tiket yang berstatus *In Progress*.
    *   Gunakan kolom **"Add Comment"** di bagian bawah untuk meminta klarifikasi atau memberikan update progress kepada pelapor.
    *   Komentar Anda akan langsung terkirim secara *real-time* ke layar pelapor.
3.  **Menyelesaikan Tiket:**
    *   Setelah masalah teknis beres di lapangan, masuk ke Detail Tiket.
    *   Tap tombol **"Resolve Ticket"** (hanya muncul jika status tiket adalah *In Progress*).
    *   Secara otomatis akan muncul log timeline penyelesaian dan pelapor akan menerima notifikasi **"✅ Tiket Selesai"**.
4.  **Notifikasi Masuk:**
    *   Anda **hanya** akan menerima notifikasi untuk tiket yang ditugaskan kepada Anda. Tiket dari user lain yang belum di-assign tidak akan mengganggu.
    *   Notifikasi komentar baru menampilkan nama pengirim dan isi pesan aslinya.

---

## C. Panduan untuk "Admin" (Manager IT)

Peran tertinggi yang mengontrol aliran penugasan, melihat gambaran penuh operasional tim, dan mengelola akun pengguna.

1.  **Dashboard Statistik Global:**
    *   Saat masuk, Admin akan disuguhkan *Bento Grid* berisikan statistik metrik (Total Tiket, Tiket *Open*, *In Progress*, *Resolved*) secara **keseluruhan sistem** dari semua karyawan.
    *   Terdapat shortcut ke **"Manage Users"** untuk mengelola akun pengguna.
2.  **Fitur Assign Staff (Penunjukan Teknisi):**
    *   Admin membuka tiket masuk dari Karyawan (yang berstatus *Open*).
    *   Admin menekan tombol **"Assign Staff"**.
    *   Akan muncul dialog pilihan daftar Helpdesk yang tersedia. Pilih teknisi yang tepat untuk menangani keluhan tersebut.
    *   Status tiket akan berubah menjadi *In Progress* dan teknisi yang dipilih akan menerima notifikasi.
3.  **Mengubah Status & Berkomentar:**
    *   Admin dapat menekan tombol **"Resolve Ticket"** pada tiket berstatus *In Progress* jika diperlukan.
    *   Admin juga dapat menambahkan komentar pada tiket manapun.
    *   Label role Admin akan ditampilkan sebagai **"System Administrator"** pada timeline.
4.  **Audit dan Pemantauan Real-Time:**
    *   Admin memiliki akses penuh untuk membaca seluruh kronologi intervensi dari *Helpdesk* dan *User* pada layar Timeline Tiket.
    *   Setiap perubahan status dan penugasan dicatat secara otomatis oleh backend dengan timestamp yang presisi.
5.  **Melihat Lampiran PDF:**
    *   Jika tiket menyertakan lampiran berformat PDF, akan muncul **Card merah** bertuliskan **"Buka Lampiran Dokumen PDF"**. Tap untuk membuka dokumen di browser/viewer bawaan perangkat.
