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
    case pinboardStatus(Int)
    case pinboardError(String)
    /// After 4 tries and waiting for a total of 30 seconds Corkboard will stop
    /// attempting new requests. Please re-initiate manually.
    case rateLimitCancelling
    /// Playing nice with the Pinboard API requires to wait a bit before trying
    /// this request again.
    case requestLimit(retryIn: TimeInterval)
}

public class PinboardClient {
    var auth: Authentication

    init(auth: Authentication) {
        self.auth = auth
    }

    /// Set this to receive information on when Corkboard will retry requests.
    public var retryingIn: ((TimeInterval) -> Void)?

    var lastRequest: Date = .distantPast
    var lastRecentsRequest: Date = .distantPast
    var lastAllRequest: Date = .distantPast

    // The current amount of time waited before retrying a request. This is
    // reset after a successful request.
    var retryWait: TimeInterval = 1

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

    private func request<T: Decodable>(_ queryItems: [URLQueryItem],
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

        let now = Date()

        switch components.path {
        case "/v1/posts/all":
            let timeDiff = now.timeIntervalSince(self.lastAllRequest)
            let waitTime: Double = 5 * 60
            guard timeDiff >= waitTime else {
                completion(.failure(.requestLimit(retryIn: waitTime - timeDiff)))
                return
            }
            self.lastAllRequest = now
        case "/v1/posts/recent":
            let timeDiff = now.timeIntervalSince(self.lastRecentsRequest)
            let waitTime: Double = 3 * 60
            guard timeDiff >= waitTime else {
                completion(.failure(.requestLimit(retryIn: waitTime - timeDiff)))
                return
            }
            self.lastRecentsRequest = now
        default:
            let timeDiff = now.timeIntervalSince(self.lastRequest)
            guard timeDiff >= 3 else {
                retry(taskTo: url,
                      in: timeDiff,
                      session: session,
                      completion: completion)
                self.retryingIn?(3 - timeDiff)
                return
            }
            self.lastRequest = now
        }

        request(url, session: session, completion: completion)
    }

    private func request<T: Decodable>(_ url: URL,
                                       session: URLSession,
                                       completion: @escaping (Result<T, CorkboardError>) -> Void) {

        let task = session.dataTask(with: url) { data, resp, error in
            guard
                error == nil,
                let data = data,
                let response = resp as? HTTPURLResponse
            else {
                completion(.failure(.network(resp)))
                return
            }

            switch response.statusCode {
            case 200...299:
                self.retryWait = 1
            case 429:
                // Pinboard docs kindly ask to increasingly back off on firing
                // too many requests. After 4 attempts (2^4 -> 30 seconds) we're
                // cancelling though.
                guard self.retryWait < 16 else {
                    completion(.failure(.rateLimitCancelling))
                    return
                }

                self.retryWait *= 2
                self.retry(taskTo: url,
                      in: self.retryWait,
                      session: session,
                      completion: completion)
                self.retryingIn?(self.retryWait)
                return
            default:
                completion(.failure(.pinboardStatus(response.statusCode)))
                return
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            if let pinboardError = try? decoder.decode(PinboardError.self, from: data) {
                completion(.failure(.pinboardError(pinboardError.resultCode)))
                return
            }

            do {
                let value = try decoder.decode(T.self, from: data)
                completion(.success(value))
            } catch {
                completion(.failure(.json(error)))
            }

        }

        task.resume()
    }

    private func retry<T: Decodable>(taskTo url: URL,
                                     in seconds: TimeInterval,
                                     session: URLSession,
                                     completion: @escaping (Result<T, CorkboardError>) -> Void) {
        let deadline = DispatchTime.now() + .seconds(Int(seconds))
        DispatchQueue(label: "Corkboard.RetryRequest").asyncAfter(deadline: deadline) {
            self.request(url, session: session, completion: completion)
        }
    }
}
