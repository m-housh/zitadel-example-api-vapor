import XCTVapor

@testable import App

final class AppTests: XCTestCase {

  func test_invalid_token() async throws {
    let authenticator = ZitadelTokenAuthenticator.empty
    let token = ZitadelTokenAuthenticator.TokenResponse(
      active: false,
      exp: 1_234_567_890,
      name: "Test",
      roles: [:]
    )
    XCTAssertThrowsError(try authenticator.validateToken(token))
  }

  func test_valid_token() throws {
    let authenticator = ZitadelTokenAuthenticator.readMessages
    let token = ZitadelTokenAuthenticator.TokenResponse(
      active: true,
      exp: Date().timeIntervalSince1970 + 1000,
      name: "Test",
      roles: ["read:messages": ["12345788890": "example.zitadel.cloud"]]
    )
    XCTAssertNoThrow(try authenticator.validateToken(token))

  }
}

extension ZitadelTokenAuthenticator {

  static let empty: Self = .init()

  static let readMessages: Self = .init("read:messages")
}
