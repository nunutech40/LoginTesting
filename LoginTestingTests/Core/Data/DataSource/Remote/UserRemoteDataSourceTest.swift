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
@testable import LoginTesting // Ganti dengan nama Project kamu

class UserRemoteDataSourceTests: XCTestCase {
    
    var sut: UserRemoteDataSource! // System Under Test (Yang mau dites)
    var mockClient: MockNetworkClient!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        // 1. Reset setiap kali test jalan
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
    
    // MARK: - Test Case 1: Login SUKSES ✅
    func testLogin_WhenAPISuccess_ShouldReturnAuthData() {
        // 1. GIVEN (Kondisi Awal)
        let expectedToken = "token_rahasia_123"
        let jsonString = """
        {
            "meta": {
                "code": 200,
                "status": "success",
                "message": "OK"
            },
            "data": {
                "access_token": "\(expectedToken)",
                "refresh_token": "refresh_123",
                "token_type": "Bearer",
                "data": {
                    "id": 1,
                    "partner_id": 10,
                    "partner_no": "P10",
                    "username": "hantesa",
                    "fullname": "Hantes A",
                    "email": "test@test.com"
                }
            }
        }
        """
        // Kita paksa Mock Client buat balikin data JSON di atas
        let data = jsonString.data(using: .utf8)!
        mockClient.result = .success(data)
        
        let request = LoginRequestBody(username: "user", password: "pwd", fcmToken: "fcm")
        let expectation = XCTestExpectation(description: "Login Sukses")
        
        // 2. WHEN (Aksi)
        sut.login(credentials: request)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Harusnya sukses, tapi malah error: \(error)")
                }
            }, receiveValue: { response in
                // 3. THEN (Verifikasi)
                XCTAssertEqual(response.accessToken, expectedToken)
                XCTAssertEqual(response.userInfo.username, "hantesa")
                expectation.fulfill()
            })
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Test Case 2: Login GAGAL (Password Salah / 401) ❌
    func testLogin_WhenError401_ShouldReturnInvalidCredentialsError() {
        // 1. GIVEN
        // Sesuaikan JSON String dengan screenshot Postman kamu
        let jsonString = """
            {
                "meta": {
                    "message": "Resource Not Found",
                    "code": 401,
                    "status": "error"
                },
                "data": null
            }
            """
        
        let errorData = jsonString.data(using: .utf8)!
        
        // PENTING: Karena statusnya 401, APIClient kamu akan melempar .failure(.serverError)
        // Jadi Mock-nya harus diset ke .failure, bukan .success
        mockClient.result = .failure(.serverError(statusCode: 401, data: errorData))
        
        let request = LoginRequestBody(username: "hantssesa", password: "12345678a", fcmToken: "fcmToken")
        let expectation = XCTestExpectation(description: "Login Gagal 401")
        
        // 2. WHEN
        sut.login(credentials: request)
            .sink(receiveCompletion: { completion in
                // 3. THEN
                switch completion {
                case .failure(let error):
                    // Datasource harus mengubah NetworkError(401) menjadi AuthError.invalidCredentials
                    // (Sesuai logic di HTTPErrorMapper yang kita buat)
                    if let authError = error as? AuthError, authError == .invalidCredentials {
                        expectation.fulfill() // ✅ BENAR
                    } else {
                        XCTFail("Tipe error salah. Harusnya AuthError.invalidCredentials, tapi dapat: \(error)")
                    }
                    
                case .finished:
                    XCTFail("Harusnya error, tapi malah sukses")
                }
            }, receiveValue: { _ in
                XCTFail("Harusnya tidak ada data yang dikembalikan")
            })
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Test Case 4: Server Maintenance (500) 🛠️
    func testLogin_WhenServer500_ShouldReturnServerMaintenanceError() {
        // 1. GIVEN
        // Simulasi APIClient melempar error 500
        mockClient.result = .failure(.serverError(statusCode: 500, data: nil))
        
        let request = LoginRequestBody(username: "u", password: "p", fcmToken: "f")
        let expectation = XCTestExpectation(description: "Server Maintenance")
        
        // 2. WHEN
        sut.login(credentials: request)
            .sink(receiveCompletion: { completion in
                // 3. THEN
                if case .failure(let error) = completion {
                    // Pastikan ke-map jadi .serverMaintenance
                    if let authError = error as? AuthError, authError == .serverMaintenance {
                        expectation.fulfill()
                    } else {
                        XCTFail("Harusnya AuthError.serverMaintenance, dapat: \(error)")
                    }
                }
            }, receiveValue: { _ in
                XCTFail("Harusnya error")
            })
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Test Case 5: Custom Message dari Server 💬
    func testLogin_WhenMetaErrorWithCustomMessage_ShouldReturnCustomError() {
        // 1. GIVEN
        let customMsg = "Email belum diverifikasi cuy!"
        let jsonString = """
            {
                "meta": {
                    "code": 422,
                    "status": "error",
                    "message": "\(customMsg)"
                },
                "data": null
            }
            """
        let data = jsonString.data(using: .utf8)!
        
        // Anggaplah APIClient sukses balikin data (200 OK), tapi isinya error bisnis
        mockClient.result = .success(data)
        
        let request = LoginRequestBody(username: "u", password: "p", fcmToken: "f")
        let expectation = XCTestExpectation(description: "Custom Error")
        
        // 2. WHEN
        sut.login(credentials: request)
            .sink(receiveCompletion: { completion in
                // 3. THEN
                if case .failure(let error) = completion {
                    // Pastikan errornya .custom dan pesannya sesuai
                    if let authError = error as? AuthError,
                       case .custom(let msg) = authError,
                       msg == customMsg { // Cek stringnya sama gak?
                        expectation.fulfill()
                    } else {
                        XCTFail("Harusnya AuthError.custom('\(customMsg)'), dapat: \(error)")
                    }
                }
            }, receiveValue: { _ in
                XCTFail("Harusnya error")
            })
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Test Case 3: Error Koneksi (Transport) ⚠️
    func testLogin_WhenNoInternet_ShouldReturnTransportError() {
        // 1. GIVEN
        // Simulasi Internet Mati (Mock langsung lempar error)
        let transportError = NetworkError.transportError(URLError(.notConnectedToInternet))
        mockClient.result = .failure(transportError)
        
        let request = LoginRequestBody(username: "user", password: "pwd", fcmToken: "fcm")
        let expectation = XCTestExpectation(description: "Error Koneksi")
        
        // 2. WHEN
        sut.login(credentials: request)
            .sink(receiveCompletion: { completion in
                // 3. THEN
                if case .failure(let error) = completion {
                    if let netError = error as? NetworkError, case .transportError = netError {
                        expectation.fulfill() // BENAR
                    } else {
                        XCTFail("Harusnya Transport Error")
                    }
                }
            }, receiveValue: { _ in
                XCTFail("Harusnya error")
            })
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
}
