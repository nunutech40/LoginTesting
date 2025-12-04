//
//  AuthenticationManagerTest.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 04/12/25.
//

import XCTest
import Combine
@testable import LoginTesting

/*
 ====================================================================================
 TEORI UNIT TESTING: AuthenticationManager (App State / Global Store)
 ====================================================================================
 
 TUJUAN UTAMA:
 Class ini adalah "Single Source of Truth" untuk navigasi aplikasi (Root).
 Kita harus memastikan dia mengambil keputusan yang tepat saat aplikasi baru lahir (Init).
 
 APA YANG HARUS DITEST? (SKENARIO NAVIGASI)
 
 1. COLD START (Aplikasi Baru Dibuka):
    Kita memanipulasi isi 'Storage' sebelum Manager di-init.
    - Skenario A (Happy Path): Ada Token + Ada Cache User -> `isAuthenticated = true`.
    - Skenario B (New User): Tidak ada Token -> `isAuthenticated = false`.
    - Skenario C (Corrupt Data): Ada Token tapi Cache User hilang -> `isAuthenticated = false` (Sesuai logic kode kamu).
    
    *PENTING:* Kita juga harus memastikan `isCheckingAuth` berubah dari `true` ke `false` agar Splash Screen hilang.
 
 2. STATE CHANGES (Runtime):
    - Login Success: Memastikan fungsi `loginSuccess` mengubah state jadi `true`.
    - Logout: Memastikan fungsi `logout` menghapus data di storage DAN mereset state jadi `false`.
 
 TEKNIK MOCKING:
 Kita menggunakan **STUB** (Data Palsu) untuk mengisi storage sebelum testing,
 dan **SPY** untuk memastikan fungsi `clear/remove` dipanggil saat logout.
 
 ====================================================================================
 */

class AuthenticationManagerTests: XCTestCase {
    
    var sut: AuthenticationManager!
    var mockSecure: MockSecureStorage!
    var mockLocal: MockLocalPersistence!
    
    override func setUp() {
        super.setUp()
        mockSecure = MockSecureStorage()
        mockLocal = MockLocalPersistence()
        // Note: Kita jangan init SUT (System Under Test) di sini dulu,
        // karena kita perlu setting data Mock SEBELUM init untuk ngetes "Cold Start".
    }
    
    override func tearDown() {
        sut = nil
        mockSecure = nil
        mockLocal = nil
        super.tearDown()
    }
    
    // MARK: - Test 1: Auto Login SUKSES (Token + User Ada) ✅
    func testInit_WhenTokenAndUserExist_ShouldBeAuthenticated() {
        // 1. GIVEN (Siapkan Data di Brankas Palsu)
        mockSecure.stubToken = "valid_token_123"
        
        let dummyUser = UserModel(id: "1", username: "budi", email: "budi@mail.com", fullname: "Budi")
        mockLocal.stubObject = dummyUser
        
        // 2. WHEN (Aplikasi Baru Dibuka / Init)
        sut = AuthenticationManager(secureStorage: mockSecure, storage: mockLocal)
        
        // 3. THEN (Cek Status)
        XCTAssertTrue(sut.isAuthenticated, "Harusnya login karena token & user ada")
        XCTAssertNotNil(sut.currentUser, "Data user harus terisi")
        XCTAssertEqual(sut.currentUser?.username, "budi")
        XCTAssertFalse(sut.isCheckingAuth, "Loading splash harus berhenti")
    }
    
    // MARK: - Test 2: Auto Login GAGAL (Token Kosong) ❌
    func testInit_WhenNoToken_ShouldNotBeAuthenticated() {
        // 1. GIVEN (Brankas Kosong)
        mockSecure.stubToken = nil
        
        // 2. WHEN
        sut = AuthenticationManager(secureStorage: mockSecure, storage: mockLocal)
        
        // 3. THEN
        XCTAssertFalse(sut.isAuthenticated, "Harusnya belum login")
        XCTAssertNil(sut.currentUser)
        XCTAssertFalse(sut.isCheckingAuth, "Loading splash harus berhenti")
    }
    
    // MARK: - Test 3: Data Corrupt (Token Ada, User Cache Hilang) ⚠️
    func testInit_WhenTokenExistsButNoUserCache_ShouldLogout() {
        // 1. GIVEN
        mockSecure.stubToken = "valid_token"
        mockLocal.stubObject = nil // User data hilang/terhapus cleaner
        
        // 2. WHEN
        sut = AuthenticationManager(secureStorage: mockSecure, storage: mockLocal)
        
        // 3. THEN
        // Sesuai logic kode kamu: "else { self.isAuthenticated = false }"
        XCTAssertFalse(sut.isAuthenticated, "Harusnya logout paksa karena data user tidak lengkap")
        XCTAssertNil(sut.currentUser)
    }
    
    // MARK: - Test 4: Manual Login Success 🟢
    func testLoginSuccess_ShouldUpdateState() {
        // 1. GIVEN (Init posisi logout)
        sut = AuthenticationManager(secureStorage: mockSecure, storage: mockLocal)
        let newUser = UserModel(id: "2", username: "ani", email: "ani@mail.com", fullname: "Ani")
        
        // 2. WHEN
        sut.loginSuccess(user: newUser)
        
        // 3. THEN
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(sut.currentUser?.username, "ani")
    }
    
    // MARK: - Test 5: Logout 🔴
    func testLogout_ShouldClearStorageAndResetState() {
        // 1. GIVEN (Posisi Login)
        sut = AuthenticationManager(secureStorage: mockSecure, storage: mockLocal)
        sut.isAuthenticated = true
        sut.currentUser = UserModel(id: "1", username: "a", email: "b", fullname: "c")
        
        // 2. WHEN
        sut.logout()
        
        // 3. THEN (Cek State UI)
        XCTAssertFalse(sut.isAuthenticated, "State harus kembali false")
        XCTAssertNil(sut.currentUser, "User harus nil")
        
        // 4. THEN (Cek Side Effect ke Storage / SPYING)
        XCTAssertTrue(mockSecure.isClearAllCalled, "Harus menghapus keychain")
        XCTAssertTrue(mockLocal.isRemoveCalled, "Harus menghapus user defaults")
    }
}
