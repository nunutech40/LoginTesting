//
//  APIClient.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 03/12/25.
//

import Foundation
import Alamofire
import Combine

// MARK: - Protokol Klien Network
protocol NetworkClient {
    func request(router: AppRouter) -> AnyPublisher<Data, NetworkError>
}

// ASUMSI: SecureStorageProtocol sudah didefinisikan (mengandung getToken(key: String))

// MARK: - Implementasi Klien Network
final class APIClient: NetworkClient {
    
    // VARIABEL BARU: Injeksi Storage (Dependency Injection)
    private let tokenStorage: SecureStorageProtocol
    
    // Key yang digunakan di SecureStorage untuk Access Token
    private let accessTokenKey = "accessToken"
    
    // BLOK INIT BARU: Untuk menginisialisasi client dan storage
    init(tokenStorage: SecureStorageProtocol = SecureStorage()) {
        self.tokenStorage = tokenStorage
    }
    
    // PROPERTI BARU: Mengambil token dari Keychain secara dinamis
    private var authToken: String? {
        // Panggil fungsi getToken dari SecureStorage (Keychain)
        return self.tokenStorage.getToken(key: accessTokenKey)
    }
    
    // KOSONGKAN IMPLEMENTASI di sini.
    // Kita akan implementasikan 'request' menggunakan extension di bawah agar lebih rapi.
}

// MARK: - Extension untuk Implementasi Fungsi
extension APIClient {
    
    func request(router: AppRouter) -> AnyPublisher<Data, NetworkError> {
        
        return Future<Data, NetworkError> { promise in
            
            do {
                // 1. Dapatkan URLRequest yang sudah di-encode parameternya dari AppRouter
                var urlRequest = try router.asURLRequest()
                
                // 2. TANGGUNG JAWAB APIClient: Menambahkan Global Headers
                
                // Header Default: Content-Type JSON
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                // Header Autentikasi (Bearer Token)
                // HANYA DITAMBAHKAN JIKA router.isAuthRequired = true
                if router.isAuthRequired, let token = self.authToken {
                    urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }
                
                // 3. Panggil Alamofire dengan URLRequest yang sudah dimodifikasi
                AF.request(urlRequest)
                    .response { response in
                        
                        // A. Cek Error Transport
                        if let afError = response.error {
                            promise(.failure(.transportError(afError)))
                            return
                        }
                        
                        // B. Cek Validitas Response
                        guard let httpResponse = response.response else {
                            promise(.failure(.invalidResponse))
                            return
                        }
                        
                        let statusCode = httpResponse.statusCode
                        
                        // C. Status Sukses (200-299)
                        if 200...299 ~= statusCode {
                            guard let data = response.data else {
                                promise(.failure(.invalidResponse))
                                return
                            }
                            promise(.success(data))
                        } else {
                            // D. Status Error Server (4xx, 5xx)
                            promise(.failure(.serverError(statusCode: statusCode, data: response.data)))
                        }
                    }
            } catch {
                // Handle error dari asURLRequest()
                promise(.failure(.invalidURL))
            }
        }
        .eraseToAnyPublisher()
    }
}
