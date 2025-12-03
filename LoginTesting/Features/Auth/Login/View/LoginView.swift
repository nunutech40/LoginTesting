//
//  LoginView.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 03/12/25.
//
import SwiftUI

struct LoginView: View {
    
    // MARK: - Properties
    @StateObject var presenter: LoginPresenter
    
    @State private var username = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // 1. Layer Paling Bawah: Background & Gesture Handler
            backgroundLayer
            
            // 2. Layer Konten Utama
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
        // 3. Handle Alert Error
        .alert(isPresented: $presenter.isError) {
            Alert(
                title: Text("Login Gagal"),
                message: Text(presenter.errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// MARK: - Subviews (Abstraksi)
extension LoginView {
    
    // 1. Background Layer
    // Kita pisah gesture ini agar tidak mengganggu tombol Login
    var backgroundLayer: some View {
        Color(UIColor.systemGroupedBackground)
            .ignoresSafeArea()
            .overlay(
                // Invisible layer untuk menangkap tap di area kosong
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }
            )
    }
    
    // 2. Header (Logo & Title)
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
            
            Text("Please sign in to continue")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // 3. Input Form
    var inputFormSection: some View {
        VStack(spacing: 20) {
            // Input Username
            inputField(
                icon: "person.fill",
                placeholder: "Username",
                text: $username
            )
            
            // Input Password
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.gray)
                
                if isPasswordVisible {
                    TextField("Password", text: $password)
                } else {
                    SecureField("Password", text: $password)
                }
                
                Button(action: { isPasswordVisible.toggle() }) {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .padding(.horizontal)
    }
    
    // 4. Tombol Login
    var loginButtonSection: some View {
        Button(action: {
            hideKeyboard()
            presenter.login(username: username, pass: password)
        }) {
            HStack {
                if presenter.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.trailing, 5)
                }
                
                Text(presenter.isLoading ? "Signing In..." : "Login")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isValidForm ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(radius: 5)
        }
        .disabled(presenter.isLoading || !isValidForm)
        .padding(.horizontal)
    }
    
    // 5. Footer
    var footerSection: some View {
        HStack {
            Text("Don't have an account?")
                .foregroundColor(.secondary)
            Button("Sign Up") {
                // Action Sign Up
            }
            .foregroundColor(.blue)
        }
    }
    
    // Helper untuk Input Field biasa
    func inputField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
            TextField(placeholder, text: text)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // Logic Validasi
    var isValidForm: Bool {
        return !username.isEmpty && !password.isEmpty
    }
}


// Extension untuk menyembunyikan keyboard
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
