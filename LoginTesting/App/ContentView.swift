//
//  ContentView.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 03/12/25.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        Group {
            // A. KONDISI: SEDANG MEMUAT (Cek Token di Awal)
            if authManager.isCheckingAuth {
                
                splashView
                    .transition(.opacity)
                
                // B. KONDISI: SUDAH LOGIN
            } else if authManager.isAuthenticated, let user = authManager.currentUser {
                // Panggil Factory Function buat Home
                createHomeModule()
                    .transition(.opacity)
            } else {
                
                // Rakit & Tampilkan Module Login
                createLoginModule()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        // Animasi halus saat status berubah (misal: dari Splash -> Home)
        .animation(.easeInOut, value: authManager.isCheckingAuth)
        .animation(.easeInOut, value: authManager.isAuthenticated)
    }
}

// MARK: - Subviews & Assembly Helper
extension ContentView {
    
    // 1. Tampilan Splash Screen Sederhana
    var splashView: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "lock.shield.fill") // Ganti dengan Logo App
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                
                ProgressView() // Spinner loading
            }
        }
    }
    
    func createLoginModule() -> some View {
        
        let loginUseCase = Injection.shared.provideLoginUseCase()
        
        let presenter = LoginPresenter(loginUseCase: loginUseCase)
        
        return LoginView(presenter: presenter)
        // Listener: Mendengarkan perubahan state 'isLoggedIn' di Presenter
            .onReceive(presenter.$isLoggedIn) { isLoggedIn in
                if isLoggedIn, let user = presenter.user {
                    // Jika Presenter bilang sukses, lapor ke AuthManager (Root)
                    // Ini akan memicu ContentView me-refresh diri dan pindah ke HomeView
                    authManager.loginSuccess(user: user)
                }
            }
    }
    
    // [BARU] RAKIT HOME MODULE
    func createHomeModule() -> some View {
        // 1. Ambil UseCase dari Injection
        let homeUseCase = Injection.shared.provideHomeUseCase()
        
        // 2. Pasang ke Presenter
        let presenter = HomePresenter(interactor: homeUseCase)
        
        // 3. Pasang ke View
        return HomeView(presenter: presenter)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        // Mocking environment object untuk preview
        let mockAuth = AuthenticationManager()
        // Kamu bisa set mockAuth.isAuthenticated = true buat ngetes tampilan Home
        
        return ContentView()
            .environmentObject(mockAuth)
    }
}
#Preview {
    ContentView()
}
