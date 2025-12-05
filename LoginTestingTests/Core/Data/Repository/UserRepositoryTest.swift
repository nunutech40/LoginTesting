//
//  UserRepositoryTests.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 04/12/25.
//

import XCTest
import Combine
@testable import LoginTesting

/*
 ====================================================================================
 TEORI UNIT TESTING: Repository Layer
 ====================================================================================
 
 PERAN REPOSITORY:
 Repository adalah "Broker" atau perantara. Dia tidak punya logika bisnis (itu tugas
 Datasource/Interactor), tapi dia punya tugas MANAJEMEN ALUR DATA dan SIDE EFFECTS.
 
 APA YANG HARUS DITEST?
 Kita tidak mengetes apakah API berhasil (itu tugas Datasource Test).
 Kita mengetes APAKAH REPOSITORY MELAKUKAN TUGASNYA SETELAH DAPAT DATA?
 
 1. DATA FLOW (Aliran Data) 🔄
 - Apakah data mentah (AuthDataResponse) dari Datasource berhasil diubah (Map)
 menjadi Domain Model (UserModel) yang bersih?
 - Apakah data yang dikembalikan ke Interactor isinya benar?
 
 2. SIDE EFFECTS (Efek Samping) 💾 -> *INI PALING KRUSIAL DI REPO*
 - Ketika Login Sukses:
 a. Apakah Repository memanggil `SecureStorage.saveToken`? (Wajib)
 b. Apakah Repository memanggil `LocalPersistence.save` untuk user cache? (Wajib)
 - Apakah token yang disimpan sesuai dengan yang diterima dari API?
 
 3. ERROR PROPAGATION (Penyaluran Error) ⚠️
 - Ketika Datasource Gagal (misal 401 atau No Internet):
 a. Apakah Repository meneruskan error itu ke Interactor?
 b. Apakah Repository *menahan diri* untuk TIDAK menyimpan data ke storage?
 (Jangan sampai simpan token null/kosong).
 
 CARA MOCKING:
 Kita harus memalsukan 3 dependency:
 1. MockRemoteDataSource -> Untuk simulasi sukses/gagal dari API.
 2. MockSecureStorage    -> Untuk memverifikasi apakah fungsi `saveToken` terpanggil.
 3. MockLocalPersistence -> Untuk memverifikasi apakah fungsi `save` terpanggil.
 
 ====================================================================================
 */

import XCTest
import Combine
@testable import LoginTesting

class UserRepositoryTests: XCTestCase {
    
    var sut: UserRepository! // System Under Test
    
    // Dependencies
    var mockRemote: MockUserRemoteDataSource!
    var mockSecure: MockSecureStorage!
    var mockLocal: MockLocalPersistence!
    
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        // 1. Init Mocks
        mockRemote = MockUserRemoteDataSource()
        mockSecure = MockSecureStorage()
        mockLocal = MockLocalPersistence()
        
        // 2. Injeksi semua Mock ke dalam Repository
        sut = UserRepository(
            remoteDataSource: mockRemote,
            secureStorage: mockSecure,
            storage: mockLocal
        )
        
        cancellables = []
    }
    
    override func tearDown() {
        sut = nil
        mockRemote = nil
        mockSecure = nil
        mockLocal = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Test Case 1: Login Sukses (Happy Path) ✅
    func testLogin_WhenSuccess_ShouldSaveDataAndReturnUserModel() {
        // 1. GIVEN
        let dummyInfo = UserInfo(id: 1, partnerId: 10, partnerNo: "P1", username: "budi", fullname: "Budi Santoso", email: "budi@mail.com")
        let dummyResponse = AuthDataResponse(
            accessToken: "access_123",
            refreshToken: "refresh_456",
            tokenType: "Bearer",
            userInfo: dummyInfo
        )
        
        // [FIX DI SINI] Pake 'loginResult', bukan 'result' lagi
        mockRemote.loginResult = .success(dummyResponse)
        
        let request = LoginRequestBody(username: "u", password: "p", fcmToken: "f")
        let expectation = XCTestExpectation(description: "Login Sukses")
        
        // 2. WHEN
        sut.login(credentials: request)
            .sink(receiveCompletion: { completion in
                if case .failure = completion { XCTFail("Harusnya sukses") }
            }, receiveValue: { userModel in
                
                // 3. THEN (Verifikasi Data Flow)
                XCTAssertEqual(userModel.username, "budi")
                
                // 4. THEN (Verifikasi Side Effects)
                
                // Cek Secure Storage
                XCTAssertEqual(self.mockSecure.saveTokenCallCount, 2, "Harusnya saveToken dipanggil 2 kali (Access & Refresh)")
                XCTAssertEqual(self.mockSecure.savedTokens["accessToken"], "access_123")
                XCTAssertEqual(self.mockSecure.savedTokens["refreshToken"], "refresh_456")
                
                // Cek Local Persistence
                XCTAssertEqual(self.mockLocal.saveCallCount, 1, "Harusnya save user cache dipanggil 1 kali")
                
                // Cek Object yang disimpan
                if let savedUser = self.mockLocal.savedObject as? UserModel {
                    XCTAssertEqual(savedUser.username, "budi")
                } else {
                    XCTFail("Gagal menyimpan UserModel ke LocalStorage")
                }
                
                expectation.fulfill()
            })
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Test Case 2: Login Gagal (Error Path) ❌
    func testLogin_WhenFailure_ShouldPropagateErrorAndNotSaveData() {
        // 1. GIVEN
        // [FIX DI SINI] Pake 'loginResult'
        mockRemote.loginResult = .failure(AuthError.invalidCredentials)
        
        let request = LoginRequestBody(username: "u", password: "p", fcmToken: "f")
        let expectation = XCTestExpectation(description: "Login Gagal")
        
        // 2. WHEN
        sut.login(credentials: request)
            .sink(receiveCompletion: { completion in
                // 3. THEN
                if case .failure(let error) = completion {
                    // Pastikan error diteruskan
                    if let authError = error as? AuthError, authError == .invalidCredentials {
                        
                        // Cek Side Effect: HARUSNYA KOSONG (Gak ada save)
                        XCTAssertEqual(self.mockSecure.saveTokenCallCount, 0, "Jangan simpan token kalau gagal!")
                        XCTAssertEqual(self.mockLocal.saveCallCount, 0, "Jangan simpan user kalau gagal!")
                        
                        expectation.fulfill()
                    } else {
                        XCTFail("Error tidak sesuai")
                    }
                }
            }, receiveValue: { _ in
                XCTFail("Harusnya error, jangan ada value")
            })
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Test Case 3: Get Profile (Bonus biar lengkap)
    func testGetProfile_ShouldReturnData() {
        // 1. GIVEN
        // Updated sesuai struct UserProfileResponse yang baru (ada noTelp dll)
        let dummyProfile = UserProfileResponse(
            id: 99,
            fullname: "Joko",
            username: "joko",
            email: "j@j.com",
            noTelp: "081234567890",
            photoProfileUrl: nil, // Optional boleh nil
            joinDate: nil,        // Optional boleh nil
            kmpoin: 0             // Optional boleh nil (atau isi angka)
        )
        
        // [FIX DI SINI] Pake 'getProfileResult'
        mockRemote.getProfileResult = .success(dummyProfile)
        
        let expectation = XCTestExpectation(description: "Get Profile Sukses")
        
        // 2. WHEN
        sut.getProfile() // Asumsi nama fungsi di repo fetchUserProfile
            .sink(receiveCompletion: { _ in }, receiveValue: { user in
                // 3. THEN
                XCTAssertEqual(user.username, "joko")
                
                // Pastikan Mock Remote 'getProfile' terpanggil (Spy Check)
                XCTAssertTrue(self.mockRemote.isGetProfileCalled)
                
                expectation.fulfill()
            })
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
}
