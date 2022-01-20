//
//  File.swift
//  
//
//  Created by John Welch on 1/9/22.
//

import Foundation

public enum JSON {
    public enum Patch {
        public enum Op: String, Encodable {
            case add
            case remove
            case replace
        }
        
        public struct Update: Encodable {
            let op: Op
            let path: String
            let value: Value
        }
    }
    
    public enum Value: Codable, Hashable {
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let value = try? container.decode([Value].self) {
                self = .array(value)
            } else if let value = try? container.decode(Double.self) {
                self = .double(value)
            } else if let value = try? container.decode([String: Value].self) {
                self = .object(value)
            } else if let value = try? container.decode(String.self) {
                self = .string(value)
            } else if let value = try? container.decode(Bool.self) {
                self = .bool(value)
            } else {
                self = .null
            }
        }
        
        case array([Value])
        case double(Double)
        case int64(Int64)
        case int(Int)
        case object([String: Value])
        case string(String)
        case bool(Bool)
        case null
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .array(let array): try container.encode(array)
            case .double(let double): try container.encode(double)
            case .int64(let int64): try container.encode(int64)
            case .int(let int): try container.encode(int)
            case .object(let object): try container.encode(object)
            case .string(let string): try container.encode(string)
            case .bool(let bool): try container.encode(bool)
            case .null: try container.encodeNil()
            }
        }
    }
}
