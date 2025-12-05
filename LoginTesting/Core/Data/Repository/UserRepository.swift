//
//  UserRepository.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 03/12/25.
//

import Foundation
import Combine

// MARK: - Protocol
protocol UserRepositoryProtocol {
    func login(credentials: LoginRequestBody) -> AnyPublisher<UserModel, Error>
    func getProfile() -> AnyPublisher<UserProfileModel, Error>
}

// MARK: - Implementation
final class UserRepository: UserRepositoryProtocol {
    
    // Injeksi Datasource
    private let remoteDataSource: UserDataSourceProtocol
    private let secureStorage: SecureStorageProtocol
    private let storage: LocalPersistenceProtocol
    
    // Key Constants
    private let accessTokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"
    
    init(remoteDataSource: UserDataSourceProtocol = UserRemoteDataSource(),
         secureStorage: SecureStorageProtocol = SecureStorage(),
         storage: LocalPersistenceProtocol = LocalPersistence()) {
        self.remoteDataSource = remoteDataSource
        self.secureStorage = secureStorage
        self.storage = storage
    }
    
    // MARK: - Login Function
    func login(credentials: LoginRequestBody) -> AnyPublisher<UserModel, Error> {
        
        // 1. Panggil API (Dapat AuthDataResponse yang ada tokennya)
        return remoteDataSource.login(credentials: credentials)
        
        // 2. SIDE EFFECT: Tahan token di sini, simpan ke Keychain
            .handleEvents(receiveOutput: { [weak self] response in
                guard let self = self else { return }
                
                do {
                    // Simpan Token ke Brankas (Keychain)
                    try self.secureStorage.saveToken(response.accessToken, key: self.accessTokenKey)
                    try self.secureStorage.saveToken(response.refreshToken, key: self.refreshTokenKey)
                } catch {
                    print("Gagal menyimpan token: \(error)")
                }
                
                // B. Simpan User Model ke UserDefaults (Cache Data) [BARU]
                let info = response.userInfo
                let userToSave = UserModel(
                    id: String(info.id),
                    username: info.username,
                    email: info.email,
                    fullname: info.fullname
                )
                
                // Panggil Generic Storage buat simpan
                self.storage.save(userToSave, key: StorageKeys.sessionUser)
            })
        
        // 3. MAPPING: Buang token, kembalikan data user bersih ke Interactor
            .map { response -> UserModel in
                let info = response.userInfo
                
                // Return Model UserIdentity (Tanpa Token)
                return UserModel(
                    id: String(info.id),
                    username: info.username,
                    email: info.email,
                    fullname: info.fullname
                )
            }
            .eraseToAnyPublisher()
    }
    
    func getProfile() -> AnyPublisher<UserProfileModel, Error> {
        
        // 1. Panggil DataSource
        // Karena lo pake parseAPIResponse, output di sini SUDAH 'UserProfileResponse' (DTO)
        // BUKAN ServerResponse lagi.
        return remoteDataSource.getProfile()
        
        // 2. MAPPING KE DOMAIN (DTO -> Model)
        // Gak perlu tryMap atau buka meta lagi. Langsung aja.
            .map { dtoResponse -> UserProfileModel in
                return dtoResponse.toDomain()
            }
        
        // 3. SIMPAN KE CACHE (Domain Model)
            .handleEvents(receiveOutput: { [weak self] domainModel in
                print("Network Sukses. Simpan ke Cache.")
                self?.storage.save(domainModel, key: StorageKeys.fullProfile)
            })
        
        // 4. FALLBACK KE CACHE (Kalau Error)
            .catch { [weak self] error -> AnyPublisher<UserProfileModel, Error> in
                print("Network Error: \(error). Cek Cache...")
                
                if let cachedData: UserProfileModel = self?.storage.get(key: StorageKeys.fullProfile) {
                    print("Pake Cache.")
                    return Just(cachedData)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                } else {
                    print("Cache Kosong.")
                    return Fail(error: error).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
}
