//
//  File.swift
//  
//
//  Created by John Welch on 1/10/22.
//

import Foundation

public enum RequestableError: Error {
    case authorizationMissing
    case missingURL
    case jsonEncodingFailed(error: Error)
}

/// Requestable objects can be converted to a URL request using the provided authorizations.
public protocol Requestable {
    // The type of the object used to configure the request.
    associatedtype ConfigurationType

    func asURLRequest(configuration: ConfigurationType, authorizations: [Authorization]) throws -> URLRequest
}
