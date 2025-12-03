//
//  LoginUseCase.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 03/12/25.
//

import Combine

protocol LoginUseCase {
    func login(request: LoginRequestBody) -> AnyPublisher<UserModel, Error>
}
