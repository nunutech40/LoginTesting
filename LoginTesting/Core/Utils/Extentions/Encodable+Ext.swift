//
//  Encodable+Ext.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 03/12/25.
//

import Foundation

// Helper: Konversi Struct Encodable ke Dictionary [String: String]
extension Encodable {
    func asDictionary() throws -> [String: String]? {
        let data = try JSONEncoder().encode(self)
        let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        
        // Konversi [String: Any] ke [String: String] yang lebih aman (Sendable)
        let stringDictionary = dictionary?.reduce(into: [String: String]()) { (result, item) in
            // Mengubah tipe data (Int, Bool, Double) menjadi String di Datasource
            result[item.key] = String(describing: item.value)
        }
        return stringDictionary
    }
}
