public struct GeneralError: Error {
    public let message: String
    public let cause: Error?
    
    public init(message: String, cause: Error? = nil) {
        self.message = message
        self.cause = cause
    }
}
