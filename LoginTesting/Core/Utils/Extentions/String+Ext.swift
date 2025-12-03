//
//  String+Ext.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 03/12/25.
//
import Foundation

extension String {
    func asURL() throws -> URL {
        guard let url = URL(string: self) else {
            throw URLError(.badURL)
        }
        return url
    }
}
