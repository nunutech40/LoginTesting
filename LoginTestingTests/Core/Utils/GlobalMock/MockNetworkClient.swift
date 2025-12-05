//
//  MockNetworkClient.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 03/12/25.
//

import XCTest
import Combine
@testable import LoginTesting // Ganti dengan nama Project kamu


class MockNetworkClient: NetworkClient {
    
    // 1. Hasil Return (STUB) - Buat nentuin sukses/gagal
    var result: Result<Data, NetworkError>?
    
    // 2. Router Terakhir (SPY) - Buat ngintip parameter request [BARU]
    var lastRouterPassed: AppRouter?
    
    func request(router: AppRouter) -> AnyPublisher<Data, NetworkError> {
        // TANGKAP router yang dikirim user, simpan di variabel
        self.lastRouterPassed = router
        
        guard let result = result else {
            return Fail(error: NetworkError.unknown(NSError(domain: "", code: -1))).eraseToAnyPublisher()
        }
        
        return result.publisher.eraseToAnyPublisher()
    }
}
