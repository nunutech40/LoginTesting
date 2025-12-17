# LoginTesting

## Gambaran Umum
LoginTesting adalah aplikasi iOS yang dirancang untuk mendemonstrasikan arsitektur yang kuat dan terukur menggunakan VIPER (View, Interactor, Presenter, Entity, Router) yang dikombinasikan dengan prinsip-prinsip Clean Architecture. Proyek ini berfokus pada alur login yang aman, otentikasi pengguna, dan manajemen profil pengguna dasar, menunjukkan praktik terbaik untuk modularitas, kemampuan pengujian, dan pemisahan masalah.

## Fitur
-   Registrasi pengguna (placeholder/fitur masa depan)
-   Login dan otentikasi pengguna
-   Melihat profil pengguna
-   Penanganan data yang aman (melalui KeychainAccess)
-   Permintaan jaringan menggunakan Alamofire

## Arsitektur: VIPER + Clean Architecture

Proyek ini mengimplementasikan kombinasi VIPER dan Clean Architecture untuk mencapai basis kode yang sangat modular, dapat diuji, dan mudah dipelihara.

### VIPER
VIPER adalah singkatan dari:
-   **View**: Bertanggung jawab untuk menampilkan UI dan meneruskan interaksi pengguna ke Presenter.
-   **Interactor**: Berisi logika bisnis untuk kasus penggunaan. Ini mengambil data dari entitas (model) dan menyiapkannya untuk Presenter.
-   **Presenter**: Berisi logika tampilan. Ini menerima tindakan pengguna dari View, meminta data dari Interactor, dan memperbarui View.
-   **Entity (Model)**: Berisi struktur data sederhana atau objek bisnis yang digunakan oleh Interactor.
-   **Router (Wireframe)**: Bertanggung jawab untuk logika navigasi, menentukan layar mana yang akan ditampilkan selanjutnya.

### Clean Architecture
Proyek ini mematuhi Clean Architecture dengan mengatur kode menjadi beberapa lapisan:

1.  **Lapisan Domain (Core/Domain)**: Berisi aturan bisnis (Entitas, Kasus Penggunaan/Interactor, antarmuka Repositori). Lapisan ini tidak tergantung pada kerangka kerja atau UI apa pun.
2.  **Lapisan Data (Core/Data)**: Mengimplementasikan antarmuka Repositori yang didefinisikan dalam Lapisan Domain. Ini menangani sumber data (API jarak jauh, penyimpanan lokal) dan pemetaan data.
3.  **Lapisan Presentasi (Features)**: Berisi UI (View) dan logika presentasi (Presenter, ViewModel).

### Struktur Proyek

-   `LoginTestingApp.swift`: Titik masuk aplikasi.
-   `App/ContentView.swift`: Tampilan konten utama.
-   `Core/`: Berisi komponen arsitektur inti.
    -   `Data/`: Sumber data dan implementasi repositori.
        -   `DataSource/`: Antarmuka/implementasi sumber data jarak jauh dan lokal.
        -   `Repository/`: Implementasi konkret dari repositori domain.
    -   `DI/`: Pengaturan Injeksi Dependensi (misalnya, menggunakan `Injection.swift`).
    -   `Domain/`: Lapisan logika bisnis.
        -   `Interactor/`: Implementasi kasus penggunaan.
        -   `Model/`: Model data inti (Entitas).
        -   `UseCase/`: Protokol untuk kasus penggunaan/interactor.
    -   `Utils/`: Ekstensi utilitas, fungsi pembantu, dan konfigurasi jaringan.
        -   `Extentions/`: Ekstensi Swift.
        -   `Helper/`: Kelas utilitas umum (misalnya, penanganan kesalahan).
        -   `Network/`: Klien jaringan, konstanta, dan perutean.
-   `Features/`: Berisi modul spesifik fitur, masing-masing mengikuti struktur VIPER.
    -   `Auth/Login/`: Modul fitur login (komponen View, Presenter, Interactor, Entity, Router).
    -   `Home/`: Modul fitur layar beranda.
    -   `Shared/`: Komponen umum yang dibagi di seluruh fitur (misalnya, `AuthenticationManager`).

## Dependensi

Proyek ini menggunakan CocoaPods untuk manajemen dependensi. Dependensi utama meliputi:

-   **Alamofire**: Pustaka jaringan HTTP yang elegan untuk Swift.
-   **KeychainAccess**: Pembungkus Swift sederhana untuk Keychain yang berfungsi di iOS, macOS, watchOS, dan tvOS.

Untuk menginstal dependensi, navigasikan ke root proyek dan jalankan:
```bash
pod install
```

## Cara Membangun dan Menjalankan

1.  **Kloning repositori**:
    ```bash
    git clone [repository_url]
    cd LoginTesting
    ```
2.  **Instal dependensi CocoaPods**:
    ```bash
    pod install
    ```
3.  **Buka di Xcode**: Buka `LoginTesting.xcworkspace` (bukan `LoginTesting.xcodeproj`).
4.  **Pilih target**: Pilih target `LoginTesting` untuk iPhone atau iPad.
5.  **Jalankan**: Bangun dan jalankan proyek (`Cmd + R`).

## Pengujian

Proyek ini mencakup pengujian unit untuk berbagai lapisan dan komponen.
-   `LoginTestingTests/`: Berisi semua pengujian unit.
    -   `Core/Data/Repository/UserRepositoryTest.swift`: Contoh pengujian repositori.
    -   `Features/Home/Presenter/HomePresenterTest.swift`: Contoh pengujian presenter.

Untuk menjalankan pengujian:
1.  Buka `LoginTesting.xcworkspace` di Xcode.
2.  Pergi ke Product -> Test (atau `Cmd + U`).

## Lisensi

[INFO_LISENSI_DI_SINI] - *Mohon isi informasi lisensi proyek Anda.*
