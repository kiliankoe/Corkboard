import XCTest
@testable import Corkboard

final class CorkboardTests: XCTestCase {
    func testExample() {
        let e = expectation(description: "foo")

        let client = PinboardClient(auth: .token("<#token#>"))
        client.postsRecent { result in
            print(result)
            e.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
