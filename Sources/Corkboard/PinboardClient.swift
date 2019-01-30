import Foundation

enum Endpoint: String {
    case postsUpdate = "/posts/update"
    case postsRecent = "/posts/recent"
}

public enum Authentication {
    case credentials(username: String, password: String)
    case token(String)
}

public enum CorkboardError: Error {
    case urlEncoding(URLComponents)
    case network(URLResponse?)
    case json(Error)
}

enum Network {
    static func request<T: Decodable>(_ queryItems: [URLQueryItem],
                 _ auth: Authentication,
                 from endpoint: Endpoint,
                 session: URLSession,
                 completion: @escaping (Result<T, CorkboardError>) -> Void) {

        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.pinboard.in"
        components.path = "/v1\(endpoint.rawValue)"
        components.queryItems = queryItems
        components.queryItems?.append(URLQueryItem(name: "format", value: "json"))

        switch auth {
        case .credentials(username: let username, password: let password):
            components.user = username
            components.password = password
        case .token(let token):
            components.queryItems?.append(URLQueryItem(name: "auth_token", value: token))
        }

        guard let url = components.url else {
            completion(.failure(.urlEncoding(components)))
            return
        }

        let task = session.dataTask(with: url) { data, response, error in
            guard error == nil, let data = data else {
                completion(.failure(.network(response)))
                return
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            do {
                let value = try decoder.decode(T.self, from: data)
                completion(.success(value))
            } catch {
                completion(.failure(.json(error)))
            }

        }

        task.resume()
    }
}

public struct PinboardClient {
    var auth: Authentication

    /// Returns a list of the user's most recent posts, filtered by tag.
    ///
    /// - Parameters:
    ///   - tags: filter by up to three tags
    ///   - count: number of results to return. Default is 15, max is 100
    public func postsRecent(tags: [String] = [],
                            count: Int = 15,
                            session: URLSession = .shared,
                            completion: @escaping (Result<[Bookmark], CorkboardError>) -> Void) {

        var queryItems = [
            URLQueryItem(name: "count", value: String(count))
        ]

        if !tags.isEmpty {
            queryItems.append(
                URLQueryItem(name: "tags", value: tags.joined(separator: " ")))
        }

        Network.request(queryItems, self.auth, from: Endpoint.postsRecent, session: session) {
            (result: Result<BookmarksResponse, CorkboardError>) in

            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                completion(.success(response.bookmarks))
            }
        }
    }
}