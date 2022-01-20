//
//  File.swift
//  
//
//  Created by John Welch on 1/10/22.
//

import OHHTTPStubs
import OHHTTPStubsSwift
import XCTest

import REST

class RequesterTests: XCTestCase {
    func testThatItReturnsAuthorizationRequiredWhenTokenIsInvalidOrExpired() async throws {
        let request = MockRequest(host: Constants.expired)

        stub(condition: isHost(Constants.expired)) { _ in
            let obj: [String: String] = [:]
            return HTTPStubsResponse(jsonObject: obj, statusCode: 401, headers: nil)
        }

        do {
            _ = try await requester.send(request: request, receiver: receiver)
            XCTFail("unexpected success")
        } catch {
            guard case RequesterError.authorizationRequired = error else {
                XCTFail()
                return
            }
        }
    }

    func testThatItAuthorizesARequestAndReturnsADecodableValue() async throws {
        let request = MockRequest(host: Constants.authorized)

        stub(condition: isHost(Constants.authorized)) { _ in
            let obj = ["value": "dummy"]
            return HTTPStubsResponse(jsonObject: obj, statusCode: 200, headers: nil)
        }

        let value = try await requester.send(request: request, receiver: receiver)
    
        XCTAssertEqual(value.value, "dummy")
    }

    func testThatItReturnsADecodeFailureWhenTheReturnedObjectIsInvalid() async throws {
        let request = MockRequest(host: Constants.invalid)

        stub(condition: isHost(Constants.invalid)) { _ in
            let obj = ["invalid": "invalid"]
            return HTTPStubsResponse(jsonObject: obj, statusCode: 200, headers: nil)
        }

        do {
            _ = try await requester.send(request: request, receiver: receiver)
            XCTFail("unexpected success")
        } catch {
            guard case RequesterError.decodeFailure = error else {
                XCTFail("wrong error")
                return
            }
        }
    }

    func testThatItReturnsANoContentErrorWhenTheReturnedStatusCodeIs204() async throws {
        let request = MockRequest(host: Constants.noContent)

        stub(condition: isHost(Constants.noContent)) { _ in
            let obj: [String: String] = [:]
            return HTTPStubsResponse(jsonObject: obj, statusCode: 204, headers: nil)
        }
        
        do {
            _ = try await requester.send(request: request, receiver: receiver)
            XCTFail("unexpected success")
        } catch {
            guard case RequesterError.noContent = error else {
                XCTFail("wrong error")
                return
            }
        }
    }

    func testThatItReturnsServerErrorWhenServerReportsError() async throws {
        let request = MockRequest(host: Constants.error)

        stub(condition: isHost(Constants.error)) { _ in
            let obj = ["invalid": "invalid"]
            return HTTPStubsResponse(jsonObject: obj, statusCode: 404, headers: nil)
        }
        
        do {
            _ = try await requester.send(request: request, receiver: receiver)
        } catch {
            guard case RequesterError.responseFailure = error else {
                XCTFail("wrong error")
                return
            }
        }
    }
    
    func testThatItReturnsNotAcceptableWhenServerReportsError() async throws {
        let request = MockRequest(host: Constants.error)

        stub(condition: isHost(Constants.error)) { _ in
            let obj = ["invalid": "invalid"]
            return HTTPStubsResponse(jsonObject: obj, statusCode: 406, headers: nil)
        }

        do {
            _ = try await requester.send(request: request, receiver: receiver)
        } catch {
            guard case RequesterError.notAcceptable = error else {
                XCTFail("wrong error")
                return
            }
        }
    }
    
    func testThatItReturnsConflicteWhenServerReportsError() async throws  {
        let request = MockRequest(host: Constants.error)

        stub(condition: isHost(Constants.error)) { _ in
            let obj = ["invalid": "invalid"]
            return HTTPStubsResponse(jsonObject: obj, statusCode: 409, headers: nil)
        }
        
        do {
            _ = try await requester.send(request: request, receiver: receiver)
        } catch {
            guard case RequesterError.responseConflict = error else {
                XCTFail("wrong error")
                return
            }
        }
    }
    
    func testThatItReturnsTimeoutWhenServerReportsError() async throws {
        let request = MockRequest(host: Constants.server)

        stub(condition: isHost(Constants.server)) { _ in
            let obj: [String: String] = [:]
            return HTTPStubsResponse(jsonObject: obj, statusCode: 408, headers: nil)
        }
        
        do {
            _ = try await requester.send(request: request, receiver: receiver)
        } catch {
            guard case RequesterError.requestTimeout = error else {
                XCTFail("wrong error")
                return
            }
        }
    }
    
    func testThatItReturnsInvalidWhenServerReportsError() async throws {
        let request = MockRequest(host: Constants.server)

        stub(condition: isHost(Constants.server)) { _ in
            let obj: [String: String] = [:]
            return HTTPStubsResponse(jsonObject: obj, statusCode: 402, headers: nil)
        }
        
        do {
            _ = try await requester.send(request: request, receiver: receiver)
        } catch {
            guard case let RequesterError.invalid(message) = error else {
                XCTFail("wrong error")
                return
            }
            XCTAssertEqual(message, "402")
        }
    }

    func testThatItReturnsServerFailureWhenServerHasInternalError() async throws {
        let request = MockRequest(host: Constants.server)

        stub(condition: isHost(Constants.server)) { _ in
            let obj: [String: String] = [:]
            return HTTPStubsResponse(jsonObject: obj, statusCode: 500, headers: nil)
        }
        
        do {
            _ = try await requester.send(request: request, receiver: receiver)
        } catch {
            guard case RequesterError.serverFailure = error else {
                XCTFail("wrong error")
                return
            }
        }
    }

    override func setUp() {
        authorizer = MockAuthorizer()
        session = URLSessionRequester(configuration: DummyConfiguration(), authorizer: authorizer)
        requester = AnyRequester(session)
        receiver = AnyReceivable(DecodableReceiver<TestDecodable>())
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        authorizer = nil
        session = nil
        requester = nil
    }

    private var authorizer: MockAuthorizer!
    private var requester: AnyRequester<DummyConfiguration, MockAuthorizer>!
    private var session: URLSessionRequester<DummyConfiguration, MockAuthorizer>!
    private var receiver: AnyReceivable<TestDecodable>!

    let timeout = 10.0

    enum Constants {
        static let expired = "expired.com"
        static let authorized = "authorized.com"
        static let invalid = "invalid.com"
        static let error = "error.com"
        static let server = "server.com"
        static let noContent = "noContent.com"
    }
}

private struct DummyConfiguration {}

private class MockAuthorizer: Authorizer {
    func authorize() async throws -> [Authorization] {
        return self.authorizations
    }

    func invalidate() async throws -> Bool {
       return false
    }

    var authorizations: [Authorization] = []
}

private struct TestDecodable: Decodable, Equatable {
    let value: String
}

private struct MockRequest: Requestable {
    func asURLRequest(configuration: DummyConfiguration, authorizations: [Authorization]) throws -> URLRequest {
        return URLRequest(url: URL(string: "https://\(host)/request")!)
    }

    typealias ConfigurationType = DummyConfiguration

    let host: String
}

