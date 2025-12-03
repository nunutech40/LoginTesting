//
//  LoginInteractor.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 03/12/25.
//

import Foundation
import Combine

class LoginInteractor: LoginUseCase {
    
    // Dependency ke Repository
    private let userRepository: UserRepositoryProtocol
    
    // Init (Dependency Injection)
    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }
    
    // MARK: - LoginUseCase Implementation
    func login(request: LoginRequestBody) -> AnyPublisher<UserModel, Error> {
        // Interactor meneruskan permintaan ke Repository
        // Di sini bisa ditaruh logic bisnis tambahan jika ada (misal validasi input sebelum ke repo)
        
        return userRepository.login(credentials: request)
            // Contoh logic bisnis:
            // Misal interactor mau logging analytics kalau login sukses
            .handleEvents(receiveOutput: { user in
                print("Analytics: User \(user.username) logged in")
            })
            .eraseToAnyPublisher()
    }
}
