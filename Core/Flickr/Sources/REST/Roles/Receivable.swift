//
//  File.swift
//  
//
//  Created by John Welch on 1/9/22.
//

import Foundation

/// Represents the logic for translating data into specific entities and domain errors.
public protocol Receivable {
    associatedtype Result

    func transform(_ data: Data) async throws -> Result
}

public struct AnyReceivable<T>: Receivable {
    public typealias Result = T

    public init<R: Receivable>(_ base: R) where R.Result == T {
        transformer = { input in try await base.transform(input) }
    }

    public func transform(_ data: Data) async throws -> T {
        return try await transformer(data)
    }

    private let transformer: (Data) async throws -> T
}
