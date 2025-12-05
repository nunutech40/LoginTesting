//
//  HomeInteractor.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 05/12/25.
//

import Foundation
import Combine

// Protocol UseCase untuk Home
protocol HomeUseCase {
    func getProfile() -> AnyPublisher<UserProfileModel, Error>
}

class HomeInteractor: HomeUseCase {
    
    private let userRepository: UserRepositoryProtocol
    
    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }
    
    func getProfile() -> AnyPublisher<UserProfileModel, Error> {
        // Langsung return, no logic added
        return userRepository.getProfile()
    }
}
