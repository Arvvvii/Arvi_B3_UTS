# 🚀 E-Ticketing Helpdesk & IT Support - UTS Mobile Ticketing System

> **Tugas Ujian Tengah Semester (UTS) - Pemrograman Perangkat Bergerak**  
> **Oleh:** Arvi (DIV IT Universitas Airlangga)  
> **Arsitektur:** Clean Architecture (Feature-First Lite)  
> **Tech Stack:** Flutter | Riverpod | Supabase BaaS | Golang Backend  

---

## 📌 1. Project Identity

Aplikasi **E-Ticketing Helpdesk & IT Support** adalah platform manajemen pengaduan kendala teknis (insiden TI) berskala korporat yang dirancang khusus untuk memfasilitasi pelaporan cepat, penugasan teknisi yang cerdas, dan pemantauan siklus hidup insiden secara transparan. 

Aplikasi ini menggunakan perpaduan teknologi mutakhir yang saling melengkapi untuk mencapai kinerja tinggi, responsivitas antarmuka, dan keamanan data tingkat tinggi.

### 🛠️ Tech Stack yang Digunakan:
*   **Frontend Framework:** `Flutter` (Material 3, performa rendering sekelas aplikasi native dengan 60fps).
*   **State Management:** `Riverpod` (Manajemen status asinkron, *caching*, pembagian ketergantungan tipe-aman/*compile-safe*).
*   **Backend-as-a-Service (BaaS):** `Supabase` (Mengelola user session/otentikasi dan penyimpanan cloud media lampiran secara instan).
*   **API Service Backend:** `Golang` (Layanan REST API berkecepatan tinggi dengan konkurensi superior untuk menyimpan data utama tiket).
*   **Penyimpanan Lokal:** `Shared Preferences` (Untuk menahan token otentikasi dan preferensi lokal pengguna).

---

## 🏗️ 2. Arsitektur Sistem (Clean Architecture - Feature-First Lite)

Aplikasi ini didesain menggunakan pendekatan **Clean Architecture dengan struktur folder Feature-First Lite**. Metode ini memisahkan setiap fitur fungsional (`auth`, `ticket`, `dashboard`, `notification`) ke dalam folder terisolasi, di mana masing-masing fitur dibagi menjadi tiga lapisan (*separation of concerns*) untuk menjamin **kemudahan pemeliharaan (maintainability)** dan **skalabilitas jangka panjang (scalability)**.

### 📊 Diagram Alur Data Sistem
```mermaid
graph TD
    subgraph 📱 Presentation Layer [Lapisan Tampilan]
        UI[UI Widget / Screens]
        Prov[Riverpod Providers]
    end

    subgraph 🧠 Domain Layer [Lapisan Aturan Bisnis]
        Model[Entities / Data Models]
    end

    subgraph 💾 Data Layer [Lapisan Integrasi Data]
        Repo[Repositories]
        Local[Shared Preferences]
    end

    subgraph 🌐 Infrastructure / Cloud Services
        Go[Golang Backend: REST API]
        Supa[Supabase BaaS: Auth & Storage]
    end

    %% Hubungan Alur Data
    UI <-->|Membaca & Mereaksi State| Prov
    Prov -->|Memanggil Aksi Bisnis| Repo
    Repo <-->|Mem-parsing & Mengembalikan| Model
    Repo <-->|Query Token & Prefs| Local
    Repo <-->|HTTP POST/GET/PUT| Go
    Repo <-->|Otentikasi & Upload File| Supa
```

### Penjelasan Lapisan Arsitektur:
1.  **Presentation Layer (UI & State):** Berisi berkas antarmuka pengguna (`login_screen.dart`, `create_ticket_screen.dart`, dll.) serta pengelola status reaktif Riverpod (`auth_provider.dart`, `ticket_provider.dart`). Tampilan langsung mereaksi setiap perubahan data secara otomatis (*declarative UI*).
2.  **Domain Layer (Entities & Enums):** Adalah jantung dari aturan bisnis. Berisi `user_model.dart` dan `ticket_model.dart`. Lapisan ini terbebas penuh dari ketergantungan framework eksternal, menjadikannya sangat kokoh terhadap perubahan infrastruktur.
3.  **Data Layer (Repositories):** Berkas seperti `auth_repository.dart` dan `ticket_repository.dart` bertanggung jawab menyatukan data lokal (SharedPreferences) dengan data jarak jauh (API HTTP Golang & SDK Supabase), mengubah format JSON mentah dari server menjadi model objek bertipe aman.

---

## 👥 3. Role & Permissions (Matriks Hak Akses Dinamis)

Sistem menerapkan pembatasan hak akses yang ketat berdasarkan peran pengguna saat masuk log (*role-based access control*). Berikut adalah pembedaan fitur untuk masing-masing peran:

| Fitur Aplikasi | 👤 User (Pelapor) | 🛠️ Helpdesk (Staff) | 👑 Admin (Manager) |
| :--- | :---: | :---: | :---: |
| Mendaftar Akun Baru |  | ❌ *(Di-bypass Admin)* | ❌ *(Manual DB)* |
| Mengirim Tiket & Lampiran |  | ❌ | ❌ |
| Komentar & Masukan Timeline |  |  |  |
| Membaca Tiket Milik Sendiri |  |  |  |
| Membaca Seluruh Tiket Sistem | ❌ | ❌ *(Hanya yang di-assign)* |  |
| Memperbarui Status Tiket *(Open ➔ In Progress ➔ Resolved)* | ❌ |  |  |
| Menunjuk Teknisi / Staff (*Assign Staff*) | ❌ | ❌ |  |

---

## 📋 4. Daftar Fitur (Functional Requirements FR-001 s/d FR-011)

Aplikasi ini telah sepenuhnya mengimplementasikan 11 spesifikasi fungsional utama serta dilengkapi fitur estetika visual modern:

*   **🔑 FR-001 [Registrasi Akun]:** Mendaftarkan kredensial pengguna baru secara aman via Supabase Auth dan menyimpan data sekunder ke tabel `public.profiles`.
*   **🔐 FR-002 [Login & Otentikasi]:** Proses masuk log bertipe aman berdasarkan peran dinamis (*User*, *Helpdesk*, *Admin*) yang ditarik dari database relasional.
*   **🔄 FR-003 [Auto-Restore Session]:** Memanfaatkan cache Supabase Session untuk mempertahankan sesi masuk log aktif pengguna saat aplikasi ditutup dan dibuka kembali.
*   **📝 FR-004 [Pembuatan Tiket]:** Formulir pengaduan kendala terintegrasi di mana pengguna dapat mengirim judul dan deskripsi insiden teknis langsung ke Golang API.
*   **📷 FR-005 [Lampiran Kamera/Galeri]:** Pemanfaatan kamera perangkat atau galeri foto untuk melampirkan screenshot bukti kesalahan (terbatas maksimal file 5MB untuk menghemat bandwidth).
*   **🔍 FR-006 [Daftar Tiket & Filter Paginated]:** Halaman daftar tiket interaktif yang memuat data secara dinamis (*lazy loading / loadMore*) serta penyaringan instan berdasarkan status.
*   **📄 FR-007 [Detail Tiket & Preview Attachment]:** Halaman detail komprehensif yang memuat seluruh informasi teknis, data lampiran dari Supabase Cloud Bucket, serta status.
*   **📈 FR-008 [Statistik Bento Grid & Glassmorphic UI]:** Tampilan antarmuka Dashboard modern yang menyajikan statistik jumlah tiket (*Open*, *In Progress*, *Resolved*, *Total*) menggunakan layout **Bento Grid** interaktif dan efek kaca buram (**Glassmorphism**).
*   **🕒 FR-009 [Activity Timeline Stepper]:** Pelacakan alur perjalanan tiket secara langsung menggunakan visualisasi garis waktu vertikal (*stepper timeline*) yang mencatat setiap peristiwa.
*   **⚙️ FR-010 [Update Status & Otorisasi]:** Fungsi dinamis bagi Helpdesk dan Admin untuk mengubah status pengerjaan tiket dengan validasi otorisasi di sisi UI.
*   **🤖 FR-011 [Smart Auto-Assign & Live Comment]:** 
    *   **Auto-Assign:** Admin secara cerdas dapat mencarikan staff penanggung jawab yang tepat dari departemen tertentu (*Helpdesk* / *IT Support*) secara acak yang ditarik dari tabel profiles.
    *   **Live Comment:** Fitur penambahan catatan/komentar dari semua peran ke dalam garis waktu tiket secara real-time.

---

## ⚡ 5. Technical Highlights (The 'Magic' Features)

### 🔮 A. Penggunaan UUID v4 untuk Integritas Data Tinggi
Guna mencegah konflik data pengenal (*ID Collision*) dalam database konkuren tinggi, sistem membuang ID urut integer (`1`, `2`, `3`) dan menerapkan **Universally Unique Identifier (UUID) v4** di sisi klien:
*   **Saat Submit Tiket Baru:** Klien menggunakan package `uuid` untuk menetapkan ID unik 128-bit acak sebelum mengirim data ke Golang Backend.
    ```dart
    id: const Uuid().v4() // Digenerate instan di create_ticket_screen.dart
    ```
*   **Saat Upload File ke Storage Cloud:** UUID digunakan sebagai awalan nama file gambar agar tidak ada berkas di cloud storage bucket yang tertimpa secara tidak sengaja.
    ```dart
    final String fileName = '${const Uuid().v4()}_${file.path.split('/').last}';
    ```

### 🔮 B. SQL Trigger di Supabase untuk Bypass Verifikasi Email
Untuk mempercepat integrasi sistem selama demonstrasi dan pengujian lokal tanpa memerlukan email verifikasi manual yang lambat, database Supabase ditanamkan fungsi **SQL Trigger**:
```sql
-- SQL Function untuk otomatisasi konfirmasi email di Supabase
CREATE OR REPLACE FUNCTION public.auto_verify_email()
RETURNS TRIGGER AS $$
BEGIN
    NEW.email_confirmed_at = NOW(); -- Bypass email confirmation
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger yang berjalan otomatis sebelum baris baru masuk ke auth.users
CREATE TRIGGER on_user_signup_verify
    BEFORE INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.auto_verify_email();
```

### 🔮 C. Conditional Visibility di Flutter untuk Keamanan UI
Sistem membatasi rendering elemen UI sensitif langsung dari pohon widget (*Widget Tree*) menggunakan logika kondisional Dart berdasarkan peran masuk pengguna, menjamin bahwa pengguna biasa tidak dapat melihat atau mengeksekusi operasi Helpdesk/Admin:
```dart
// Mendeteksi peran login pengguna saat ini
final user = ref.watch(authProvider).value;
final isUser = user?.role.toString().split('.').last == 'user';

// Menggunakan Operator Spread (...) untuk conditional rendering di ticket_detail_screen.dart
if (!isUser) ...[
  // Widget tombol 'Update Status' dan 'Assign Staff' hanya dirender untuk Admin/Helpdesk
  ElevatedButton.icon(
    onPressed: () => _showUpdateStatusDialog(...),
    icon: const Icon(LucideIcons.edit3),
    label: const Text('Update Status'),
  ),
]

// Di ticket_list_screen.dart, Tombol Create (FAB) dihilangkan untuk Admin/Helpdesk
floatingActionButton: user?.role == UserRole.user ? FloatingActionButton(...) : null,
```

---

## 📥 6. Instalasi & Cara Menjalankan

### 📋 Prasyarat
*   Flutter SDK (Minimal Versi 3.10.8)
*   Golang SDK (Minimal Versi 1.20) untuk Server Backend API
*   Akun aktif Supabase untuk BaaS

### 🚀 Langkah Menjalankan Aplikasi
1.  **Clone dan Pindah ke Folder Project:**
    ```bash
    cd d:/Project/Android/maauts003
    ```
2.  **Unduh Seluruh Dependencies Flutter:**
    ```bash
    flutter pub get
    ```
3.  **Setup Environment Variables (.env):**
    Buat file bernama `.env` pada direktori root project dengan nilai variabel berikut:
    ```env
    SUPABASE_URL=https://chqperxbnbgsyeldptfk.supabase.co
    SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
    BACKEND_URL=http://10.0.2.2:8080 # IP khusus Emulator Android ke Localhost
    ```
4.  **Menjalankan Aplikasi Mobile:**
    Jalankan ke perangkat fisik Android yang terhubung atau emulator:
    ```bash
    flutter run
    ```
