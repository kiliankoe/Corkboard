import Foundation

enum YesNo: String, Decodable {
    case yes, no

    var bool: Bool {
        return self ~= .yes
    }
}

public struct Bookmark: Decodable {
    public let url: URL
    public let title: String
    public let description: String
    public let meta: String?
    public let hash: String?
    public let time: Date
    public let isPublic: Bool
    public let isUnread: Bool
    public let tags: [String]

    private enum CodingKeys: String, CodingKey {
        case url = "href"
        case title = "description"
        case description = "extended"
        case meta
        case hash
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
        self.meta = try container.decodeIfPresent(String.self, forKey: .meta)
        self.hash = try container.decodeIfPresent(String.self, forKey: .hash)
        self.time = try container.decode(Date.self, forKey: .time)

        let shared = try container.decode(YesNo.self, forKey: .isPublic)
        self.isPublic = shared.bool
        let toRead = try container.decode(YesNo.self, forKey: .isUnread)
        self.isUnread = toRead.bool
        let tagString = try container.decode(String.self, forKey: .tags)
        self.tags = tagString.split(separator: " ").map(String.init)
    }
}
