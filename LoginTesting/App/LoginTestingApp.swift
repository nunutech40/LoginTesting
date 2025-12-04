//
//  LoginTestingApp.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 03/12/25.
//

import SwiftUI

@main
struct LoginTestingApp: App {
    
    // 1. SINGLE SOURCE OF TRUTH
    // @StateObject artinya object ini milik App, dan akan hidup selama aplikasi jalan.
    // Injection.shared... itu cuma helper buat bikin objectnya biar rapi.
    @StateObject var authManager = Injection.shared.provideAuthManager()
    
    var body: some Scene {
        WindowGroup {
            // 2. Root View
            ContentView()
                // 3. Inject ke Environment
                // Supaya ContentView dan semua anaknya bisa akses data user login
                .environmentObject(authManager)
        }
    }
}
