//
//  MockLocalPresistance.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 04/12/25.
//

import XCTest
@testable import LoginTesting

// C. Mock Local Persistence (Spy)
class MockLocalPersistence: LocalPersistenceProtocol {
    var saveCallCount = 0
    var savedObject: Any?
    
    func save<T: Codable>(_ value: T, key: String) {
        saveCallCount += 1
        savedObject = value
    }
    
    func get<T: Codable>(key: String) -> T? { return nil }
    func remove(key: String) {}
    func has(key: String) -> Bool { return false }
}
