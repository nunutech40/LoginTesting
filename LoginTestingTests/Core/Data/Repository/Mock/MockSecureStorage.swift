//
//  MockSecureStorage.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 04/12/25.
//

import XCTest
@testable import LoginTesting

// MARK: - 2. SUPER MOCK SECURE STORAGE
// Mock ini bisa:
// a. Disuruh nyatet saveToken (Spy) -> Buat Repository Test
// b. Disuruh balikin token palsu (Stub) -> Buat AuthManager Test
// c. Disuruh nyatet clearAll (Spy) -> Buat Logout Test

class MockSecureStorage: SecureStorageProtocol {
    
    // --- Bagian STUB ---
    var stubToken: String?    // Kalau ada yang minta token, kasih ini
    
    // --- Bagian SPY ---
    var saveTokenCallCount = 0
    var savedTokens: [String: String] = [:] // Nyimpen token beneran di memori sementara
    var isClearAllCalled = false
    
    // MARK: - Protocol Implementation
    
    func saveToken(_ token: String, key: String) throws {
        saveTokenCallCount += 1
        savedTokens[key] = token
    }
    
    func getToken(key: String) -> String? {
        // Kalau stubToken diset manual (AuthManagerTest), pakai itu.
        // Kalau enggak, coba cari di savedTokens (RepositoryTest).
        return stubToken ?? savedTokens[key]
    }
    
    func clearAll() throws {
        isClearAllCalled = true
        savedTokens.removeAll()
        stubToken = nil
    }
    
    // Helper tambahan (Opsional)
    func saveAccessAndRefreshTokens(accessToken: String, refreshToken: String) throws {
        try saveToken(accessToken, key: "accessToken")
        try saveToken(refreshToken, key: "refreshToken")
    }
}
