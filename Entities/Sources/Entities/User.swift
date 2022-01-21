public struct User: Identifiable, Codable, Sendable {
    public let id: ID
    public var name: String
    public var introduction: String
    
    public init(id: User.ID, name: String, introduction: String) {
        self.id = id
        self.name = name
        self.introduction = introduction
    }
    
    public struct ID: RawRepresentable, Hashable, Sendable {
        public let rawValue: String
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}

extension User.ID: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self.init(rawValue: rawValue)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension User.ID: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

extension User.ID: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}
