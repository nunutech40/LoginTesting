//
//  AuthError.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 03/12/25.
//

import Foundation


enum AuthError: Error, LocalizedError, Equatable {
    case invalidCredentials // 400, 401
    case accountBlocked     // 403
    case serverMaintenance  // 500
    case custom(String)     // Error dengan pesan khusus dari server
    case unknown            // Error antah berantah
    
    var errorDescription: String? {
        // ... (kode errorDescription tetap sama, tidak perlu diubah)
        switch self {
        case .invalidCredentials:
            return "Username atau Password salah."
        case .accountBlocked:
            return "Akun Anda telah diblokir. Silakan hubungi admin."
        case .serverMaintenance:
            return "Server sedang dalam perbaikan. Coba lagi nanti."
        case .custom(let message):
            return message
        case .unknown:
            return "Terjadi kesalahan yang tidak diketahui."
        }
    }
}
