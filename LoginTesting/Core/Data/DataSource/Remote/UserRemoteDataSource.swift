//
//  UserRemoteDataSource.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 03/12/25.
//

import Foundation
import Combine
import Alamofire

struct LoginRequestBody: Encodable {
    let username: String
    let password: String
    let fcmToken: String
    
    enum CodingKeys: String, CodingKey {
        case username = "username"
        case password = "password"
        case fcmToken = "fcm_token"
    }
}

protocol UserDataSourceProtocol {
    // UBAH: Mengembalikan AuthData (Payload API)
    func login(credentials: LoginRequestBody) -> AnyPublisher<AuthDataResponse, Error>
    func getProfile() -> AnyPublisher<UserProfileResponse, Error>
}

final class UserRemoteDataSource: UserDataSourceProtocol {
    
    private let client: NetworkClient
    
    init(client: NetworkClient = APIClient()) {
        self.client = client
    }
    
    // MARK: - Login Implementation
    func login(credentials: LoginRequestBody) -> AnyPublisher<AuthDataResponse, Error> {
        
        do {
            guard let parameters = try credentials.asDictionary() else {
                throw NetworkError.invalidResponse
            }
            
            let router = AppRouter.login(credentials: parameters)
            
            // LIHAT INI: Cukup panggil client, lalu validasi. Selesai.
            return client.request(router: router)
                .parseAPIResponse(type: AuthDataResponse.self)
            
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    // MARK: - Get Profile (BARU)
    func getProfile() -> AnyPublisher<UserProfileResponse, Error> {
        
        // Asumsi: AppRouter.getProfile sudah diset (Method GET, isAuthRequired = true)
        let router = AppRouter.getProfile
        
        // Panggil API -> Parse ke UserProfileResponse
        // Token otomatis di-inject oleh APIClient karena router.isAuthRequired = true
        return client.request(router: router)
            .parseAPIResponse(type: UserProfileResponse.self)
    }
}
