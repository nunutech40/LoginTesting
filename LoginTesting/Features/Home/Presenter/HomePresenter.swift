//
//  HomePresenter.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 05/12/25.
//

import Foundation
import Combine

class HomePresenter: ObservableObject {
    
    // Dependency Interactor
    private let interactor: HomeUseCase
    
    // Output ke View
    @Published var user: UserProfileModel?
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // Init inject Interactor
    init(interactor: HomeUseCase) {
        self.interactor = interactor
    }
    
    func loadProfile() {
        self.isLoading = true
        
        interactor.getProfile()
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] user in
                self?.user = user
            })
            .store(in: &cancellables)
    }
}
