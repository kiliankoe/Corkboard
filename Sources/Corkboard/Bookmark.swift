import Foundation

public struct Bookmark: Decodable {
    public let url: URL
    public let title: String
    public let description: String
    public let time: Date
    public let isPublic: Bool
    public let isUnread: Bool
    public let tags: [String]

    private enum CodingKeys: String, CodingKey {
        case url = "href"
        case title = "description"
        case description = "extended"
        case time
        case isPublic = "shared"
        case isUnread = "toread"
        case tags
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.url = try container.decode(URL.self, forKey: .url)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        self.time = try container.decode(Date.self, forKey: .time)
        self.isPublic = try container.decode(Bool.self, forKey: .isPublic)
        self.isUnread = try container.decode(Bool.self, forKey: .isUnread)
        let tagString = try container.decode(String.self, forKey: .tags)
        self.tags = tagString.split(separator: " ").map(String.init)
    }
}
