import Foundation

enum Endpoint: String {
    case postsUpdate = "/posts/update"
    case postsAdd = "/posts/add"
    case postsDelete = "/posts/delete"
    case postsGet = "/posts/get"
    case postsRecent = "/posts/recent"
}

extension PinboardClient {
    /// Returns the most recent time a bookmark was added, updated or deleted.
    ///
    /// Use this before calling posts/all to see if the data has changed since the last fetch.
    public func postsUpdate(session: URLSession = .shared,
                            completion: @escaping (Result<Date, CorkboardError>) -> Void) {
        request([], self.auth, from: .postsUpdate, session: session) {
            (result: Result<PostsUpdateResponse, CorkboardError>) in

            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                completion(.success(response.updateTime))
            }
        }
    }

    /// Add a bookmark.
    ///
    /// - Parameters:
    ///   - url: URL of the item
    ///   - title: Title of the item.
    ///   - description: Description of the item.
    ///   - tags: List of up to 100 tags
    ///   - creationTime: creation time for this bookmark. Defaults to current time.
    /// Datestamps more than 10 minutes ahead of server time will be reset to current server time.
    ///   - replaceExisting: Replace any existing bookmark with this URL.
    /// Default is yes. If set to no, will throw an error if bookmark exists
    ///   - isPublic: Make bookmark public. Default is yes unless user has
    /// enabled the "save all bookmarks as private" user setting, in which case default is no
    ///   - isUnread: Marks the bookmark as unread. Default is no
    public func postsAdd(url: URL,
                         title: String,
                         description: String? = nil,
                         tags: [String]? = nil,
                         creationTime: Date? = nil,
                         replaceExisting: Bool? = nil,
                         isPublic: Bool? = nil,
                         isUnread: Bool? = nil,
                         session: URLSession = .shared,
                         completion: @escaping (Result<(), CorkboardError>) -> Void) {
        var queryItems = [
            URLQueryItem(name: "url", value: url.absoluteString),
            URLQueryItem(name: "description", value: title)
        ]

        if let description = description {
            queryItems.append(URLQueryItem(name: "extended", value: description))
        }
        if let tags = tags {
            queryItems.append(URLQueryItem(name: "tags", value: tags.joined(separator: " ")))
        }
        if let creationTime = creationTime {
            let formatter = ISO8601DateFormatter()
            queryItems.append(URLQueryItem(name: "dt", value: formatter.string(from: creationTime)))
        }
        if let replaceExisting = replaceExisting {
            let yesNo = replaceExisting ? "yes" : "no"
            queryItems.append(URLQueryItem(name: "replace", value: yesNo))
        }
        if let isPublic = isPublic {
            let yesNo = isPublic ? "yes" : "no"
            queryItems.append(URLQueryItem(name: "shared", value: yesNo))
        }
        if let isUnread = isUnread {
            let yesNo = isUnread ? "yes" : "no"
            queryItems.append(URLQueryItem(name: "toread", value: yesNo))
        }

        request(queryItems, self.auth, from: .postsAdd, session: session) {
            (result: Result<Ok, CorkboardError>) in

            switch result {
            case .failure(.pinboardOk):
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            case .success(_):
                assertionFailure("Unexpected success value in posts/add. This is an error in Corkboard.")
            }
        }
    }

    /// Delete a bookmark.
    public func postsDelete(url: URL,
                            session: URLSession = .shared,
                            completion: @escaping (Result<(), CorkboardError>) -> Void) {
        let queryItems = [URLQueryItem(name: "url", value: url.absoluteString)]

        request(queryItems, self.auth, from: .postsDelete, session: session) {
            (result: Result<Ok, CorkboardError>) in

            switch result {
            case .failure(.pinboardOk):
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            case .success(_):
                assertionFailure("Unexpected success value in posts/delete. This is an error in Corkboard.")
            }
        }
    }

    /// Returns one or more posts on a single day matching the arguments. If no
    /// date or url is given, date of most recent bookmark will be used.
    ///
    /// - Parameters:
    ///   - tags: filter by up to three tags
    ///   - creationTime: return results bookmarked on this day
    ///   - url: return bookmark for this URL
    ///   - includeMeta: include a change detection signature in a meta attribute
    public func postsGet(tags: [String]? = nil,
                         creationTime: Date? = nil,
                         url: URL? = nil,
                         includeMeta: Bool? = nil,
                         session: URLSession = .shared,
                         completion: @escaping (Result<[Bookmark], CorkboardError>) -> Void) {

        var queryItems: [URLQueryItem] = []

        if let tags = tags {
            queryItems.append(URLQueryItem(name: "tag", value: tags.joined(separator: " ")))
        }
        if let creationTime = creationTime {
            let formatter = ISO8601DateFormatter()
            queryItems.append(URLQueryItem(name: "dt", value: formatter.string(from: creationTime)))
        }
        if let url = url {
            queryItems.append(URLQueryItem(name: "url", value: url.absoluteString))
        }
        if let includeMeta = includeMeta {
            let yesNo = includeMeta ? "yes" : "no"
            queryItems.append(URLQueryItem(name: "meta", value: yesNo))
        }

        request(queryItems, self.auth, from: .postsGet, session: session) {
            (result: Result<BookmarksResponse, CorkboardError>) in

            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                completion(.success(response.posts))
            }
        }
    }

    /// Returns a list of the user's most recent posts, filtered by tag.
    ///
    /// - Parameters:
    ///   - tags: filter by up to three tags
    ///   - count: number of results to return. Default is 15, max is 100
    public func postsRecent(tags: [String] = [],
                            count: Int? = nil,
                            session: URLSession = .shared,
                            completion: @escaping (Result<[Bookmark], CorkboardError>) -> Void) {

        var queryItems: [URLQueryItem] = []

        if let count = count {
            queryItems.append(URLQueryItem(name: "count", value: String(count)))
        }

        if !tags.isEmpty {
            queryItems.append(
                URLQueryItem(name: "tags", value: tags.joined(separator: " ")))
        }

        request(queryItems, self.auth, from: Endpoint.postsRecent, session: session) {
            (result: Result<BookmarksResponse, CorkboardError>) in

            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                completion(.success(response.posts))
            }
        }
    }
}
