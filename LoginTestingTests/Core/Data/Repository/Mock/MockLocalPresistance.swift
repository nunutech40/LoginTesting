//
//  MockLocalPresistance.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 04/12/25.
//

import XCTest
@testable import LoginTesting

// MARK: - 1. SUPER MOCK LOCAL PERSISTENCE
// Mock ini bisa:
// a. Disuruh nyatet save (Spy) -> Buat Repository Test
// b. Disuruh balikin data palsu (Stub) -> Buat AuthManager Test
// c. Disuruh nyatet remove (Spy) -> Buat AuthManager Test

class MockLocalPersistence: LocalPersistenceProtocol {
    
    // --- Bagian STUB (Buat ngatur Return Value) ---
    var stubObject: Any?      // Kalau ada yang minta get(), kasih ini
    
    // --- Bagian SPY (Buat Nyatet) ---
    var saveCallCount = 0     // Berapa kali save dipanggil?
    var savedObject: Any?     // Apa yang terakhir disimpan?
    var isRemoveCalled = false // Apakah remove dipanggil?
    
    // MARK: - Protocol Implementation
    
    func save<T: Codable>(_ value: T, key: String) {
        saveCallCount += 1
        savedObject = value
    }
    
    func get<T: Codable>(key: String) -> T? {
        // Balikin data palsu yang sudah disiapkan di 'stubObject'
        return stubObject as? T
    }
    
    func remove(key: String) {
        isRemoveCalled = true
    }
    
    func has(key: String) -> Bool {
        return false // Default false, atau tambah stub boolean kalau butuh
    }
}
