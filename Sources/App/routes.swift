import Vapor

func routes(_ app: Application) throws {

  // Remove
  app.get("config") { req async throws -> String in
    guard let config = req.application.zitadelConfiguration else {
      throw Abort(.notFound)
    }
    req.logger.info("Zitadel Domain: \(config.domain)")
    req.logger.info("Client ID: \(config.clientId)")
    req.logger.info("Client Secret: \(config.clientSecret)")
    return config.domain
  }

  app.get("api", "public") { req async -> String in
    "Public route - You don't need to be authenticated to see this."
  }

  app.get("api", "private") { req async -> String in
    "Private route - You need to be authenticated to see this."
  }

  app.get("api", "private-scoped") { req async -> String in
    "Private, scoped route - You need to be authenticated and have the role read:messages to see this."
  }
}
