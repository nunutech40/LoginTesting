//
//  AuthenticationManager.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 03/12/25.
//

import Foundation
import Combine

class AuthenticationManager: ObservableObject {
    
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: UserModel?
    @Published var isCheckingAuth: Bool = true
    
    private let secureStorage: SecureStorageProtocol
    private let storage: LocalPersistenceProtocol // Tambahkan ini
    
    // Key yang sama dengan di Repository
    private let userSessionKey = "kSessionUser"
    
    init(secureStorage: SecureStorageProtocol = SecureStorage(),
         storage: LocalPersistenceProtocol = LocalPersistence()) {
        self.secureStorage = secureStorage
        self.storage = storage
        
        checkLoginStatus()
    }
    
    func checkLoginStatus() {
        // 1. Cek Token
        if let token = secureStorage.getToken(key: "accessToken"), !token.isEmpty {
            // 2. Cek User Cache
            if let cachedUser: UserModel = storage.get(key: userSessionKey) {
                self.currentUser = cachedUser
                self.isAuthenticated = true
            } else {
                // Ada token tapi data user hilang? (Kasus aneh, anggap logout atau fetch ulang)
                self.isAuthenticated = false
            }
        } else {
            self.isAuthenticated = false
        }
        self.isCheckingAuth = false
    }
    
    func loginSuccess(user: UserModel) {
        self.currentUser = user
        self.isAuthenticated = true
    }
    
    func logout() {
        try? secureStorage.clearAll()
        storage.remove(key: userSessionKey)
        
        self.isAuthenticated = false
        self.currentUser = nil
    }
}
