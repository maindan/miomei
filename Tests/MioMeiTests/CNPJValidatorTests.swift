import XCTest
@testable import MioMei

final class CNPJValidatorTests: XCTestCase {
    func testValidCNPJ() {
        XCTAssertTrue(CNPJValidator.isValid("11.222.333/0001-81"))
        XCTAssertTrue(CNPJValidator.isValid("11222333000181"))
    }

    func testInvalidCheckDigits() {
        XCTAssertFalse(CNPJValidator.isValid("11.222.333/0001-80"))
    }

    func testRejectsWrongLength() {
        XCTAssertFalse(CNPJValidator.isValid("123"))
    }

    func testRejectsAllSameDigits() {
        XCTAssertFalse(CNPJValidator.isValid("11111111111111"))
    }

    func testFormat() {
        XCTAssertEqual(CNPJValidator.format("11222333000181"), "11.222.333/0001-81")
    }
}
