//
//  File.swift
//  
//
//  Created by John Welch on 1/10/22.
//

import XCTest
import REST

class RequestTests: XCTestCase {

    func testThatItAddsAuthorizationsToHeader() throws {
        let authorizations: [Authorization] = [.bearer(token: "token"), .custom(field:"X-Field", token: "custom")]
        let sample = SampleRequest()
        
        let request = try sample.asURLRequest(configuration: (), authorizations: authorizations)
        
        XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], "Bearer token")
        XCTAssertEqual(request.allHTTPHeaderFields?["X-Field"], "custom")
    }
    
    func testThatItAddsParametersToURL() throws {
        let authorizations: [Authorization] = [.bearer(token: "token"), .custom(field:"X-Field", token: "custom")]
        var sample = SampleRequest()
        sample.urlEncodeParameters = true
        
        let request = try sample.asURLRequest(configuration: (), authorizations: authorizations)
        
        XCTAssertTrue(request.url!.absoluteString.contains("?sample=parameter"))
    }
}

private struct SampleRequest: Requestable, Requests {
    typealias ConfigurationType = Void

    func asURLRequest(configuration: Void, authorizations: [Authorization]) throws -> URLRequest {
        try request(
            url: URL(string: "https://stub.com")!,
            method: .get,
            urlEncodeParameters: urlEncodeParameters,
            parameters: ["sample": "parameter"],
            headers: authorizations.headers())
    }
    
    var urlEncodeParameters = false
}
