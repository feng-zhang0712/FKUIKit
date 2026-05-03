import FKCoreKit
import XCTest

/// Smoke tests for **public** `FKCoreKit` helpers (mostly `Extension/` + portable APIs).
/// Keep cases dependency-light so they run cleanly on **iOS Simulator** via `xcodebuild test`.
final class FKCoreKitExtensionSmokeTests: XCTestCase {
  func testStringTrimmed() {
    XCTAssertEqual("  hi  ".fk_trimmed, "hi")
    XCTAssertTrue("  ".fk_isBlank)
    XCTAssertFalse("a".fk_isBlank)
  }

  func testOptionalOr() {
    XCTAssertEqual(Int?.none.fk_or(42), 42)
    XCTAssertEqual(Optional(7).fk_or(42), 7)
  }

  func testArraySafeSubscript() {
    let values = [10, 20, 30]
    XCTAssertNil(values[fk_safe: 99])
    XCTAssertEqual(values[fk_safe: 1], 20)
  }

  func testResultSuccessAndFailure() {
    let ok = Result<Int, NSError>.success(1)
    XCTAssertEqual(ok.fk_successValue, 1)
    XCTAssertNil(ok.fk_failureValue)

    let err = Result<Int, NSError>.failure(NSError(domain: "t", code: 1))
    XCTAssertNil(err.fk_successValue)
    XCTAssertNotNil(err.fk_failureValue)
  }

  func testUUIDRoundTripCompactHex() {
    let original = UUID(uuidString: "8A4A6052-4A02-4E89-B7CB-0AC97097C13E")!
    let compact = original.fk_compactHexString
    XCTAssertEqual(compact, "8a4a60524a024e89b7cb0ac97097c13e")
    XCTAssertEqual(UUID(fk_hexString: compact), original)
  }
}
