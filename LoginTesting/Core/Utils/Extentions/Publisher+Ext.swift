//
//  Publisher+Ext.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 03/12/25.
//
import Combine
import Foundation

// [FIX] Pindahkan Struct ini keluar dari closure/function generic
private struct ErrorMeta: Decodable {
    let meta: Meta
    struct Meta: Decodable {
        let message: String
    }
}

extension Publisher where Output == Data, Failure == NetworkError {
    
    func parseAPIResponse<T: Decodable>(type: T.Type) -> AnyPublisher<T, Error> {
        return self
        // 1. Decode ke Wrapper Standard (Happy Path 200)
            .decode(type: ServerResponse<T>.self, decoder: JSONDecoder())
        
        // 2. Validasi Logic Bisnis (Meta di 200 OK)
            .tryMap { wrapper in
                // Cek Kode Meta via Mapper
                if let businessError = HTTPErrorMapper.map(statusCode: wrapper.meta.code) {
                    throw businessError
                }
                
                // Cek Status String
                if wrapper.meta.status != "success" {
                    if !wrapper.meta.message.isEmpty {
                        throw AuthError.custom(wrapper.meta.message)
                    }
                    throw AuthError.unknown
                }
                
                guard let validData = wrapper.data else {
                    throw NetworkError.invalidResponse
                }
                return validData
            }
        
        // 3. MAPPING ERROR TERPUSAT (Sad Path 4xx/5xx)
            .mapError { error in
                
                // A. Handle Error Server (Alamofire .failure)
                if let netError = error as? NetworkError,
                   case .serverError(let code, let data) = netError {
                    
                    // [BARU] CEK ISI BODY ERROR DULU!
                    // Sebelum nyerah ke Mapper, coba intip apakah ada pesan custom di JSON-nya?
                    if let responseData = data {
                        // Kalau berhasil decode JSON Error -> Ambil pesannya!
                        // Menggunakan struct ErrorMeta yang sudah dipindah ke luar
                        if let errorResponse = try? JSONDecoder().decode(ErrorMeta.self, from: responseData) {
                            return AuthError.custom(errorResponse.meta.message)
                        }
                    }
                    
                    // Kalau gak ada pesan custom, baru pake Mapper (401 -> InvalidCreds)
                    if let authError = HTTPErrorMapper.map(statusCode: code) {
                        return authError
                    }
                    
                    // Fallback akhir
                    if code >= 500 { return AuthError.serverMaintenance }
                }
                
                // B. Handle Decoding Error
                if error is DecodingError {
                    return NetworkError.decodingError(error)
                }
                
                // C. Handle Transport/Internet
                if let netError = error as? NetworkError, case .transportError = netError {
                    // Opsional: Ubah ke AuthError kalau perlu
                    // return AuthError.noInternet
                    return netError
                }
                
                return error
            }
            .eraseToAnyPublisher()
    }
}
