//
//  HTTPErrorMapper.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 03/12/25.
//

import Foundation

struct HTTPErrorMapper {
    
    static func map(statusCode: Int) -> Error? {
        switch statusCode {
        case 200...299:
            return nil // Tidak ada error
            
        case 400, 401:
            return AuthError.invalidCredentials
            
        case 403:
            return AuthError.accountBlocked
            
        case 500...599:
            return AuthError.serverMaintenance
            
        default:
            // Kembalikan sebagai NetworkError biasa kalau tidak terdefinisi
            return nil
        }
    }
}
