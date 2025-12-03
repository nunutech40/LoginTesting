//
//  CustomError.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 03/12/25.
//
import Foundation

enum NetworkError: Error, LocalizedError {
    case transportError(Error)                     // Masalah koneksi/internet/Alamofire
    case serverError(statusCode: Int, data: Data?) // Error HTTP (400-599)
    case invalidResponse                           // Response kosong atau bukan HTTP
    case invalidURL                                // URL string tidak valid
    case decodingError(Error)                      // JSON tidak sesuai dengan Struct
    case unknown(Error)                            // Error lain yang tak terduga

    var errorDescription: String? {
        switch self {
        case .transportError(let error):
            // Tampilkan pesan asli dari Alamofire/URLSession (misal: "Internet offline")
            return "Masalah Koneksi: \(error.localizedDescription)"

        case .serverError(let statusCode, _):
            // Tampilkan kode status server
            return "Terjadi kesalahan server dengan kode: \(statusCode)."

        case .invalidResponse:
            return "Respon dari server tidak valid atau kosong."

        case .invalidURL:
            return "URL tujuan tidak valid."

        case .decodingError(let error):
            // Pesan ini sangat berguna saat development
            return "Gagal memproses data (Decoding): \(error.localizedDescription)"

        case .unknown(let error):
            return "Terjadi kesalahan yang tidak diketahui: \(error.localizedDescription)"
        }
    }
}
