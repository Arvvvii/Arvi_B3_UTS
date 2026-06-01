# Dokumentasi Coding (Penjelasan Function)

Aplikasi Flutter ini dibangun menggunakan pendekatan **Clean Architecture - Feature-First Lite** yang mengisolasi kode per fitur (`auth`, `ticket`, `dashboard`). Setiap fitur dibagi ke tiga lapis: **Presentation (UI)**, **Domain (Model)**, dan **Data (Repository)**.

## Pengelolaan State Management (Riverpod)

Proyek ini sangat mengandalkan `flutter_riverpod` untuk menangani *State* dan pembagian dependensi (*Dependency Injection*).

### 1. `auth_provider.dart` & `AuthRepository`
*   **Fungsi `login(email, password)`**: Mengirim *request* otentikasi ke Supabase. Jika berhasil, objek `UserModel` (yang menampung nama, ID, dan *role*) akan diemisikan (emit) ke dalam *State*. 
*   **Fungsi `restoreSession()`**: Berjalan saat aplikasi pertama dibuka (*splash screen*). Secara otomatis mengambil token *cache* (SharedPreferences / Supabase Auth State) untuk melompati halaman login jika sesi masih aktif.
*   **Fungsi `logout()`**: Menghapus sesi di Supabase dan SharedPreferences, lalu mereset state AuthProvider.

### 2. `ticket_provider.dart` & `TicketRepository`
*   **Fungsi `fetchTickets()`**: Menggunakan *Dio* atau *http* client untuk menembak API Golang. Mengonversi balikan JSON `List<dynamic>` menjadi `List<TicketModel>`. Mengadopsi mekanisme *loading/error state* bawaan dari `AsyncValue` milik Riverpod.
*   **Fungsi `createTicket(TicketModel)`**: Mengemas data tiket beserta path/URL lampiran, lalu melakukan POST ke server Golang. UUID v4 *generated locally* disematkan di fungsi ini untuk menjamin ID Unik sebelum dikirim.
*   **Fungsi `updateTicketStatus(ticketId, newStatus)`**: Menembak *endpoint* PUT/PATCH ke API, untuk memodifikasi field `status`. Jika sukses, data lokal Riverpod langsung di-refresh (`ref.invalidate()`) agar antarmuka UI *Dashboard* berubah otomatis.
*   **Fungsi `assignStaff(ticketId, staffId)`**: Logika admin untuk menugaskan (assign) staff/helpdesk spesifik. Mengupdate field `assigned_to`.

### 3. Image Upload Logic (`ImagePicker` & Supabase Storage)
*   **Fungsi `pickImage()`**: Memanggil library `image_picker` (sumber: galeri / kamera) untuk mengambil path file *byte stream*.
*   **Fungsi `uploadAttachment(File file)`**:
    ```dart
    final String fileName = '${const Uuid().v4()}_${file.path.split('/').last}';
    // Mengupload byte stream secara presigned ke bucket "attachments"
    ```

### 4. Routing dengan `GoRouter`
Navigasi dikelola oleh `go_router` menggunakan deklarasi *path* (misal `/login`, `/dashboard`, `/ticket/:id`). 
*   **Redirect Logic (Guard)**: Terdapat *router guard* yang memantau *auth state*. Jika state bernilai `null` (belum login) tapi pengguna mencoba membuka halaman `/dashboard`, aplikasi akan secara otomatis mem-*force redirect* pengguna kembali ke `/login`.

### 5. Conditional Rendering di UI
Banyak komponen *Widget* menggunakan kondisi Dart untuk menyembunyikan fungsi dari peran yang tidak berhak:
```dart
if (user.role == UserRole.admin || user.role == UserRole.helpdesk) {
   // Tampilkan tombol Update Status
}
```
