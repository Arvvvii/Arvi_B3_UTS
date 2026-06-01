# Manual Book Penggunaan Aplikasi

Aplikasi **E-Ticketing Helpdesk & IT Support** membagi fiturnya berdasarkan 3 hak akses: **User (Pelapor)**, **Helpdesk**, dan **Admin**. Berikut panduan lengkap untuk menggunakan sistem.

---

## A. Panduan untuk "User" (Karyawan / Pelapor)

Peran ini bertugas melaporkan kendala teknis (seperti laptop rusak, jaringan mati) ke tim IT.

1.  **Registrasi dan Login:**
    *   Buka aplikasi, jika belum memiliki akun tap "Register". Isi Nama Lengkap, Email, dan Password. Peran *User* akan secara otomatis diberikan.
    *   Jika sudah punya akun, masukkan Email dan Password untuk Login.
2.  **Melihat Status Tiket Anda:**
    *   Pada halaman utama (Dashboard), Anda akan melihat rangkuman jumlah tiket Anda.
    *   Di bagian bawah terdapat daftar tiket yang pernah Anda buat berserta statusnya (*Open*, *In Progress*, atau *Resolved*).
3.  **Membuat Tiket Keluhan Baru:**
    *   Tap tombol bulat **"+" (Floating Action Button)** di sudut bawah.
    *   Isi **Judul** kendala (contoh: "Wifi Ruang Rapat Mati").
    *   Isi **Deskripsi** detail kendala.
    *   *(Opsional)* Tap icon Kamera atau Galeri untuk mengunggah bukti foto (*screenshot error*, foto kabel terputus).
    *   Tap **Kirim/Submit**. Tiket akan masuk dengan status *Open*.
4.  **Membaca Balasan / Timeline:**
    *   Tap pada salah satu tiket di daftar. Anda dapat melihat jejak penyelesaian pada layar **Activity Timeline**.
    *   Anda dapat menambahkan komentar jika teknisi meminta keterangan tambahan.

---

## B. Panduan untuk "Helpdesk" (Staff / Teknisi IT)

Peran ini tidak membuat tiket, melainkan menyelesaikan dan merespons tiket yang masuk.

1.  **Melihat Daftar Tugas:**
    *   Saat Login, Helpdesk akan melihat seluruh antrean tiket yang berstatus *Open* atau yang di-assign (ditugaskan) ke akun Helpdesk tersebut.
2.  **Menindaklanjuti Tiket:**
    *   Tap tiket yang berstatus *Open*.
    *   Pilih tombol **"Update Status"**.
    *   Ubah status menjadi **"In Progress"** untuk menandakan bahwa tiket sedang dikerjakan.
3.  **Menyelesaikan Tiket:**
    *   Setelah masalah teknis beres di lapangan, masuk lagi ke Detail Tiket.
    *   Ubah status menjadi **"Resolved"**. Tambahkan keterangan/komentar (contoh: "Kabel router sudah diganti").
    *   Secara otomatis akan muncul log timeline penyelesaian.

---

## C. Panduan untuk "Admin" (Manager IT)

Peran tertinggi yang mengontrol aliran penugasan dan melihat gambaran penuh operasional tim.

1.  **Dashboard Statistik:**
    *   Saat masuk, Admin akan disuguhkan *Bento Grid* berisikan statistik metrik (Total Tiket, Tiket *Open*, Tiket Terkendala, dsb.) secara keseluruhan sistem (dari seluruh karyawan).
2.  **Fitur Assign Staff (Penunjukan Otomatis/Manual):**
    *   Admin membuka tiket masuk dari Karyawan (yang berstatus *Open*).
    *   Admin dapat menekan tombol **"Assign Staff"**.
    *   Akan muncul dialog pilihan daftar Helpdesk. Pilih teknisi yang sedang *available* untuk menangani keluhan tersebut.
3.  **Audit dan Pemantauan:**
    *   Admin memiliki akses untuk mengubah status secara bebas, dan dapat membaca seluruh kronologi intervensi dari *Helpdesk* dan *User* di layar Timeline Tiket.
