//
//  HomeView.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 03/12/25.
//

import SwiftUI

struct HomeView: View {
    
    // 1. INJECT AUTH MANAGER (Tetap ada buat logout)
    @EnvironmentObject var authManager: AuthenticationManager
    
    // 2. INJECT PRESENTER (Buat data Profile)
    @ObservedObject var presenter: HomePresenter
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                
                // Cek apakah data user sudah ada
                if let user = presenter.user {
                    // Profile Section
                    VStack(spacing: 15) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.green)
                            .shadow(radius: 5)
                        
                        VStack(spacing: 5) {
                            Text("Selamat Datang,")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(user.fullname)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("@\(user.username)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 40)
                    
                } else if presenter.isLoading {
                    // Tampilan Loading
                    ProgressView("Loading Profile...")
                } else {
                    // Tampilan Error atau Kosong
                    Text("Gagal memuat profil")
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                Text("Content Dashboard Here")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            
            // PANGGIL LOAD PROFILE SAAT VIEW MUNCUL
            .onAppear {
                presenter.loadProfile()
            }
            
            // 3. ICON SETTING
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive, action: {
                            authManager.logout()
                        }) {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .imageScale(.large)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
}

// Preview Helper Updated
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        // Setup Dummy Dependency manual buat Preview
        let repo = UserRepository() // Asumsi ada dummy/real repo
        let useCase = HomeInteractor(userRepository: repo)
        let presenter = HomePresenter(interactor: useCase)
        
        HomeView(presenter: presenter)
            .environmentObject(AuthenticationManager())
    }
}
