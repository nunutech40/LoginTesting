//
//  UserProfileModel.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 05/12/25.
//

import Foundation

// MARK: - 2. Domain Model (Model Bersih buat UI)
struct UserProfileModel: Identifiable, Codable, Equatable {
    let id: String
    let fullname: String
    let username: String
    let email: String
    let phone: String
    let avatarUrl: URL?
    let joinDate: Date?
    let points: Int
    
    // Init lengkap (Biar enak kalau mau bikin dummy data)
    init(id: String, fullname: String, username: String, email: String, phone: String, avatarUrl: URL?, joinDate: Date?, points: Int) {
        self.id = id
        self.fullname = fullname
        self.username = username
        self.email = email
        self.phone = phone
        self.avatarUrl = avatarUrl
        self.joinDate = joinDate
        self.points = points
    }
}

// MARK: - 3. Mapper Extension (DTO -> Domain)
extension UserProfileResponse {
    func toDomain() -> UserProfileModel {
        // Setup Date Formatter sesuai format JSON "2023-12-06"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        return UserProfileModel(
            id: String(self.id),                    // Int -> String
            fullname: self.fullname,
            username: self.username,
            email: self.email,
            phone: self.noTelp,
            avatarUrl: URL(string: self.photoProfileUrl ?? ""), // String -> URL
            joinDate: formatter.date(from: self.joinDate ?? ""), // String -> Date
            points: self.kmpoin ?? 0
        )
    }
}
