//
//  File.swift
//  
//
//  Created by John Welch on 1/10/22.
//

import Foundation

public enum RequesterError: Error {
    case authorizationRequired
    case decodeFailure(error: Error)
    case noContent
    case invalid(message: String)
    case notAcceptable
    case responseConflict(existingResponseId: String?, data: Data?)
    case responseFailure(code: Int, message: String, data: Data?)
    case serverFailure(code: Int, data: Data?)
    case serviceUnavailable
    case unrecognizedNetworkError(error: Error)
    case unsupportedURL(url: URL)
    case requestTimeout
}

/**
 *  This protocol defines a generic service for network requests.
 */
public protocol Requester {
    // The type of the object used to configure the request.
    associatedtype ConfigurationType

    /// The type of the authorizing object
    associatedtype AuthorizerType: Authorizer

    /// The authorizer instance.
    var authorizer: AuthorizerType { get }

    // Send a network request generated from a convertable object.
    ///
    /// - Parameters:
    ///   - request: The object representing the network request.
    ///   - receiver: The receiver processes the request result into a desired type.
    /// - Returns a publisher for the receivable type
    func send<Request: Requestable, Receiver: Receivable>(request: Request, receiver: Receiver) async throws -> Receiver.Result where Request.ConfigurationType == ConfigurationType
}

public struct AnyRequester<C, A: Authorizer>: Requester {
    public typealias ConfigurationType = C
    public typealias AuthorizerType = A

    public var authorizer: AuthorizerType

    public init<R: Requester>(_ base: R) where R.ConfigurationType == ConfigurationType, R.AuthorizerType == AuthorizerType {
        box = AnyRequesterBox(base)
        authorizer = base.authorizer
    }

    public func send<Request: Requestable, Receiver: Receivable>(request: Request, receiver: Receiver) async throws -> Receiver.Result where Request.ConfigurationType == ConfigurationType {
        return try await box.send(request: request, receiver: receiver)
    }

    private let box: AnyRequesterBoxBase<C, A>
}

private class AnyRequesterBoxBase<C, A: Authorizer>: Requester {
    typealias ConfigurationType = C
    typealias AuthorizerType = A

    let authorizer: AuthorizerType

    init(authorizer: A) {
        self.authorizer = authorizer
    }

    func send<Request: Requestable, Receiver: Receivable>(request: Request, receiver: Receiver) async throws -> Receiver.Result where Request.ConfigurationType == ConfigurationType {
        fatalError()
    }
}

private final class AnyRequesterBox<R: Requester>: AnyRequesterBoxBase<R.ConfigurationType, R.AuthorizerType> {
    typealias ConfigurationType = R.ConfigurationType
    typealias AuthorizerType = R.AuthorizerType

    private let erased: R

    init(_ base: R) {
        erased = base
        super.init(authorizer: base.authorizer)
    }

    override func send<Request: Requestable, Receiver: Receivable>(request: Request, receiver: Receiver) async throws -> Receiver.Result where Request.ConfigurationType == ConfigurationType {
        return try await erased.send(request: request, receiver: receiver)
    }
}
