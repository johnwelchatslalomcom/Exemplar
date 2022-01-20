//
//  File.swift
//  
//
//  Created by John Welch on 1/9/22.
//

import Foundation

public final class ConstantAuthorizer: Authorizer {
    public func authorize() async throws-> [Authorization] {
        return authorizations
        
    }

    public func invalidate() async throws -> Bool {
        return false
    }

    public init(_ authorizations: [Authorization]) {
        self.authorizations = authorizations
    }

    private let authorizations: [Authorization]
}

public final class ComposedAuthorizer<A: Authorizer, B: Authorizer>: Authorizer {
    public func authorize() async throws -> [Authorization] {
        async let first = a.authorize()
        async let second = b.authorize()
        let results = try await (first, second)
        return results.0 + results.1
    }
    
    public func invalidate() async throws -> Bool {
        async let first = a.invalidate()
        async let second = b.invalidate()
        let results = try await (first, second)
        return results.0 && results.1
    }
    
    public init(a: A, b: B) {
        self.a = a
        self.b = b
    }
    
    private let a: A
    private let b: B
}

public extension Authorization {
    func header() -> [String: String] {
        switch self {
        case .bearer(let token):
            return ["Authorization": "Bearer \(token)"]
        case .custom(let field, let token):
            return [field: token]
        }
    }
}

public extension Array where Element == Authorization {
    func headers() -> [String: String] {
        var results: [String: String] = [:]
        
        forEach { element in
            results.merge(element.header(), uniquingKeysWith: { original, _  in  original })
        }
        
        return results
    }
}
