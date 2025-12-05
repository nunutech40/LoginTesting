//
//  Injection.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 03/12/25.
//

import Foundation

final class Injection: NSObject {
    
    // Singleton untuk Injection itu sendiri
    static let shared = Injection()
    
    // MARK: - 1. Provide Repositories (Data Layer)
    
    func provideUserRepository() -> UserRepositoryProtocol {
        // A. Siapkan Tools
        let secureStorage = SecureStorage()
        let localStorage = LocalPersistence()
        
        // B. Siapkan API Client (Network Layer)
        // APIClient butuh secureStorage buat baca token otomatis
        let apiClient = APIClient(tokenStorage: secureStorage)
        
        // C. Siapkan Datasource (Data Layer)
        let remoteDataSource = UserRemoteDataSource(client: apiClient)
        
        // D. Rakit Repository
        return UserRepository(
            remoteDataSource: remoteDataSource,
            secureStorage: secureStorage,
            storage: localStorage
        )
    }
    
    // MARK: - 2. Provide UseCases (Domain Layer)
    
    func provideLoginUseCase() -> LoginUseCase {
        // Minta Repository dari fungsi di atas
        let repository = provideUserRepository()
        
        // Rakit Interactor
        return LoginInteractor(userRepository: repository)
    }
    
    // Nanti kalau ada fitur lain, tambah di sini:
    // func provideProfileUseCase() -> ProfileUseCase { ... }
    
    // [BARU] Tambahan buat Home
    func provideHomeUseCase() -> HomeUseCase {
        let repository = provideUserRepository()
        return HomeInteractor(userRepository: repository)
    }
    
    // MARK: - 3. Provide Global State (App Layer)
    
    // Ini khusus buat di Root (LoginTestingApp)
    func provideAuthManager() -> AuthenticationManager {
        let secureStorage = SecureStorage()
        let localStorage = LocalPersistence()
        
        return AuthenticationManager(
            secureStorage: secureStorage,
            storage: localStorage
        )
    }
}
