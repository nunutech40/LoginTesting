//
//  MockNetworkClient.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 03/12/25.
//

import XCTest
import Combine
@testable import LoginTesting // Ganti dengan nama Project kamu

// MARK: - MOCK Network Client
class MockNetworkClient: NetworkClient {
    
    // Kita bisa atur hasil return-nya mau Sukses (Data) atau Gagal (Error)
    var result: Result<Data, NetworkError>?
    
    func request(router: AppRouter) -> AnyPublisher<Data, NetworkError> {
        guard let result = result else {
            // Default kalau lupa set result
            return Fail(error: NetworkError.unknown(NSError(domain: "", code: -1))).eraseToAnyPublisher()
        }
        
        return result.publisher.eraseToAnyPublisher()
    }
}
