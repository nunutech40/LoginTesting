//
//  GetProfileUseCase.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 05/12/25.
//


import Foundation
import Combine

protocol GetProfileUseCase {
    func getProfile() -> AnyPublisher<UserModel, Error>
}
