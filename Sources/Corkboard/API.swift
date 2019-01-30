import Foundation

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
