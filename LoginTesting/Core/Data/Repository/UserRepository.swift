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
}
