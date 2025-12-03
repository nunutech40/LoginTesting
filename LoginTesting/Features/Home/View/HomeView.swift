//
//  HomeView.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 03/12/25.
//

import SwiftUI

struct HomeView: View {
    
    let user: UserModel // Menerima data user dari Login
    
    // Closure untuk Logout (nanti dilempar ke Root buat ganti halaman)
    var onLogout: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.green)
                
                Text("Selamat Datang!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(user.fullname)
                    .font(.headline)
                
                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: {
                    onLogout() // Panggil aksi logout
                }) {
                    Text("Logout")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Home")
        }
    }
}
