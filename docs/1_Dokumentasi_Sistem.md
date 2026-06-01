# Dokumentasi Sistem (Analisa ERD Engine)

Sistem E-Ticketing Helpdesk & IT Support ini didukung oleh arsitektur backend terdistribusi, di mana otentikasi dan penyimpanan *blob/object* (gambar) dikelola oleh **Supabase (PostgreSQL)**, sementara data utama (*core data*) tiket diurus oleh **Golang Backend REST API**.

## Entity Relationship Diagram (ERD) Abstrak

Berdasarkan struktur model data yang digunakan dalam aplikasi Flutter (pada lapisan *Domain*), kita dapat memetakan ERD sistem menjadi tiga entitas utama yang saling berelasi.

### 1. Entitas `Users` (Profiles)
Digunakan untuk manajemen hak akses dan identitas pengguna. Tersimpan di database Supabase (`auth.users` dan tabel sekunder `public.profiles`).

| Field Name | Data Type | Keterangan |
| :--- | :--- | :--- |
| `id` | UUID (PK) | Di-generate oleh Supabase Auth, primary key. |
| `name` | String | Nama lengkap pengguna. |
| `email` | String | Email untuk login. |
| `role` | Enum | Peran: `user`, `helpdesk`, atau `admin`. |
| `created_at`| Timestamp | Waktu akun dibuat. |

### 2. Entitas `Tickets`
Data utama pengaduan yang dikirim ke backend Golang.

| Field Name | Data Type | Keterangan |
| :--- | :--- | :--- |
| `id` | UUID v4 (PK)| Dibuat oleh *client* (Flutter) menggunakan package `uuid`. |
| `title` | String | Judul keluhan atau masalah. |
| `description`| Text | Detail penjelasan keluhan. |
| `status` | Enum | Status: `open`, `in_progress`, atau `resolved`. |
| `created_by` | String (FK)| ID/Nama dari pelapor (relasi ke `Users`). |
| `assigned_to`| String (FK)| ID/Nama dari teknisi/helpdesk yang ditunjuk (relasi ke `Users`). |
| `attachment_url`| String | Path URL file di Supabase Storage (opsional). |
| `created_at` | Timestamp | Waktu tiket dibuat. |

### 3. Entitas `TicketTimelines` (Catatan Histori / Log)
Berfungsi sebagai *audit trail* atau jejak aktivitas dari suatu tiket. Relasinya adalah *One-to-Many* (Satu Tiket memiliki Banyak Timeline).

| Field Name | Data Type | Keterangan |
| :--- | :--- | :--- |
| `id` | UUID (PK) | ID log timeline. |
| `ticket_id` | UUID (FK) | Merujuk ke entitas `Tickets`. |
| `description`| String | Aktivitas/Komentar (misal: "Status diubah menjadi In Progress"). |
| `actor_role` | String | Peran pengguna yang melakukan aksi (`admin`, `helpdesk`). |
| `timestamp` | Timestamp | Waktu aktivitas dilakukan. |

## Flow Data & Integrasi Engine
1. **User Sign Up/Login**: Klien mengirim *credentials* ke Supabase. Supabase merespons dengan Session Token (JWT).
2. **Kirim Tiket & Attachment**: Jika ada gambar, Flutter mem-bypass Golang dan mengunggahnya (upload) ke **Supabase Storage Bucket** menggunakan UUID v4. URL yang dihasilkan diteruskan bersama data JSON Tiket ke **Golang Backend** melalui *HTTP POST*.
3. **Database Sinkronisasi**: Golang API bertugas memvalidasi *payload* JSON dan menuliskannya ke dalam database utama (misal MySQL/PostgreSQL di sisi Golang).
4. **Data Retrieval & Filtering**: Flutter mengambil daftar tiket via HTTP GET ke Golang API, melakukan *parsing* dari JSON ke objek `TicketModel` di dalam layer Repositori. Data kemudian diserahkan ke *State Management* (Riverpod) yang akan menerapkan **Hierarki Filter ITIL** (User melihat tiket miliknya, Helpdesk melihat tiket yang di-assign padanya, Admin melihat semua) sebelum di-*render* ke UI.
