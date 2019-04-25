# 📌 Corkboard

*This project is still very much a work in progress and will likely go through some change before it's in a presentable state.*

This is a simple client for the pinboard.in API. Use it to fetch and update your bookmarks from within your app or service.

Corkboard respects the rate limits imposed by Pinboard and will wait if a request has been sent within the last three seconds. It will also retry up to 4 times if it receives a `429 Too Many Requests` status code.

The `posts/recent` and `posts/all` endpoints have their own limits of three and five minutes respectively. These are not retried automatically, you will receive an error with the waiting time remaining.



### Quick Start

```swift
import Corkboard

let client = PinboardClient(auth: .token("<#your token#>"))

client.postsRecent { result in
    guard let bookmarks = try? result.get() else { return }
    for bookmark in bookmarks {
        print(bookmark)                    
    }
}
```

Instantiate a client with either token (recommended) or username/password based auth. The client has methods for interacting with the API.



### Installation

Add the following to your package manifest.

```swift
.package(url: "https://github.com/kiliankoe/Corkboard", from: "<#latest#>")
```
