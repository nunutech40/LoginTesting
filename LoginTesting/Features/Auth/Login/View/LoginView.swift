//
//  LoginView.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 03/12/25.
//

import SwiftUI

struct LoginView: View {
    
    @StateObject var presenter: LoginPresenter
    
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    
    // State Validasi Lokal (Untuk feedback UI langsung)
    var isEmailValid: Bool { email.isValidEmail }
    var isPasswordValid: Bool { password.isValidPassword }
    var canSubmit: Bool { isEmailValid && isPasswordValid && !presenter.isLoading }
    
//    var canSubmit: Bool {
//        // Bypass validasi: Tombol nyala asalkan input tidak kosong & tidak loading
//        !email.isEmpty && !password.isEmpty && !presenter.isLoading
//    }
    
    var body: some View {
        ZStack {
            backgroundLayer
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    headerSection
                    inputFormSection
                    loginButtonSection
                    footerSection
                }
                .padding(.vertical, 40)
            }
        }
        .alert(isPresented: $presenter.isError) {
            Alert(
                title: Text("Login Gagal"),
                message: Text(presenter.errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// MARK: - Subviews
extension LoginView {
    
    var backgroundLayer: some View {
        Color(UIColor.systemGroupedBackground)
            .ignoresSafeArea()
            .overlay(
                Color.clear.contentShape(Rectangle())
                    .onTapGesture { hideKeyboard() }
            )
    }
    
    var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)
            
            Text("Welcome Back")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Please sign in to your account")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    var inputFormSection: some View {
        VStack(spacing: 20) {
            
            // 1. INPUT EMAIL
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.gray)
                        .frame(width: 20)
                    
                    TextField("Email Address", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    // Indikator Validasi (Checkmark Hijau)
                    if !email.isEmpty {
                        Image(systemName: isEmailValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isEmailValid ? .green : .red)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // Pesan Error Email (Opsional)
                if !email.isEmpty && !isEmailValid {
                    Text("Format email tidak valid")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.leading, 12)
                }
            }
            
            // 2. INPUT PASSWORD
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray)
                        .frame(width: 20)
                    
                    if isPasswordVisible {
                        TextField("Password", text: $password)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    } else {
                        SecureField("Password", text: $password)
                            .textContentType(.password) // Penting buat autofill
                    }
                    
                    // Tombol Show/Hide
                    Button(action: { isPasswordVisible.toggle() }) {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // Pesan Error Password
                if !password.isEmpty && !isPasswordValid {
                    Text("Password minimal 8 karakter")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.leading, 12)
                }
            }
        }
        .padding(.horizontal)
    }
    
    var loginButtonSection: some View {
        Button(action: {
            hideKeyboard()
            presenter.login(username: email, pass: password)
        }) {
            HStack {
                if presenter.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.trailing, 5)
                }
                
                Text(presenter.isLoading ? "Masuk..." : "Login")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            // Warna tombol berubah kalau form belum valid
            .background(canSubmit ? Color.blue : Color.gray.opacity(0.5))
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(radius: canSubmit ? 5 : 0)
        }
        .disabled(!canSubmit) // Matikan tombol kalau tidak valid
        .padding(.horizontal)
    }
    
    var footerSection: some View {
        HStack {
            Text("Don't have an account?")
                .foregroundColor(.secondary)
            Button("Sign Up") { }
                .foregroundColor(.blue)
        }
    }
}


// Extension untuk menyembunyikan keyboard
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
