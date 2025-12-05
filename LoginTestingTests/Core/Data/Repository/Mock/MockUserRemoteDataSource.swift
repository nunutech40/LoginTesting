//
//  MockUserRemoteDataSource.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 04/12/25.
//
import XCTest
import Combine
@testable import LoginTesting

class MockUserRemoteDataSource: UserDataSourceProtocol {
    
    // MARK: - 1. STUB (Hasil yang mau dikembalikan)
    // Kita pisah result untuk Login dan Profile biar gak tabrakan
    var loginResult: Result<AuthDataResponse, Error>?
    var getProfileResult: Result<UserProfileResponse, Error>?
    
    // MARK: - 2. SPY (Mata-mata Input)
    // Buat ngecek: "Apakah Repository ngirim data yg bener ke sini?"
    var lastLoginCredentials: LoginRequestBody?
    var isGetProfileCalled: Bool = false
    
    // MARK: - Login Implementation
    func login(credentials: LoginRequestBody) -> AnyPublisher<AuthDataResponse, Error> {
        // Tangkap inputnya (Spying)
        self.lastLoginCredentials = credentials
        
        if let result = loginResult {
            return result.publisher.eraseToAnyPublisher()
        }
        return Fail(error: NetworkError.unknown(NSError(domain: "MockLogin", code: -1))).eraseToAnyPublisher()
    }
    
    // MARK: - Get Profile Implementation
    func getProfile() -> AnyPublisher<UserProfileResponse, Error> {
        // Tandai kalau fungsi ini dipanggil
        self.isGetProfileCalled = true
        
        if let result = getProfileResult {
            return result.publisher.eraseToAnyPublisher()
        }
        return Fail(error: NetworkError.unknown(NSError(domain: "MockProfile", code: -1))).eraseToAnyPublisher()
    }
}
