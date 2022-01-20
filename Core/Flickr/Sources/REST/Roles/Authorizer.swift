//
//  File.swift
//  
//
//  Created by John Welch on 1/9/22.
//

import Foundation

public enum AuthorizerError: Error {
    case failed
    case invalidated
    case platform(error: Error)
}

/**
 *  A companion protocol to the Requester. Authorizes requests so we can
 *  build them.
 */
//@available(macOS 10.15.0, *)
public protocol Authorizer {
    /// Attempt to authorize a request. Returns a promise that delivers the new authorizations.
    func authorize() async throws -> [Authorization]
    /// Cancel current authorizations
    func invalidate() async throws -> Bool
}

//@available(macOS 10.15.0, *)
public struct AnyAuthorizer: Authorizer {
    public init<A: Authorizer>(_ base: A) {
        authorizer = { try await base.authorize() }
        invalidator = { try await base.invalidate() }
    }

    public func authorize() async throws-> [Authorization] {
        return try await authorizer()
    }

    public func invalidate() async throws-> Bool {
        return try await invalidator()
    }

    private let authorizer: () async throws -> [Authorization]
    private let invalidator: () async throws-> Bool
}
