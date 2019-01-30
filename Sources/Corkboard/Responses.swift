import struct Foundation.Date

struct PinboardResult: Decodable {
    let resultCode: String
}

struct BookmarksResponse: Decodable {
    let date: Date
    let user: String
    let posts: [Bookmark]
}

struct PostsUpdateResponse: Decodable {
    let updateTime: Date
}
