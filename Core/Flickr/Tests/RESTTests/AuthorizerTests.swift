import XCTest
@testable import REST

final class AuthorizerTests: XCTestCase {
    func testThatItReturnsTheAuthorizations() async throws {
        let authorization: Authorization = .bearer(token: "test")
        let authorizer = AnyAuthorizer(ConstantAuthorizer([authorization]))

        let value = try await authorizer.authorize()
        
        XCTAssertEqual(value, [authorization])
    }

    func testThatItDoesNotInvalidate() async throws {
        let authorization: Authorization = .bearer(token: "test")
        let authorizer = AnyAuthorizer(ConstantAuthorizer([authorization]))
        _ = try await authorizer.authorize()
            
        let invalidated = try await authorizer.invalidate()
        
        XCTAssertFalse(invalidated)
    }
    
    func testThatItComposesAuthenticators() async throws {
        let bearer = Authorization.bearer(token: "a")
        let custom = Authorization.custom(field: "custom", token: "b")
        
        let a = ConstantAuthorizer([bearer])
        let b = ConstantAuthorizer([custom])
        
        let c = ComposedAuthorizer(a: a, b: b)
        
        let values = try await c.authorize()

        XCTAssertEqual(values, [bearer,custom])
    }
    
    func testThatAComposedAuthorizerInvalidates() async throws {
        let a = TestAuthorizer()
        let b = TestAuthorizer()
        let authorizer = ComposedAuthorizer(a: a, b: b)
        
        _ = try await authorizer.invalidate()
        
        XCTAssertTrue(a.didInvalidate)
        XCTAssertTrue(b.didInvalidate)
    }

    func testThatItCreatesAHeaderForABearerAuthorization() {
        let authorization = Authorization.bearer(token: "test")

        XCTAssertEqual(authorization.header(), ["Authorization": "Bearer test"])
    }

    func testThatItCreatesAHeaderForACustomAuthorization() {
        let authorization = Authorization.custom(field: "Field", token: "test")

        XCTAssertEqual(authorization.header(), ["Field": "test"])
    }
}

private final class TestAuthorizer: Authorizer {
    func authorize() async throws-> [Authorization] {
        return []
    }
    
    func invalidate() async throws -> Bool {
        didInvalidate = true
        return true
    }
    
    var didInvalidate = false
}
