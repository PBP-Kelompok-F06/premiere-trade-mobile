# Premiere Trade Mobile

`Premiere Trade Mobile` merupakan Mobile App transfer jual beli pemain bola, di mana pemilik `Admin Club` dapat melakukan jual beli pemain pada app ini dengan sesama pemilik `Admin Club` lainnya. Terdapat juga `Fan Account` yang bisa melihat siapa saja pemain yang sedang dimasukkan ke dalam daftar transfer oleh setiap klub, serta melihat nilai pasar dari semua pemain yang ada.

---

## Anggota Kelompok

| Nama                          | NIM        |
| :---------------------------- | :--------- |
| Walyul'ahdi Maulana Ramadhan  | 2406426012 |
| Muhammad Indi Ryan Pratama    | 2406432160 |
| Salsabila Salimah             | 2406432734 |
| Aryandana Pascua Patiung      | 2406438214 |
| Adryan Muhammad Rasyad        | 2406430451 |

---


## Jenis Pengguna & Hak Akses

Proyek ini memiliki empat jenis pengguna dengan hak akses yang berbeda:

### 1. Super Admin
* CRUD User
* CRUD Pemain
* CRUD Klub

### 2. Admin Club
* Melihat daftar pemain dari setiap klub.
* Melihat halaman bursa transfer.
* Melakukan transaksi penuh: menempatkan pemain untuk dijual, mengajukan penawaran, membeli, dan menerima/menolak tawaran dari klub lain.

### 3. Fan Account
* Melihat daftar pemain dari setiap klub.
* Melihat halaman bursa transfer (hanya melihat, tidak bisa bertransaksi).
* *Catatan: Siapa pun dapat mendaftar sebagai Fan Account.*

### 4. User Non-Login
* Hanya dapat melihat daftar pemain dari setiap klub.

---

## Modul

#### 0. Modul `main` (Dikerjakan bersama)
* Menyediakan homepage, template dasar (`base.html`), dan mengelola data master untuk `Club` dan `Player`.
* **CRUD**:
    * **Create**: (Data Awal) Mengimpor data pemain dari dataset.
    * **Read**: Menampilkan halaman daftar klub dan daftar pemain yang bisa dilihat oleh semua pengguna.

#### 1. Modul `accounts` (Walyul'ahdi Maulana Ramadhan)
* Mengelola otentikasi dan profil pengguna.
* **CRUD**:
    * **Create**: Registrasi untuk (`Fan Account`), Membuat User baru (`Super Admin`).
    * **Read**: Melihat halaman profil sendiri (`Fan Account`/ `Admin Club`), Melihat seluruh data User, Klub, Pemain (`Super Admin`).
    * **Update**: Mengedit informasi profil (`Fan Account`/ `Admin Club`), Mengedit seluruh data User, Klub, Pemain (`Super Admin`).
    * **Delete**: Menghapus akun sendiri (`Fan Account`/ `Admin Club`), Dapat menghapus data User, Klub, Pemain apapun (`Super Admin`).

#### 2. Modul `transactions` (Muhammad Indi Ryan Pratama)
* Mengelola seluruh alur bursa transfer.
* **CRUD**:
    * **Create**: `Admin Club` membuat `TransferListing` (menjual pemain) dan `Offer` (menawar pemain).
    * **Read**: Semua pengguna melihat bursa transfer. `Admin Club` melihat detail tawaran masuk/keluar.
    * **Update**: `Admin Club` menerima/menolak `Offer`. Status pemain diperbarui setelah transfer.
    * **Delete**: `Admin Club` membatalkan `TransferListing` atau `Offer`.

#### 3. Modul `best_eleven` (Salsabila Salimah)
* Fitur bagi `Fan Account` untuk membuat formasi 11 pemain terbaik.
* **CRUD**:
    * **Create**: `Fan Account` membuat formasi baru.
    * **Read**: `Fan Account` melihat formasi yang telah disimpan.
    * **Update**: `Fan Account` mengubah pemain dalam formasi mereka.
    * **Delete**: `Fan Account` menghapus formasi.

#### 4. Modul `rumors` (Adryan Muhammad Rasyad)
* Platform bagi `Fan Account` untuk memposting dan membahas rumor transfer.
* **CRUD**:
    * **Create**: `Fan Account` membuat postingan rumor baru.
    * **Read**: Semua pengguna membaca daftar rumor.
    * **Update**: Pengguna mengedit postingan rumor milik mereka.
    * **Delete**: Pengguna menghapus postingan rumor milik mereka.

#### 5. Modul `community` (Aryandana Pascua Patiung)
* Forum diskusi umum bagi `Fan Account`.
* **CRUD**:
    * **Create**: `Fan Account` membuat topik (`Thread`) atau balasan (`Post`) baru.
    * **Read**: Semua pengguna membaca forum.
    * **Update**: Pengguna mengedit `Thread` atau `Post` milik mereka.
    * **Delete**: Pengguna menghapus `Thread` atau `Post` milik mereka.

---

## Alur Integrasi

1.  **Web Service (Django):** Menyediakan endpoint JSON untuk data pemain, klub, dan fitur lainnya.
2.  **Mobile App (Flutter):** Mengambil data menggunakan `package:http` secara *asynchronous*.
3.  **Autentikasi:** Menggunakan `pbp_django_auth` untuk menangani cookie dan session antara Flutter dan Django.

---

## Flutter Plan



1. Pekan 1 (17-24 November 2025)

Walyul'ahdi Maulana Ramadhan : Menginisiasi Flutter Project, Desain Model, API Setup

Muhammad Indi Ryan Pratama   :

Salsabila Salimah            :

Aryandana Pascua Patiung     : Mulai melakukan design Figma

Adryan Muhammad Rasyad       : Membuat deskripsi github & Desain Model & API Setup


---


2. Pekan 2 (24 November 2025-1 Desember 2025)

Walyul'ahdi Maulana Ramadhan : Implementasi API auth

Muhammad Indi Ryan Pratama   :

Salsabila Salimah            :

Aryandana Pascua Patiung     : Implementasi create and read page Community

Adryan Muhammad Rasyad       : Implementasi rumors I (Read)


---


3. Pekan 3 (1 Desember 2025-8 Desember 2025)

Walyul'ahdi Maulana Ramadhan : Implementasi accounts Profil

Muhammad Indi Ryan Pratama   :

Salsabila Salimah            :

Aryandana Pascua Patiung     : Implementasi edit page Community

Adryan Muhammad Rasyad       : implementasi rumors II (Create)


---


4. Pekan 4 (8 Desember 2025 - 17 Desember 2025)

Walyul'ahdi Maulana Ramadhan : Implementasi dashboard admin

Muhammad Indi Ryan Pratama   :

Salsabila Salimah            :

Aryandana Pascua Patiung     : Implementasi delete page Community

Adryan Muhammad Rasyad       : implementasi rumors III (Update & Delete) 


---


5. Pekan 5 (17 Desember 2025 - 21 Desember 2025)

Kelompok : Integrasi dan membenarkan error jika ada.


---

