//
//  File.swift
//  
//
//  Created by John Welch on 1/9/22.
//

import Foundation

public final class DecodableReceiver<T: Decodable>: Receivable {
    public typealias Result = T

    public init(decoder: JSONDecoder = JSONDecoder()) { self.decoder = decoder }

    public func transform(_ data: Data) async throws -> T {
        return try decoder.decode(T.self, from: data)
    }

    private let decoder: JSONDecoder
}

public final class EmptyReceiver: Receivable {
    public typealias Result = Void

    public init() { }

    public func transform(_ data: Data) async throws -> Void {
        return ()
    }
}
