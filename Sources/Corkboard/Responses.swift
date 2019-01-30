import struct Foundation.Date

struct BookmarksResponse: Decodable {
    let date: Date
    let user: String
    let posts: [Bookmark]
}

struct PostsUpdateResponse: Decodable {
    let updateTime: Date
}
