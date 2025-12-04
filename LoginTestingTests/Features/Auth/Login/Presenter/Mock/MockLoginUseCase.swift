//
//  MockLoginUseCase.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 04/12/25.
//
import XCTest
import Combine
@testable import LoginTesting

// MARK: - 1. MOCK USECASE
// Kita butuh UseCase palsu yang bisa kita atur hasilnya (Sukses/Gagal)
class MockLoginUseCase: LoginUseCase {
    
    // Variabel pengatur hasil (Stub)
    var result: Result<UserModel, Error>?
    
    func login(request: LoginRequestBody) -> AnyPublisher<UserModel, Error> {
        if let result = result {
            // Simulasikan delay sedikit biar terasa async (optional)
            return result.publisher
                // .delay(for: .milliseconds(10), scheduler: RunLoop.main) // Opsional
                .eraseToAnyPublisher()
        }
        return Empty().eraseToAnyPublisher()
    }
}
