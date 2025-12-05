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
            
            // BERSIH! Gak perlu .mapError lagi di sini.
            // .parseAPIResponse() di extension sudah nge-handle:
            // 1. Validasi Sukses
            // 2. Baca Pesan Error Custom (422)
            // 3. Mapping Error Standard (401, 500, Offline)
            return client.request(router: router)
                .parseAPIResponse(type: AuthDataResponse.self)
            
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    // MARK: - Get Profile
    func getProfile() -> AnyPublisher<UserProfileResponse, Error> {
        
        let router = AppRouter.getProfile
        
        // BERSIH JUGA!
        return client.request(router: router)
            .parseAPIResponse(type: UserProfileResponse.self)
    }
}
