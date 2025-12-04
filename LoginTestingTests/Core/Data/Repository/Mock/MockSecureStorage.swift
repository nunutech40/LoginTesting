//
//  MockSecureStorage.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 04/12/25.
//

import XCTest
@testable import LoginTesting

// Disebut "Spy" karena kita memata-matai apakah fungsinya dipanggil.
class MockSecureStorage: SecureStorageProtocol {
    var saveTokenCallCount = 0
    var savedTokens: [String: String] = [:] // Key : Token
    
    func saveToken(_ token: String, key: String) throws {
        saveTokenCallCount += 1
        savedTokens[key] = token
    }
    
    func getToken(key: String) -> String? { return nil }
    func clearAll() throws {}
}
