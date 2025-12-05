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
    
    // Dummy Request Data
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
        // [FIXED] Login balikin 'AuthDataResponse' yang berisi 'UserInfo'
        // UserInfo biasanya punya partner_id/partner_no
        let userJson = """
        {
            "access_token": "abc",
            "refresh_token": "ref",
            "token_type": "Bearer",
            "data": {
                "id": 1,
                "partner_id": 101,
                "partner_no": "P-001",
                "username": "nunu",
                "fullname": "Nunu",
                "email": "n@m.com"
            }
        }
        """
        setupMockSuccess(withDataJson: userJson)
        
        expect(publisher: sut.login(credentials: dummyLoginReq)) { result in
            if case .success(let response) = result {
                // Assert Auth Data
                XCTAssertEqual(response.accessToken, "abc")
                // Assert UserInfo (Model Login)
                XCTAssertEqual(response.userInfo.partnerNo, "P-001")
                XCTAssertEqual(response.userInfo.username, "nunu")
            } else {
                if case .failure(let err) = result {
                    XCTFail("Harusnya sukses, tapi error: \(err)")
                }
            }
        }
    }
    
    func testGetProfile_Success() {
        // [FIXED] Profile balikin 'UserProfileResponse'
        // BEDA MODEL: Punya no_telp, kmpoin, photo_profile_url (UserInfo gak punya ini)
        let profileJson = """
        {
            "id": 99,
            "username": "doe",
            "fullname": "Doe",
            "email": "d@m.com",
            "no_telp": "081234567890",
            "kmpoin": 500,
            "photo_profile_url": "https://img.com/me.jpg",
            "join_date": "2023-01-01"
        }
        """
        setupMockSuccess(withDataJson: profileJson)
        
        expect(publisher: sut.getProfile()) { result in
            if case .success(let response) = result {
                // Assert UserProfileResponse (Model Profile)
                XCTAssertEqual(response.username, "doe")
                XCTAssertEqual(response.noTelp, "081234567890")
                XCTAssertEqual(response.kmpoin, 500)
            } else {
                if case .failure(let err) = result {
                    XCTFail("Harusnya sukses, tapi error: \(err)")
                }
            }
        }
    }
    
    // MARK: VERIFY REQUEST PARAMETERS (SPY TEST)
    func testLogin_ShouldSendCorrectParameters() {
        // Dummy JSON struktur AuthDataResponse (UserInfo)
        let userInfoJson = """
        { "id": 1, "partner_id": 1, "partner_no": "1", "username": "a", "fullname": "a", "email": "a" }
        """
        
        let fullResponse = """
        {
            "access_token": "a", "refresh_token": "b", "token_type": "c",
            "data": \(userInfoJson)
        }
        """
        setupMockSuccess(withDataJson: fullResponse, raw: true)
        
        let inputUsername = "user_ganteng"
        let inputPassword = "password_kuat"
        let req = LoginRequestBody(username: inputUsername, password: inputPassword, fcmToken: "f")
        
        _ = sut.login(credentials: req)
        
        guard let router = mockClient.lastRouterPassed else {
            XCTFail("Request tidak dikirim ke client (router nil)")
            return
        }
        
        if case .login(let params) = router {
            XCTAssertEqual(params["username"], inputUsername)
            XCTAssertEqual(params["password"], inputPassword)
        } else {
            XCTFail("Router salah!")
        }
    }
    
    // =========================================================================
    // MARK: - 2. SPECIFIC ERRORS
    // =========================================================================
    
    func testLogin_CustomErrorMessage_422() {
        // [FIX] Struktur JSON harus NESTED (data -> data) persis kayak response asli.
        // Kalau strukturnya beda (kurang nested), Decoder bakal error duluan sebelum baca pesan "Password Salah Bro".
        let errorJsonNested = """
            {
                "meta": {
                    "message": "Password Salah Bro",
                    "code": 422,
                    "status": "error"
                },
                "data": {
                    "access_token": "dummy_token",
                    "refresh_token": "dummy_refresh",
                    "token_type": "Bearer",
                    "data": {
                        "id": 1,
                        "partner_id": 101,
                        "partner_no": "P-001",
                        "username": "dummy",
                        "fullname": "Dummy",
                        "email": "dummy@mail.com"
                    }
                }
            }
            """
        
        // Inject manual result-nya biar gak kena wrap helper setupMockFailure yang mungkin salah format
        let data = errorJsonNested.data(using: .utf8)!
        mockClient.result = .failure(.serverError(statusCode: 422, data: data))
        
        expect(publisher: sut.login(credentials: dummyLoginReq)) { result in
            if case .failure(let error) = result,
               let authError = error as? AuthError,
               case .custom(let msg) = authError {
                XCTAssertEqual(msg, "Password Salah Bro")
            } else {
                if case .failure(let err) = result { print("DEBUG: Error aslinya adalah \(err)") }
                XCTFail("Harusnya Custom Error, tapi dapet: \(result)")
            }
        }
    }
    
    func testGetProfile_DecodingError() {
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
    // MARK: - 3. COMMON ERRORS
    // =========================================================================
    
    func test_AllFeatures_StandardHttpErrors() {
        verifyCommonHttpErrors(description: "Login") {
            self.sut.login(credentials: self.dummyLoginReq)
        }
        
        verifyCommonHttpErrors(description: "GetProfile") {
            self.sut.getProfile()
        }
    }
    
    func test_AllFeatures_NoInternetConnection() {
        let transportError = NetworkError.transportError(URLError(.notConnectedToInternet))
        mockClient.result = .failure(transportError)
        
        expect(publisher: sut.login(credentials: dummyLoginReq)) { result in
            self.assertTransportError(result)
        }
        
        expect(publisher: sut.getProfile()) { result in
            self.assertTransportError(result)
        }
    }
}

// =========================================================================
// MARK: - HELPER METHODS
// =========================================================================

extension UserRemoteDataSourceTests {
    
    func verifyCommonHttpErrors<T>(description: String, action: () -> AnyPublisher<T, Error>) {
        let scenarios: [Int: AuthError] = [
            401: .invalidCredentials,
            500: .serverMaintenance,
            503: .serverMaintenance
        ]
        
        for (code, expectedError) in scenarios {
            
            // [FIX PENTING] Jangan pake setupMockFailure!
            // Kita inject Data Kosong/Rusak "{}" supaya logic 'baca pesan json' GAGAL.
            // Dengan gagal baca pesan, dia akan fallback ke pengecekan Status Code.
            let emptyData = "{}".data(using: .utf8)!
            mockClient.result = .failure(.serverError(statusCode: code, data: emptyData))
            
            let exp = XCTestExpectation(description: "\(description) Error \(code)")
            
            action().sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    // Sekarang harusnya cocok, karena dia pakai fallback mapping
                    XCTAssertEqual(error as? AuthError, expectedError, "\(description) code \(code) salah mapping. Dapet: \(error)")
                    exp.fulfill()
                }
            }, receiveValue: { _ in XCTFail("Harusnya Error") })
            .store(in: &cancellables)
            
            wait(for: [exp], timeout: 0.1)
        }
    }
    
    func assertTransportError<T>(_ result: Result<T, Error>) {
        if case .failure(let err) = result, let netErr = err as? NetworkError, case .transportError = netErr {
            XCTAssertTrue(true)
        } else {
            XCTFail("Bukan transport error")
        }
    }
    
    private func setupMockSuccess(withDataJson jsonBody: String, raw: Bool = false) {
        let fullJson = raw ? jsonBody : """
        { "meta": { "code": 200, "status": "success", "message": "OK" }, "data": \(jsonBody) }
        """
        mockClient.result = .success(fullJson.data(using: .utf8)!)
    }
    
    private func setupMockFailure(errorCode: Int, message: String = "Fail", dataBody: String = "null") {
        let errorJson = """
        { "meta": { "code": \(errorCode), "status": "error", "message": "\(message)" }, "data": \(dataBody) }
        """
        let data = errorJson.data(using: .utf8)!
        mockClient.result = .failure(.serverError(statusCode: errorCode, data: data))
    }
    
    private func expect<T: Publisher>(publisher: T, assertion: @escaping (Result<T.Output, T.Failure>) -> Void) {
        let exp = XCTestExpectation(description: "Wait")
        publisher.sink(receiveCompletion: { completion in
            if case .failure(let err) = completion { assertion(.failure(err)); exp.fulfill() }
        }, receiveValue: { val in
            assertion(.success(val)); exp.fulfill()
        }).store(in: &cancellables)
        wait(for: [exp], timeout: 1.0)
    }
}
