//
//  String+Ext.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 03/12/25.
//
import Foundation

// asURL -> used in network layer
extension String {
    func asURL() throws -> URL {
        guard let url = URL(string: self) else {
            throw URLError(.badURL)
        }
        return url
    }
}

// -> validation
extension String {
    
    // Validasi Email menggunakan Regex
    var isValidEmail: Bool {
        // Regex standar untuk email
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
    
    // Validasi Username (Contoh: Minimal 4 karakter, huruf/angka)
    var isValidUsername: Bool {
        return self.count >= 4 && !self.contains(" ")
    }
    
    // Validasi Password (Contoh: Minimal 8 karakter)
    var isValidPassword: Bool {
        return self.count >= 8
    }
}
