//
//  MockUserRemoteDataSource.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 04/12/25.
//
import XCTest
import Combine
@testable import LoginTesting

// A. Mock Remote Datasource
class MockUserRemoteDataSource: UserDataSourceProtocol {
    var result: Result<AuthDataResponse, Error>?
    
    func login(credentials: LoginRequestBody) -> AnyPublisher<AuthDataResponse, Error> {
        if let result = result {
            return result.publisher.eraseToAnyPublisher()
        }
        return Fail(error: NetworkError.unknown(NSError(domain: "", code: -1))).eraseToAnyPublisher()
    }
}
