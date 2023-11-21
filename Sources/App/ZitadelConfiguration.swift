import Vapor

struct ZitadelConfigurationError: Error {}

struct ZitadelConfiguration {
  var domain: String
  var clientId: String
  var clientSecret: String

  init() throws {
    guard let domain = Environment.get("ZITADEL_DOMAIN"),
      let clientId = Environment.get("CLIENT_ID"),
      let clientSecret = Environment.get("CLIENT_SECRET")
    else {
      throw ZitadelConfigurationError()
    }
    self.domain = domain
    self.clientId = clientId
    self.clientSecret = clientSecret
  }
}

extension ZitadelConfiguration {
  var basicAuth: BasicAuthorization {
    .init(username: clientId, password: clientSecret)
  }
}

struct ZitadelConfigurationKey: StorageKey {
  typealias Value = ZitadelConfiguration
}

extension Application {
  var zitadelConfiguration: ZitadelConfiguration? {
    get { self.storage[ZitadelConfigurationKey.self] }
    set { self.storage[ZitadelConfigurationKey.self] = newValue }
  }
}
