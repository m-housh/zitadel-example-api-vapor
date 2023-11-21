import Foundation
import Vapor

enum ValidationError: Error {
  case configNotFound
  case invalidStatus(code: HTTPStatus)
  case invalidScope
  case tokenNotActive
  case tokenExpired
}

struct ZitadelUser: Equatable, Codable {
  let name: String
}

extension ZitadelUser: Authenticatable {}

struct ZitadelTokenAuthenticator: AsyncBearerAuthenticator {
  typealias User = ZitadelUser

  let requiredScopes: [String]

  init(requiredScopes: [String] = []) {
    self.requiredScopes = requiredScopes
  }

  init(_ requiredScopes: String...) {
    self.requiredScopes = requiredScopes
  }

  func authenticate(
    bearer: BearerAuthorization,
    for request: Request
  ) async throws {
    guard let config = request.application.zitadelConfiguration
    else {
      throw ValidationError.configNotFound
    }
    request.logger.debug("Config.domain: \(config.domain)")
    request.logger.debug("Checking validation token: \(bearer.token)")
    let response = try await request.client.post("\(config.domain)/oauth/v2/introspect") { req in
      try req.query.encode([
        "token": bearer.token,
        "token_type_hint": "access_token",
        "scope": "openid",
      ])
      req.headers.add(name: .contentType, value: "www-x-form-urlencoded; charset=utf-8")
      req.headers.basicAuthorization = config.basicAuth
    }
    guard response.status == .ok else {
      throw ValidationError.invalidStatus(code: response.status)
    }
    let decodedResponse = try response.content.decode(TokenResponse.self)
    try self.validateToken(decodedResponse)
    request.auth.login(ZitadelUser.init(name: decodedResponse.name))
  }

  func matchTokenScopes(_ tokenResponse: TokenResponse) throws {
    let keys = tokenResponse.roles.keys
    for scope in self.requiredScopes {
      guard keys.contains(scope) else {
        throw ValidationError.invalidScope
      }
    }
  }

  func validateToken(_ tokenResponse: TokenResponse) throws {
    guard tokenResponse.active else {
      throw ValidationError.tokenNotActive
    }

    let now = Date().timeIntervalSince1970
    guard tokenResponse.exp > now else {
      throw ValidationError.tokenExpired
    }

    try self.matchTokenScopes(tokenResponse)
  }

  struct TokenResponse: Content {
    let active: Bool
    let exp: TimeInterval
    let name: String
    let roles: [String: [String: String]]

    init(
      active: Bool,
      exp: TimeInterval,
      name: String,
      roles: [String: [String: String]]
    ) {
      self.active = active
      self.exp = exp
      self.name = name
      self.roles = roles
    }

    private enum CodingKeys: String, CodingKey {
      case active
      case exp
      case name
      case roles = "urn:zitadel:iam:org:project:roles"
    }
  }
}
