//
//  File.swift
//  
//
//  Created by John Welch on 1/10/22.
//

import REST
import XCTest

class ReceiverTests: XCTestCase {

    func testThatAnEmptyReceiverDiscardsData() async throws {
        let receiver = EmptyReceiver()
        let data = "test".data(using: .utf8)!
        
       try await receiver.transform(data)
    }
}
