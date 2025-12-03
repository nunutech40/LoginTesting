//
//  SecureStorage.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 03/12/25.
//

import Foundation
import KeychainAccess

// MARK: - AuthLocalDataSourceProtocol (Interface Anda)
// Tidak perlu diubah.
protocol SecureStorageProtocol {
    func saveToken(_ token: String, key: String) throws
    func getToken(key: String) -> String?
    func clearAll() throws
}

// MARK: - AuthLocalDataSource Implementation
final class SecureStorage: SecureStorageProtocol { // Gunakan 'final class'
    
    // Key Identifier: Tentukan service ID yang unik untuk aplikasi ini
    // Objek 'keychain' ini mengelola semua item di bawah service ID ini.
    private let keychain: Keychain
    
    // Key yang digunakan untuk menyimpan token di dalam service ID di atas
    private let accessTokenKey = "accessToken"      // Menggunakan key sederhana, service ID sudah unik
    private let refreshTokenKey = "refreshToken"
    
    // Inisialisasi Klien Keychain
    // service: adalah parameter unik yang membedakan Keychain service Anda dari aplikasi lain
    init(service: String = "id.ios.rajaongkirios.LoginTesting") {
        self.keychain = Keychain(service: service)
    }
    
    // MARK: - Operasi Penyimpanan
    func saveToken(_ token: String, key: String) throws {
        // Menggunakan set(_:key:) dari KeychainAccess
        do {
            try keychain.set(token, key: key)
        } catch {
            // Melemparkan error custom jika ada masalah saat menyimpan (misalnya, device terkunci)
            throw error // Biarkan error dari KeychainAccess yang dilempar, atau buat custom error
        }
    }
    
    // MARK: - Operasi Pengambilan
    func getToken(key: String) -> String? {
        // Menggunakan get(key:) dari KeychainAccess
        return try? keychain.get(key)
    }
    
    // MARK: - Operasi Penghapusan
    func clearAll() throws {
        // Menghapus item berdasarkan key
        try keychain.remove(accessTokenKey)
        try keychain.remove(refreshTokenKey)
        
        // Catatan: Jika Anda ingin menghapus SEMUA data di service ini, gunakan:
        // try keychain.removeAll()
    }
    
    // Anda mungkin juga ingin menambahkan fungsi helper untuk menyimpan/mengambil Access Token dan Refresh Token
    func saveAccessAndRefreshTokens(accessToken: String, refreshToken: String) throws {
        try keychain.set(accessToken, key: accessTokenKey)
        try keychain.set(refreshToken, key: refreshTokenKey)
    }
    
    func getAccessToken() -> String? {
        return try? keychain.get(accessTokenKey)
    }
}
