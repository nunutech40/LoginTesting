//
//  LoginPresenter.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 03/12/25.
//

import SwiftUI
import Combine

class LoginPresenter: ObservableObject {
    
    // 1. Dependency
    private let loginUseCase: LoginUseCase
    private var cancellables = Set<AnyCancellable>()
    
    // 2. State untuk UI (View tinggal observe ini)
    @Published var isLoading: Bool = false
    @Published var isError: Bool = false
    @Published var errorMessage: String = ""
    @Published var isLoggedIn: Bool = false // Trigger pindah halaman ke Home
    @Published var user: UserModel?         // Data user (opsional disimpan di sini)
    
    // 3. Init
    init(loginUseCase: LoginUseCase) {
        self.loginUseCase = loginUseCase
    }
    
    // 4. Fungsi Login
    func login(username: String, pass: String) {
        
        // Reset State awal
        self.isLoading = true
        self.isError = false
        self.errorMessage = ""
        
        // Buat Request Body
        let request = LoginRequestBody(
            username: username,
            password: pass,
            fcmToken: "dummy_fcm"
        )
        
        print("cek request: \(request)")
        // Eksekusi
        loginUseCase.login(request: request)
            .receive(on: RunLoop.main) // Wajib Main Thread
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                // Apapun hasilnya, loading kelar
                self.isLoading = false
                
                switch completion {
                case .failure(let error):
                    // Set Error State -> View otomatis munculin Alert
                    self.errorMessage = error.localizedDescription
                    self.isError = true
                    print("cek error: \(error.localizedDescription)")
                case .finished:
                    break
                }
                
            }, receiveValue: { [weak self] user in
                guard let self = self else { return }
                
                // Set Sukses State -> View otomatis pindah ke Home
                self.user = user
                self.isLoggedIn = true
            })
            .store(in: &cancellables)
    }
}
