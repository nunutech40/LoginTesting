//
//  LoginResponse.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 03/12/25.
//

import Foundation

struct AuthDataResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let userInfo: UserInfo // Struct UserInfo juga harus didefinisikan
    
    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
        case accessToken = "access_token"
        case tokenType = "token_type"
        case userInfo = "data" // Mengakses lapisan "data" kedua
    }
}

struct UserInfo: Decodable {
    let id: Int
    let partnerId: Int
    let partnerNo: String
    let username: String
    let fullname: String
    let email: String
    
    enum CodingKeys: String, CodingKey {
        case id, username, fullname, email
        case partnerId = "partner_id"
        case partnerNo = "partner_no"
    }
}
