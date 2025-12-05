//
//  MetaResponse.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 03/12/25.
//

import Foundation

// MARK: - 1. Meta (Reusable)
struct Meta: Decodable {
    let message: String
    let code: Int
    let status: String
}

// MARK: - 2. ServerResponse (Reusable Generic Wrapper)
struct ServerResponse<T: Decodable>: Decodable {
    let meta: Meta
    let data: T? // Tipe data unik (T) yang berisi payload
}
