//
//  File.swift
//  
//
//  Created by John Welch on 1/9/22.
//

import Foundation

public enum Authorization: Equatable {
    case bearer(token: String)
    case custom(field: String, token: String)
}
