//
//  Publisher+Ext.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 03/12/25.
//

import Combine
import Foundation

extension Publisher where Output == Data, Failure == NetworkError {
    
    // Fungsi ini khusus buat API kantor kamu yang punya format { meta, data }
    func parseAPIResponse<T: Decodable>(type: T.Type) -> AnyPublisher<T, Error> {
        return self
        // 1. Decode ke Wrapper Standard (ServerResponse)
            .decode(type: ServerResponse<T>.self, decoder: JSONDecoder())
        
        // 2. Validasi Logic Bisnis (Meta)
            .tryMap { wrapper in
                // Cek Kode Meta
                if let businessError = HTTPErrorMapper.map(statusCode: wrapper.meta.code) {
                    throw businessError
                }
                
                // Cek Status String
                if wrapper.meta.status != "success" {
                    
                    // OPSI 1: Kalau server ngasih pesan error di meta, pakai itu
                    if !wrapper.meta.message.isEmpty {
                        throw AuthError.custom(wrapper.meta.message)
                    }
                    
                    // OPSI 2: Kalau message kosong tapi status error, lempar unknown atau invalid
                    throw AuthError.unknown
                }
                
                // Kalau meta sukses, data HARUS ada. Kalau nil, berarti aneh.
                guard let validData = wrapper.data else {
                    throw NetworkError.invalidResponse // Atau error "Data Kosong"
                }
                
                return validData
            }
        
        // 3. Mapping Error Terpusat
            .mapError { error in
                // A. Error dari APIClient (401, 500, Offline)
                if let netError = error as? NetworkError {
                    if case .serverError(let code, _) = netError {
                        // Terjemahkan error HTTP ke Error Bisnis
                        if let authError = HTTPErrorMapper.map(statusCode: code) {
                            return authError
                        }
                    }
                    return netError
                }
                
                // B. Error Decoding
                if error is DecodingError {
                    return NetworkError.decodingError(error)
                }
                
                // C. Error Bisnis (AuthError)
                return error
            }
            .eraseToAnyPublisher()
    }
}
