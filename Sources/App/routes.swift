import Vapor

func routes(_ app: Application) throws {

  app.get("api", "public") { req async -> String in
    "Public route - You don't need to be authenticated to see this."
  }

  app
    .grouped(ZitadelTokenAuthenticator())
    .grouped(ZitadelUser.guardMiddleware())
    .get("api", "private") { req async -> String in
      "Private route - You need to be authenticated to see this."
    }

  app
    .grouped(ZitadelTokenAuthenticator("read:messages"))
    .grouped(ZitadelUser.guardMiddleware())
    .get("api", "private-scoped") { req async -> String in
      "Private, scoped route - You need to be authenticated and have the role read:messages to see this."
    }

}
