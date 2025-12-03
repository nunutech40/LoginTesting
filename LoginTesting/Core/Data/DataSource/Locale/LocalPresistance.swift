//
//  LocalPresistance.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 03/12/25.
//

import Foundation

// MARK: - Protocol (Supaya bisa di-mock di Unit Test)
protocol LocalPersistenceProtocol {
    func save<T: Codable>(_ value: T, key: String)
    func get<T: Codable>(key: String) -> T?
    func remove(key: String)
    func has(key: String) -> Bool
}

// MARK: - Implementation
final class LocalPersistence: LocalPersistenceProtocol {
    
    private let defaults = UserDefaults.standard
    
    // Simpan APA SAJA (Asal Codable)
    // Bisa Struct User, bisa Bool (Toggle), bisa Array, dll.
    func save<T: Codable>(_ value: T, key: String) {
        if let encoded = try? JSONEncoder().encode(value) {
            defaults.set(encoded, forKey: key)
        }
    }
    
    // Ambil APA SAJA
    // Nanti dipanggil: let user: UserModel? = storage.get(key: ...)
    // Atau: let isDarkMode: Bool? = storage.get(key: ...)
    func get<T: Codable>(key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    // Hapus
    func remove(key: String) {
        defaults.removeObject(forKey: key)
    }
    
    // Cek keberadaan data
    func has(key: String) -> Bool {
        return defaults.object(forKey: key) != nil
    }
}
