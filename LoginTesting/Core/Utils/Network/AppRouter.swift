//
//  AppRouter.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 03/12/25.
//

import Foundation
import Alamofire

// Catatan: Pastikan Anda memiliki 'APIConstants' di scope global atau file terpisah.
// struct APIConstants { static let baseURL = "..." }

// MARK: - Protokol Dasar
protocol APIEndpoint: URLRequestConvertible {
    var method: HTTPMethod { get }
    var path: String { get }
    var parameters: Parameters? { get }
    var encoding: ParameterEncoding { get }
    var isAuthRequired: Bool { get }
}

// MARK: - Endpoint Enum yang Disesuaikan
enum AppRouter: APIEndpoint {
    
    // GET Requests
    case getCategories
    case searchProducts(query: String, limit: Int) // OK: Menangani query dinamis
    
    // POST Requests
    case login(credentials: [String: String])
    case getProfile
    case submitOrder(data: [String: String])
    
    // MARK: - Implementasi Protokol
    
    var method: HTTPMethod {
        switch self {
        case .getCategories, .searchProducts, .getProfile:
            return .get
        case .login, .submitOrder: // Tambahkan semua POST case di sini
            return .post
        }
    }
    
    // Penentuan Path
    var path: String {
        switch self {
        case .getCategories:
            return "/categories"
        case .searchProducts:
            return "/products/search"
        case .login:
            return "/api/v1/auth/login"
        case .submitOrder:
            return "/orders"
        case .getProfile:
            return "/api/v1/auth/profile"
        }
    }
    
    // Penentuan Parameter (Body/Query)
    var parameters: Parameters? {
        switch self {
        case .searchProducts(let query, let limit):
            return ["q": query, "limit": limit] // Query Parameters (GET)
        case .login(let credentials):
            return credentials // JSON Body Data (POST)
        case .submitOrder(let data):
            return data // JSON Body Data (POST)
        case .getCategories, .getProfile:
            return nil // GET tanpa parameter body/query
        }
    }
    
    // Penentuan Encoding
    var encoding: ParameterEncoding {
        switch self {
        case .searchProducts:
            return URLEncoding.default // GET menggunakan Query Encoding
        case .login, .submitOrder:
            return JSONEncoding.default // POST menggunakan JSON Body Encoding
        default:
            return URLEncoding.default // Default untuk GET/kasus tanpa parameter
        }
    }
    
    // MARK: - Implementasi URLRequestConvertible
    func asURLRequest() throws -> URLRequest {
        
        // Asumsi 'APIConstants' sudah tersedia
        let url = try APIConstants.baseURL.asURL()
        let finalURL = url.appendingPathComponent(path)
        
        // Header diset ke nil karena akan ditambahkan di APIClient
        var request = try URLRequest(url: finalURL, method: method, headers: nil)
        
        // Encoding Parameters (Alamofire akan merakit URL/Body sesuai 'encoding')
        request = try encoding.encode(request, with: parameters)
        
        return request
    }
    
    
}

extension AppRouter {
    var isAuthRequired: Bool {
        switch self {
        case .login:
            return false // TIDAK perlu token untuk login
        case .getCategories, .searchProducts, .getProfile, .submitOrder:
            return true // Semua endpoint ini memerlukan token
        }
    }
}
