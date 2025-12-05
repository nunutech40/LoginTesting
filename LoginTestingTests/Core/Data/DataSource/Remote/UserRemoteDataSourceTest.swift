//
//  UserRemoteDataSourceTest.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 03/12/25.
//

/*
 ====================================================================================
 TEORI UNIT TESTING: UserRemoteDataSource (Data Layer)
 ====================================================================================
 
 TUJUAN UTAMA:
 Memastikan bahwa 'Datasource' berfungsi sebagai "Penerjemah" yang benar antara
 API Client (Network Layer) dan Repository.
 
 APA YANG HARUS DITEST?
 Kita tidak mengetes Alamofire (itu tugas APIClient). Kita mengetes LOGIKA BISNIS
 yang ada di dalam Datasource, yaitu:
 
 1. DECODING & MAPPING SUKSES (Happy Path)
 - Jika APIClient mengembalikan JSON yang valid (200 OK + Meta Success),
 apakah Datasource berhasil mengubahnya menjadi struct `AuthDataResponse`?
 - Apakah data yang keluar sesuai dengan JSON input?
 
 2. ERROR MAPPING: LOGIKA BISNIS (Business Logic Failure)
 - Jika APIClient sukses (200 OK), TAPI Meta Status = "error" atau Code = 401:
 Apakah Datasource "menyadari" ini error dan melempar `AuthError` (bukan sukses)?
 - Ini penting agar Presenter tidak menampilkan "Login Sukses" padahal gagal di server.
 
 3. ERROR MAPPING: TRANSPORT/HTTP (Technical Failure)
 - Jika APIClient melempar error (Misal: Internet Mati atau 500 Internal Server Error):
 Apakah Datasource meneruskan error tersebut dengan benar?
 - Apakah `HTTPErrorMapper` bekerja? (Misal 401 dari APIClient -> AuthError.invalidCredentials)
 
 4. DECODING FAILURE (Malformed Data)
 - Jika APIClient mengembalikan JSON sampah/rusak:
 Apakah Datasource melempar `NetworkError.decodingError`?
 
 METODOLOGI: GIVEN - WHEN - THEN
 Setiap fungsi test harus mengikuti pola ini:
 - GIVEN: Kondisi awal. "Kalau APIClient saya setting supaya balikin data X..."
 - WHEN:  Aksi. "Terus saya panggil fungsi `login()`..."
 - THEN:  Hasil. "Maka outputnya harus Y."
 
 MENGAPA PAKAI MOCK?
 Kita pakai `MockNetworkClient` karena kita ingin mengetes LOGIKA Datasource,
 bukan mengetes koneksi internet atau server asli. Kita ingin mengendalikan
 situasi (Simulasi Sukses, Simulasi Error) secara deterministik.
 
 ====================================================================================
 */

import XCTest
import Combine
@testable import LoginTesting

class UserRemoteDataSourceTests: XCTestCase {
    
    // MARK: - Properties
    var sut: UserRemoteDataSource!
    var mockClient: MockNetworkClient!
    var cancellables: Set<AnyCancellable>!
    
    // Dummy Request Data (Biar gak nulis ulang)
    let dummyLoginReq = LoginRequestBody(username: "u", password: "p", fcmToken: "f")
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        mockClient = MockNetworkClient()
        sut = UserRemoteDataSource(client: mockClient)
        cancellables = []
    }
    
    override func tearDown() {
        sut = nil
        mockClient = nil
        cancellables = nil
        super.tearDown()
    }
    
    // =========================================================================
    // MARK: - 1. HAPPY PATHS (Tes Sukses Semua Fitur)
    // =========================================================================
    
    func testLogin_Success() {
        let userJson = """
        { "access_token": "abc", "refresh_token": "ref", "token_type": "Bearer",
          "data": { "id": 1, "username": "nunu", "fullname": "Nunu", "email": "n@m.com" } }
        """
        setupMockSuccess(withDataJson: userJson)
        
        expect(publisher: sut.login(credentials: dummyLoginReq)) { result in
            if case .success(let response) = result {
                XCTAssertEqual(response.accessToken, "abc")
            } else { XCTFail("Harusnya sukses") }
        }
    }
    
    // MARK: VERIFY REQUEST PARAMETERS (SPY TEST)
    
    func testLogin_ShouldSendCorrectParameters() {
        // GIVEN
        let userJson = "{}" // Dummy response (gak penting isinya)
        setupMockSuccess(withDataJson: userJson)
        
        // Parameter input yang mau kita tes
        let inputUsername = "user_ganteng"
        let inputPassword = "password_kuat"
        let req = LoginRequestBody(username: inputUsername, password: inputPassword, fcmToken: "f")
        
        // WHEN
        _ = sut.login(credentials: req) // Ignore resultnya, kita mau cek requestnya
        
        // THEN
        // 1. Pastikan ada request yang masuk ke MockClient
        guard let router = mockClient.lastRouterPassed else {
            XCTFail("Request tidak dikirim ke client (router nil)")
            return
        }
        
        // 2. Bongkar Router-nya, cek isinya
        // Asumsi AppRouter adalah Enum. Kita cek case-nya.
        if case .login(let params) = router {
            // params biasanya [String: Any], jadi perlu di-cast
            XCTAssertEqual(params["username"] as? String, inputUsername)
            XCTAssertEqual(params["password"] as? String, inputPassword)
        } else {
            XCTFail("Router salah! Harusnya case .login, tapi dapet: \(router)")
        }
    }
    
    func testGetProfile_Success() {
        let profileJson = """
        { "id": 99, "username": "doe", "fullname": "Doe", "email": "d@m.com" }
        """
        setupMockSuccess(withDataJson: profileJson)
        
        expect(publisher: sut.getProfile()) { result in
            if case .success(let response) = result {
                XCTAssertEqual(response.username, "doe")
            } else { XCTFail("Harusnya sukses") }
        }
    }
    
    // =========================================================================
    // MARK: - 2. SPECIFIC ERRORS (Error Unik Per Fitur)
    // =========================================================================
    // Error yang cuma ada di fitur tertentu, gak bisa digabung.
    
    // --- LOGIN SPECIFIC ---
    func testLogin_CustomErrorMessage_422() {
        // Login punya logic khusus baca message error dari server
        setupMockFailure(errorCode: 422, message: "Password Salah Bro")
        
        expect(publisher: sut.login(credentials: dummyLoginReq)) { result in
            if case .failure(let error) = result,
               let authError = error as? AuthError,
               case .custom(let msg) = authError {
                XCTAssertEqual(msg, "Password Salah Bro")
            } else {
                XCTFail("Harusnya Custom Error")
            }
        }
    }
    
    // --- PROFILE SPECIFIC ---
    func testGetProfile_DecodingError() {
        // Profile rentan error kalau JSON strukturnya beda
        setupMockSuccess(withDataJson: "{ \"salah\": \"format\" }")
        
        expect(publisher: sut.getProfile()) { result in
            if case .failure(let error) = result,
               let netError = error as? NetworkError,
               case .decodingError = netError {
                XCTAssertTrue(true)
            } else {
                XCTFail("Harusnya Decoding Error")
            }
        }
    }
    
    // =========================================================================
    // MARK: - 3. COMMON / SHARED ERRORS (Test Barengan)
    // =========================================================================
    // Di sini kita test logic error yang BERULANG/SAMA untuk semua endpoint.
    // (401, 500, 503, dan No Internet)
    
    func test_AllFeatures_StandardHttpErrors() {
        // 1. Cek Login (Harus handle 401, 500, 503)
        verifyCommonHttpErrors(description: "Login") {
            self.sut.login(credentials: self.dummyLoginReq)
        }
        
        // 2. Cek Get Profile (Harus handle 401, 500, 503 juga)
        verifyCommonHttpErrors(description: "GetProfile") {
            self.sut.getProfile()
        }
    }
    
    func test_AllFeatures_NoInternetConnection() {
        // Setup Internet Mati
        let transportError = NetworkError.transportError(URLError(.notConnectedToInternet))
        mockClient.result = .failure(transportError)
        
        // 1. Cek Login
        expect(publisher: sut.login(credentials: dummyLoginReq)) { result in
            self.assertTransportError(result, context: "Login")
        }
        
        // 2. Cek Get Profile
        expect(publisher: sut.getProfile()) { result in
            self.assertTransportError(result, context: "GetProfile")
        }
    }
}

// =========================================================================
// MARK: - HELPER METHODS
// =========================================================================

extension UserRemoteDataSourceTests {
    
    /// Helper Loop untuk test error standard (401, 500, 503)
    func verifyCommonHttpErrors<T>(description: String, action: () -> AnyPublisher<T, Error>) {
        let scenarios: [Int: AuthError] = [
            401: .invalidCredentials,
            500: .serverMaintenance,
            503: .serverMaintenance
        ]
        
        for (code, expectedError) in scenarios {
            setupMockFailure(errorCode: code)
            let exp = XCTestExpectation(description: "\(description) Error \(code)")
            
            action().sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTAssertEqual(error as? AuthError, expectedError, "\(description) code \(code) salah mapping")
                    exp.fulfill()
                }
            }, receiveValue: { _ in XCTFail("Harusnya Error") })
            .store(in: &cancellables)
            
            wait(for: [exp], timeout: 0.1)
        }
    }
    
    // Helper Assert Transport Error
    func assertTransportError<T>(_ result: Result<T, Error>, context: String) {
        if case .failure(let error) = result,
           let netError = error as? NetworkError,
           case .transportError = netError {
            XCTAssertTrue(true)
        } else {
            XCTFail("\(context): Harusnya Transport Error, dapet: \(result)")
        }
    }
    
    // Setup Mock Success
    private func setupMockSuccess(withDataJson jsonBody: String) {
        let fullJson = """
        { "meta": { "code": 200, "status": "success", "message": "OK" }, "data": \(jsonBody) }
        """
        mockClient.result = .success(fullJson.data(using: .utf8)!)
    }
    
    // Setup Mock Failure
    private func setupMockFailure(errorCode: Int, message: String = "Fail") {
        let errorJson = """
        { "meta": { "code": \(errorCode), "status": "error", "message": "\(message)" }, "data": null }
        """
        let data = errorJson.data(using: .utf8)!
        mockClient.result = .failure(.serverError(statusCode: errorCode, data: data))
    }
    
    // Expect Wrapper
    private func expect<T: Publisher>(publisher: T, assertion: @escaping (Result<T.Output, T.Failure>) -> Void) {
        let exp = XCTestExpectation(description: "Wait Publisher")
        publisher.sink(receiveCompletion: { completion in
            if case .failure(let error) = completion { assertion(.failure(error)); exp.fulfill() }
        }, receiveValue: { value in
            assertion(.success(value)); exp.fulfill()
        }).store(in: &cancellables)
        wait(for: [exp], timeout: 1.0)
    }
}
