//
//  HomeView.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 03/12/25.
//
import SwiftUI

struct HomeView: View {
    
    // 1. INJECT AUTH MANAGER
    // Kita ambil akses langsung ke Manager Global lewat Environment
    @EnvironmentObject var authManager: AuthenticationManager
    
    // Data user tetap dikirim dari parent (ContentView) agar View ini tidak perlu unwrap optional
    let user: UserModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                
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
                
                Spacer()
                
                Text("Content Dashboard Here")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            
            // 2. ICON SETTING DI POJOK KANAN ATAS
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Komponen MENU: Klik icon -> Muncul list opsi
                    Menu {
                        // Opsi Logout
                        Button(role: .destructive, action: {
                            // Panggil fungsi logout langsung di Manager
                            authManager.logout()
                        }) {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                        
                        // Bisa tambah opsi lain di sini, misal:
                        // Button("Edit Profile") { ... }
                        
                    } label: {
                        Image(systemName: "gearshape.fill") // Icon Setting
                            .imageScale(.large)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
}

// Preview Helper
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let dummyUser = UserModel(id: "1", username: "hantesa", email: "test@mail.com", fullname: "Hantes A")
        HomeView(user: dummyUser)
            .environmentObject(AuthenticationManager()) // Inject dummy env
    }
}
