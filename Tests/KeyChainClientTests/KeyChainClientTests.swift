//===----------------------------------------------------------------------===//
//
// This source file is part of the KeyChainClient open source project
//
// Copyright (c) 2022 fltrWallet AG and the KeyChainClient project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
import XCTest
import KeyChainClientTest

final class KeyChainClientTests: XCTestCase {
    var client: KeyChainClient!
    
    override func setUp() {
        self.client = .dict
    }
    
    func testPutExistsGet() {
        let data: [UInt8] = Array("whatever floats 🌊 your boat ⛵️"
                                    .decomposedStringWithCanonicalMapping.utf8)
        self.client.put(key: "test", data: data) as Void
        
        XCTAssertTrue(self.client.exists(key: "test"))
        
        XCTAssertNoThrow(
            XCTAssertEqual(try self.client.get(key: "test") as [UInt8], data)
        )
    }
    
    func testEncryptionKey() {
        KeyChainClientAPISettings = .init(EncryptionKey: [0])
        let data: [UInt8] = Array("test encrypted data changing key 🏐"
                                    .decomposedStringWithCanonicalMapping.utf8)
        let _: Void = self.client.put(key: "a", data: data)
        
        KeyChainClientAPISettings = .init(EncryptionKey: [0, 0])
        XCTAssertThrowsError(try self.client.get(key: "a") as [UInt8]) { error in
            switch error {
            case KeyChainClient.Error.decryptionFailed: break
            default: XCTFail()
            }
        }

        KeyChainClientAPISettings = .init(EncryptionKey: [0])
        XCTAssertEqual(data, try? self.client.get(key: "a") as [UInt8])
    }
    
    func testSkip() throws {
        throw XCTSkip("Must also run platform specific tests for KeyChain entitlements (KeyChainClient_iOSTests)")
    }
}
