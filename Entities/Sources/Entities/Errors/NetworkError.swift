public struct NetworkError: Error {
    public let cause: Error
    
    public init(cause: Error) {
        self.cause = cause
    }
}
