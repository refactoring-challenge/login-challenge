import Foundation

public enum ServerError: Error {
    case response(HTTPURLResponse)
    case `internal`(cause: Error)
}
