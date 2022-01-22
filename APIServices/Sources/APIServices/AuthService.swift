import Foundation
import Entities

public enum AuthService {
    static internal private(set) var token: Data?
    
    public static func logInWith(id: String, password: String) async throws {
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
        
        guard id == "koher", password == "1234" else {
            throw LoginError()
        }
        
        token = Data((1 ... 10000).map { _ in UInt8.random(in: 0x00 ...  0xff) })
        Task {
            try await Task.sleep(nanoseconds: 30_000_000_000)
            token = nil
        }
    }
    
    public static func logOut() async {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        token = nil
    }
}
