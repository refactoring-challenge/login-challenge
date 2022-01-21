import Entities

public enum UserService {
    public static func currentUser() async throws -> User {
        guard let _ = AuthService.token else {
            throw AuthenticationError()
        }

        do {
            try await Task.sleep(nanoseconds: 2_000_000_000)
        } catch {
            throw NetworkError(cause: error)
        }

        guard Bool.random() else {
            if Bool.random() {
                throw NetworkError(cause: GeneralError(message: "Timeout."))
            } else if Bool.random() {
                throw ServerError.internal(cause: GeneralError(message: "Rate limit exceeded."))
            } else {
                throw GeneralError(message: "System error.")
            }
        }

        let introduction: String
        if Bool.random() {
            introduction = """
            ソフトウェアエンジニア。 Heart of Swift https://heart-of-swift.github.io を書きました。
            """
        } else {
            introduction = """
            ソフトウェアエンジニア。 Swift Zoomin' https://swift-tweets.connpass.com/ を主催しています。
            """
        }
        return User(id: "koher", name: "Yuta Koshizawa", introduction: introduction)
    }
}
