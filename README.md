# 📌 Corkboard

*This project is still very much a work in progress and will likely go through some change before it's in a presentable state.*

This is a simple client for the pinboard.in API. Use it to fetch and update your bookmarks from within your app or service.

Please be sure to read the section on rate limits in the [pinboard.in API documentation](https://pinboard.in/api). This package currently supports checking for `429 Too Many Requests` errors and will retry a few times waiting a few seconds, but it does not currently handle the limits imposed for the posts/all and posts/recent endpoint.



### Quick Start

```swift
let client = PinboardClient(auth: .token("<#your token#>"))
client.postsRecent { result in
    guard let bookmarks = try? result.dematerialize() else { return }
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

