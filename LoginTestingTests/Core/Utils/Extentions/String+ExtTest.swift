//
//  String+ExtTest.swift
//  LoginTesting
//
//  Created by Nunu Nugraha on 04/12/25.
//

import XCTest
@testable import LoginTesting

/*
 ====================================================================================
 TEORI UNIT TESTING: Helper & Extensions (Logic Testing)
 ====================================================================================
 
 KENAPA PERLU DITEST?
 Helper/Extension adalah "Batu Bata" paling dasar dari aplikasi.
 - Kalau logic validasi email salah di sini, maka Login, Register, dan Forgot Password
   semuanya akan ikut salah (Bug menjalar ke atas).
 
 KARAKTERISTIK TEST HELPER:
 1. PURE FUNCTIONS (Fungsi Murni):
    Outputnya hanya bergantung pada Input. Tidak ada ketergantungan ke API, Database,
    atau State luar.
    -> Input: "budi" -> Output: True/False. Selalu sama.
 
 2. NO MOCKING NEEDED:
    Karena tidak ada dependency, kita tidak butuh Mock object. Test-nya langsung
    tembak ke fungsi aslinya.
 
 3. BOUNDARY TESTING (Uji Batas):
    Kita harus mengetes di "tepi jurang" logika.
    - Kalau syarat password minimal 8 karakter:
      Test input 7 karakter (Harus False).
      Test input 8 karakter (Harus True).
 
 STRATEGI TEST:
 - Happy Path: Masukkan data yang benar, pastikan return True.
 - Sad Path: Masukkan data salah (kosong, format acak), pastikan return False / Throw Error.
 
 ====================================================================================
 */
import XCTest
@testable import LoginTesting

class StringExtTests: XCTestCase {

    // MARK: - 1. Test asURL() 🌐
    // Tujuannya: Memastikan string berubah jadi URL, atau throw error kalau stringnya sampah.
    
    func test_asURL_WhenValidString_ShouldReturnURL() {
        // GIVEN
        let validString = "https://dev.go.komtim.komerce.my.id"
        
        // WHEN & THEN
        // Kita pakai XCTAssertNoThrow karena fungsi ini throws
        XCTAssertNoThrow(try {
            let url = try validString.asURL()
            XCTAssertEqual(url.absoluteString, validString)
            XCTAssertEqual(url.scheme, "https")
        }())
    }
    
    func test_asURL_WhenInvalidString_ShouldThrowBadURLError() {
        // GIVEN
        // String kosong biasanya menyebabkan URL(string:) return nil
        let invalidString = ""
        
        // WHEN & THEN
        XCTAssertThrowsError(try invalidString.asURL()) { error in
            // Pastikan error yang dilempar adalah URLError.badURL
            if let urlError = error as? URLError {
                XCTAssertEqual(urlError.code, .badURL)
            } else {
                XCTFail("Error yang dilempar bukan URLError")
            }
        }
    }
    
    // MARK: - 2. Test Email Validation 📧
    // Tujuannya: Memastikan Regex bekerja untuk format email standar.
    
    func test_isValidEmail_WhenFormatCorrect_ShouldReturnTrue() {
        // GIVEN: Daftar email valid
        let validEmails = [
            "budi@gmail.com",
            "test.user@kantor.co.id",
            "nama+tag@domain.net",
            "123@angka.com"
        ]
        
        // WHEN & THEN
        for email in validEmails {
            XCTAssertTrue(email.isValidEmail, "Seharusnya Valid: \(email)")
        }
    }
    
    func test_isValidEmail_WhenFormatWrong_ShouldReturnFalse() {
        // GIVEN: Daftar email ngaco
        let invalidEmails = [
            "budi",             // Gak ada @
            "budi@com",         // Gak ada domain
            "budi@.com",        // Domain kosong
            "@gmail.com",       // Username kosong
            "",                 // Kosong total
            "budi spasi@gmail.com" // Ada spasi
        ]
        
        // WHEN & THEN
        for email in invalidEmails {
            XCTAssertFalse(email.isValidEmail, "Seharusnya TIDAK Valid: \(email)")
        }
    }
    
    // MARK: - 3. Test Username Validation 👤
    // Logic: Minimal 4 karakter & Tidak ada spasi.
    
    func test_isValidUsername_WhenValid_ShouldReturnTrue() {
        // GIVEN
        let validUsernames = ["budi", "admin123", "user_name"]
        
        // THEN
        for name in validUsernames {
            XCTAssertTrue(name.isValidUsername, "Valid: \(name)")
        }
    }
    
    func test_isValidUsername_WhenTooShort_ShouldReturnFalse() {
        // GIVEN (Kurang dari 4 char)
        let shortName = "bud"
        
        // THEN
        XCTAssertFalse(shortName.isValidUsername)
    }
    
    func test_isValidUsername_WhenContainsSpace_ShouldReturnFalse() {
        // GIVEN (Ada spasi)
        let spacedName = "budi santoso"
        
        // THEN
        XCTAssertFalse(spacedName.isValidUsername)
    }
    
    // MARK: - 4. Test Password Validation 🔒
    // Logic: Minimal 8 karakter.
    
    func test_isValidPassword_WhenLongEnough_ShouldReturnTrue() {
        // GIVEN (8 Karakter atau lebih)
        let pass8 = "12345678"
        let passLong = "iniPasswordSangatPanjang"
        
        // THEN
        XCTAssertTrue(pass8.isValidPassword)
        XCTAssertTrue(passLong.isValidPassword)
    }
    
    func test_isValidPassword_WhenTooShort_ShouldReturnFalse() {
        // GIVEN (Kurang dari 8)
        let pass7 = "1234567" // Batas kritis
        let passEmpty = ""
        
        // THEN
        XCTAssertFalse(pass7.isValidPassword)
        XCTAssertFalse(passEmpty.isValidPassword)
    }
}
