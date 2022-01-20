//
//  File.swift
//  
//
//  Created by John Welch on 1/10/22.
//

import Foundation

public final class URLSessionRequester<C, A: Authorizer>: Requester {
    public typealias ConfigurationType = C
    public typealias AuthorizerType = A

    public let authorizer: AuthorizerType

    public init(configuration: ConfigurationType, authorizer: AuthorizerType, session: URLSession = URLSession.shared) {
        self.configuration = configuration
        self.authorizer = authorizer
        self.session = session
    }

    public func send<Request, Receiver>(request: Request, receiver: Receiver) async throws ->Receiver.Result where Request : Requestable, Receiver : Receivable, Request.ConfigurationType == ConfigurationType {

        let authorizations = try await authorizer.authorize()
        
        do {
            let request = try request.asURLRequest(configuration: configuration, authorizations: authorizations)
            let (data, response) = try await session.data(for: request)
            
            try await validate(response: response, data: data)

            return try await receiver.transform(data)
        } catch {            
            throw translate(error)
        }
    }

    private let configuration: ConfigurationType
    private let session: URLSession
}

private func validate(response: URLResponse, data: Data) async throws {
    guard let response = response as? HTTPURLResponse else { throw RequesterError.notAcceptable }
    
    switch response.statusCode {
    case 204: throw RequesterError.noContent
    case 401, 403: throw RequesterError.authorizationRequired
    case 400, 404, 415: throw RequesterError.responseFailure(code: response.statusCode, message: "Resource", data: data)
    case 406: throw RequesterError.notAcceptable
    case 409: throw RequesterError.responseConflict(existingResponseId: nil, data: data)
    case 408: throw RequesterError.requestTimeout
    case let code where code >= 400 && code < 500: throw RequesterError.invalid(message: "\(code)")
    case let code where code >= 500: throw RequesterError.serverFailure(code: code, data: data)
    default: break
    }
}

private func translate(_ error: Error) -> RequesterError {
    if let error = error as? RequesterError {
        return error
    }
    
    if error is DecodingError {
        return RequesterError.decodeFailure(error: error)
    }

    return .unrecognizedNetworkError(error: error)
}
