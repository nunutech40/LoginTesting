//
//  LoginPresenterTests.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 04/12/25.
//

import XCTest
import Combine
@testable import LoginTesting

/*
 ====================================================================================
 TEORI UNIT TESTING: Presenter / ViewModel Layer (SwiftUI + Combine)
 ====================================================================================
 
 TUJUAN UTAMA:
 Presenter adalah "Otak UI". Kita tidak mengetes apakah tombolnya berwarna biru (itu UI Test),
 tapi kita mengetes apakah LOGIKA perubahan STATE-nya benar.
 
 APA YANG HARUS DITEST? (STATE CHANGES)
 Dalam SwiftUI (`ObservableObject`), Output adalah properti `@Published`.
 Kita harus memastikan Input (Function call) menghasilkan Output (State change) yang benar.
 
 1. SKENARIO SUKSES (Happy Path)
    - INPUT: Panggil `login(username, password)`.
    - EXPECTATION:
      a. `isLoading` harus sempat jadi true, lalu kembali false.
      b. `isLoggedIn` harus berubah menjadi `true`.
      c. `user` tidak boleh nil (terisi data).
      d. `isError` harus tetap `false`.
 
 2. SKENARIO GAGAL (Error Path)
    - INPUT: Panggil `login(...)` tapi UseCase melempar Error.
    - EXPECTATION:
      a. `isLoading` harus kembali false.
      b. `isLoggedIn` harus tetap `false`.
      c. `isError` harus berubah menjadi `true`.
      d. `errorMessage` harus berisi pesan yang sesuai dengan errornya.
 
 TANTANGAN COMBINE & RUNLOOP:
 Karena Presenter menggunakan `.receive(on: RunLoop.main)`, perubahan state terjadi
 secara *Asynchronous* di Main Thread.
 -> SOLUSI: Kita harus menggunakan `XCTestExpectation` atau `DispatchQueue` di dalam test
    untuk menunggu siklus RunLoop selesai sebelum melakukan `Assert`.
 
 ====================================================================================
 */

// MARK: - 2. TEST CLASS
class LoginPresenterTests: XCTestCase {
    
    var sut: LoginPresenter!
    var mockUseCase: MockLoginUseCase!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockUseCase = MockLoginUseCase()
        sut = LoginPresenter(loginUseCase: mockUseCase)
        cancellables = []
    }
    
    override func tearDown() {
        sut = nil
        mockUseCase = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Test Case 1: Login Sukses ✅
    func testLogin_WhenSuccess_ShouldUpdateStateToLoggedIn() {
        // 1. GIVEN
        let dummyUser = UserModel(id: "1", username: "hantesa", email: "test@mail.com", fullname: "Hantes A")
        mockUseCase.result = .success(dummyUser)
        
        // Kita butuh expectation karena perubahan @Published itu async
        let expectation = XCTestExpectation(description: "State updated to LoggedIn")
        
        // Kita "mata-matai" properti isLoggedIn milik Presenter
        sut.$isLoggedIn
            .dropFirst() // Abaikan value awal (false)
            .sink { isLoggedIn in
                if isLoggedIn {
                    expectation.fulfill() // Test lulus kalau ini terpanggil
                }
            }
            .store(in: &cancellables)
        
        // 2. WHEN
        sut.login(username: "hantesa", pass: "12345678")
        
        // 3. THEN
        // Tunggu expectation terpenuhi (maksimal 1 detik)
        wait(for: [expectation], timeout: 1.0)
        
        // Cek sisa state lainnya
        XCTAssertFalse(sut.isLoading, "Loading harus berhenti")
        XCTAssertFalse(sut.isError, "Tidak boleh ada error")
        XCTAssertEqual(sut.user?.username, "hantesa", "Data user harus sesuai")
    }
    
    // MARK: - Test Case 2: Login Gagal (Error) ❌
    func testLogin_WhenFailure_ShouldUpdateErrorState() {
        // 1. GIVEN
        // Kita paksa UseCase balikin error
        let expectedError = AuthError.invalidCredentials
        mockUseCase.result = .failure(expectedError)
        
        let expectation = XCTestExpectation(description: "State updated to Error")
        
        // Mata-matai properti isError
        sut.$isError
            .dropFirst()
            .sink { isError in
                if isError {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // 2. WHEN
        sut.login(username: "hantesa", pass: "salah_password")
        
        // 3. THEN
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertFalse(sut.isLoading, "Loading harus berhenti")
        XCTAssertFalse(sut.isLoggedIn, "User tidak boleh login")
        
        // Cek Pesan Error
        // Catatan: Karena di kode Presenter kamu pakai error.localizedDescription,
        // pastikan AuthError punya localizedDescription yang benar.
        XCTAssertEqual(sut.errorMessage, expectedError.localizedDescription)
    }
    
    // MARK: - Test Case 3: Validasi Loading State (Optional) ⏳
    // Mengetes apakah isLoading sempat true lalu jadi false
    func testLogin_LoadingStateFlow() {
        // 1. GIVEN
        mockUseCase.result = .success(UserModel(id: "1", username: "u", email: "e", fullname: "f"))
        
        // 2. WHEN
        sut.login(username: "u", pass: "p")
        
        // 3. THEN
        // Karena Combine di Presenter pakai .receive(on: RunLoop.main),
        // Sesaat setelah dipanggil, isLoading harusnya true (sebelum async selesai)
        
        // Cek state awal (Synchronous check)
        XCTAssertTrue(sut.isLoading, "Saat baru dipanggil, loading harus True")
        
        // Cek state akhir (Asynchronous check)
        let expectation = XCTestExpectation(description: "Loading finished")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Setelah proses selesai
            XCTAssertFalse(self.sut.isLoading, "Setelah selesai, loading harus False")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}
