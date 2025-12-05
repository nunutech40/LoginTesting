//
//  HomePresenterTests.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 05/12/25.
//

/*
 ====================================================================================
 TEORI UNIT TESTING: Presentation Layer (Presenter / ViewModel)
 ====================================================================================
 
 TUJUAN UTAMA:
 Layer ini bertugas mengatur "State" dari Tampilan (UI).
 Kita tidak mengetes tampilan (View) itu sendiri (apakah warnanya merah/biru),
 tapi kita mengetes LOGIKA PERUBAHAN STATE-nya.
 
 APA YANG HARUS DITEST? (STATE VERIFICATION)
 1. Loading State:
 - Saat request dimulai, apakah `isLoading` berubah jadi `true`?
 - Saat request selesai (sukses/gagal), apakah `isLoading` kembali `false`?
 
 2. Data State (Happy Path):
 - Jika Interactor mengembalikan data sukses, apakah variabel `@Published user` terisi?
 - Apakah data yang ditampilkan sesuai dengan yang dikirim Interactor?
 - Apakah pesan error kosong?
 
 3. Error State (Sad Path):
 - Jika Interactor gagal, apakah variabel `@Published errorMessage` terisi pesan yang benar?
 - Apakah variabel `user` tetap kosong/nil?
 
 METODOLOGI: GIVEN - WHEN - THEN
 - GIVEN: Siapkan Mock Interactor. Kita atur mau dia sukses atau gagal (Stubbing).
 - WHEN:  Panggil fungsi di Presenter (misal: `loadProfile()`).
 - THEN:  Cek perubahan variabel `@Published` menggunakan Combine Subscription (`.sink`).
 
 KENAPA MOCK INTERACTOR?
 Presenter tidak boleh tahu logic API/Database. Dia cuma minta data ke Interactor.
 Jadi kita memalsukan Interactor biar kita bisa ngatur skenario:
 "Eh Interactor, pura-pura sukses dong" atau "Pura-pura internet mati dong".
 ====================================================================================
 */

import XCTest
import Combine
@testable import LoginTesting

// =========================================================================
// MOCK OBJECTS
// =========================================================================

// 1. Mock UseCase (Interactor)
// Kita butuh ini karena Presenter bergantung pada HomeUseCase
class MockHomeInteractor: HomeUseCase {
    
    // Configurable Result (Stub)
    var getProfileResult: Result<UserProfileModel, Error>?
    
    func getProfile() -> AnyPublisher<UserProfileModel, Error> {
        if let result = getProfileResult {
            return result.publisher.eraseToAnyPublisher()
        }
        return Fail(error: NetworkError.unknown(NSError(domain: "Mock", code: -1))).eraseToAnyPublisher()
    }
}

// =========================================================================
// TEST SUITE
// =========================================================================

class HomePresenterTests: XCTestCase {
    
    // System Under Test
    var sut: HomePresenter!
    
    // Dependencies
    var mockInteractor: MockHomeInteractor!
    
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockInteractor = MockHomeInteractor()
        sut = HomePresenter(interactor: mockInteractor)
        cancellables = []
    }
    
    override func tearDown() {
        sut = nil
        mockInteractor = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Test Case 1: Load Profile Sukses ✅
    func testLoadProfile_WhenSuccess_ShouldUpdateUserAndStopLoading() {
        // 1. GIVEN
        // Siapkan data dummy UserProfileModel (Domain Model)
        // [UPDATED] Disesuaikan dengan struktur Domain Model baru (phone, points, avatarUrl)
        let dummyUser = UserProfileModel(
            id: "1", // String
            fullname: "Sultan Andara",
            username: "sultan",
            email: "sultan@mail.com",
            phone: "08123456789", // phone
            avatarUrl: URL(string: "https://dummy.com/avatar.png"), // avatarUrl
            joinDate: Date(), // joinDate
            points: 999 // points
        )
        
        mockInteractor.getProfileResult = .success(dummyUser)
        
        let expectation = XCTestExpectation(description: "Profile Loaded & Loading Stopped")
        
        // 2. WHEN
        // Kita observe $isLoading. Tunggu sampai dia balik jadi FALSE (Selesai).
        sut.$isLoading
            .dropFirst() // Abaikan value awal (false)
            .sink { isLoading in
                // 3. THEN
                // Kita cek hanya ketika loading sudah selesai (false)
                if !isLoading {
                    // Pastikan data user SUDAH masuk
                    if let user = self.sut.user {
                        XCTAssertEqual(user.username, "sultan")
                        XCTAssertEqual(user.fullname, "Sultan Andara")
                        XCTAssertEqual(user.points, 999)
                        
                        // Error message harus kosong
                        XCTAssertTrue(self.sut.errorMessage.isEmpty)
                        
                        expectation.fulfill()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Action Trigger
        sut.loadProfile()
        
        // Cek state awal (Synchronous check: Loading harus true sesaat setelah dipanggil)
        XCTAssertTrue(sut.isLoading, "Loading harus true saat request dimulai")
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Test Case 2: Load Profile Gagal
    func testLoadProfile_WhenFailure_ShouldShowErrorAndStopLoading() {
        // 1. GIVEN
        let mockError = AuthError.serverMaintenance
        mockInteractor.getProfileResult = .failure(mockError)
        
        let expectation = XCTestExpectation(description: "Error Received")
        
        // 2. WHEN
        // Kita observe property @Published 'errorMessage'
        sut.$errorMessage
            .dropFirst() // Abaikan value awal ("")
            .sink { message in
                // 3. THEN
                if !message.isEmpty {
                    // Pastikan pesan error sesuai (AuthError.serverMaintenance punya localizedDescription)
                    XCTAssertEqual(message, mockError.localizedDescription)
                    
                    // Pastikan user tetap nil & loading berhenti
                    XCTAssertNil(self.sut.user)
                    XCTAssertFalse(self.sut.isLoading)
                    
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Action Trigger
        sut.loadProfile()
        
        wait(for: [expectation], timeout: 1.0)
    }
}
