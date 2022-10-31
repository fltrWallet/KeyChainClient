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
import Combine
import Dispatch
import NIOCore
import NIOPosix
import KeyChainClientAsync
import KeyChainClientTest
import XCTest

final class KeyChainClientAsyncTests: XCTestCase {
    var client: KeyChainClient!
    var elg: MultiThreadedEventLoopGroup!
    var eventLoop: EventLoop!
    var threadPool: NIOThreadPool!
    var queue: DispatchQueue!
    
    override func setUp() {
        KeyChainClientAPISettings = .init(EncryptionKey: [1, 2, 3,])
        
        self.client = .dict
        let elg = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.eventLoop = elg.next()
        self.elg = elg
        self.threadPool = NIOThreadPool(numberOfThreads: 1)
        self.threadPool.start()
        self.queue = DispatchQueue(label: "test")
    }
    
    override func tearDown() {
        XCTAssertNoThrow(try self.threadPool.syncShutdownGracefully())
        self.threadPool = nil
        XCTAssertNoThrow(try self.elg.syncShutdownGracefully())
        self.eventLoop = nil
        self.elg = nil
        self.client = nil
        self.queue = nil
    }
    
    // MARK: Combine
    func testCombinePutExistsGet() {
        var c: Set<AnyCancellable> = .init()

        let data = (64..<96).map { UInt8($0) }

        let e1 = expectation(description: "")
        self.client.put(key: "alfa", data: data).sink {
            e1.fulfill()
        }
        .store(in: &c)
        let e2 = expectation(description: "")
        self.client.put(key: "beta", data: data + data).sink {
            e2.fulfill()
        }
        .store(in: &c)
        let e3 = expectation(description: "")
        self.client.put(key: "gamma", data: data + data + data).sink {
            e3.fulfill()
        }
        .store(in: &c)
        let e4 = expectation(description: "")
        self.client.put(key: "delta", data: data + data + data + data).sink {
            e4.fulfill()
        }
        .store(in: &c)
        wait(for: [e1, e2, e3, e4], timeout: 2.0)
        
        let ee1 = expectation(description: "")
        self.client.exists(key: "alfa").sink {
            XCTAssert($0)
            ee1.fulfill()
        }
        .store(in: &c)
        let ee2 = expectation(description: "")
        self.client.exists(key: "beta").sink {
            XCTAssert($0)
            ee2.fulfill()
        }
        .store(in: &c)
        let ee3 = expectation(description: "")
        self.client.exists(key: "gamma").sink {
            XCTAssert($0)
            ee3.fulfill()
        }
        .store(in: &c)
        let ee4 = expectation(description: "")
        self.client.exists(key: "delta").sink {
            XCTAssert($0)
            ee4.fulfill()
        }
        .store(in: &c)
        wait(for: [ee1, ee2, ee3, ee4], timeout: 2.0)
        
        let eee1 = expectation(description: "")
        self.client.get(key: "alfa").sink(receiveCompletion: {
            switch $0 {
            case .finished: eee1.fulfill()
            case .failure: XCTFail()
            }
        }, receiveValue: {
            XCTAssertEqual(data, $0)
        })
        .store(in: &c)
        let eee2 = expectation(description: "")
        self.client.get(key: "beta").sink(receiveCompletion: {
            switch $0 {
            case .finished: eee2.fulfill()
            case .failure: XCTFail()
            }
        }, receiveValue: {
            XCTAssertEqual(data + data, $0)
        })
        .store(in: &c)
        let eee3 = expectation(description: "")
        self.client.get(key: "gamma").sink(receiveCompletion: {
            switch $0 {
            case .finished: eee3.fulfill()
            case .failure: XCTFail()
            }
        }, receiveValue: {
            XCTAssertEqual(data + data + data, $0)
        })
        .store(in: &c)
        let eee4 = expectation(description: "")
        self.client.get(key: "delta").sink(receiveCompletion: {
            switch $0 {
            case .finished: eee4.fulfill()
            case .failure: XCTFail()
            }
        }, receiveValue: {
            XCTAssertEqual(data + data + data + data, $0)
        })
        .store(in: &c)
        wait(for: [eee1, eee2, eee3, eee4], timeout: 2.0)
    }
    
    func testCombineNotFound() {
        var c: Set<AnyCancellable> = .init()
        
        let e1 = expectation(description: "")
        self.client.exists(key: "none").sink {
            XCTAssertFalse($0)
            e1.fulfill()
        }
        .store(in: &c)
        wait(for: [e1], timeout: 2.0)
        
        let e2 = expectation(description: "")
        self.client.get(key: "none").sink(
            receiveCompletion: {
                e2.fulfill()
                switch $0 {
                case .failure(KeyChainClient.Error.notFound): break
                default: XCTFail()
                }
            }, receiveValue: { _ in
                XCTFail()
            }
        )
        .store(in: &c)
        wait(for: [e2], timeout: 2.0)
    }

    // MARK: Dispatch
    func testDispatchPutExistsGet() {
        let data = (32..<64).reversed().map { UInt8($0) }
        
        let e1 = expectation(description: "")
        self.client.put(key: "alfa",
                        data: data,
                        queue: self.queue) {
            e1.fulfill()
        }
        let e2 = expectation(description: "")
        self.client.put(key: "beta",
                        data: data + data,
                        queue: self.queue) {
            e2.fulfill()
        }
        let e3 = expectation(description: "")
        self.client.put(key: "gamma",
                        data: data + data + data,
                        queue: self.queue) {
            e3.fulfill()
        }
        let e4 = expectation(description: "")
        self.client.put(key: "delta",
                        data: data + data + data + data,
                        queue: self.queue) {
            e4.fulfill()
        }
        wait(for: [e1, e2, e3, e4], timeout: 2.0)

        let ee1 = expectation(description: "")
        self.client.exists(key: "alfa", queue: self.queue) {
            XCTAssert($0)
            ee1.fulfill()
        }
        let ee2 = expectation(description: "")
        self.client.exists(key: "beta", queue: self.queue) {
            XCTAssert($0)
            ee2.fulfill()
        }
        let ee3 = expectation(description: "")
        self.client.exists(key: "gamma", queue: self.queue) {
            XCTAssert($0)
            ee3.fulfill()
        }
        let ee4 = expectation(description: "")
        self.client.exists(key: "delta", queue: self.queue) {
            XCTAssert($0)
            ee4.fulfill()
        }
        wait(for: [ee1, ee2, ee3, ee4], timeout: 2.0)
        
        let eee1 = expectation(description: "")
        self.client.get(key: "alfa", queue: self.queue) {
            XCTAssertEqual(data, try? $0.get())
            eee1.fulfill()
        }
        let eee2 = expectation(description: "")
        self.client.get(key: "beta", queue: self.queue) {
            XCTAssertEqual(data + data, try? $0.get())
            eee2.fulfill()
        }
        let eee3 = expectation(description: "")
        self.client.get(key: "gamma", queue: self.queue) {
            XCTAssertEqual(data + data + data, try? $0.get())
            eee3.fulfill()
        }
        let eee4 = expectation(description: "")
        self.client.get(key: "delta", queue: self.queue) {
            XCTAssertEqual(data + data + data + data, try? $0.get())
            eee4.fulfill()
        }
        wait(for: [eee1, eee2, eee3, eee4], timeout: 2.0)
    }
    
    func testDispatchNotFound() {
        let e1 = expectation(description: "")
        self.client.exists(key: "none", queue: self.queue) {
            XCTAssertFalse($0)
            e1.fulfill()
        }
        
        let e2 = expectation(description: "")
        self.client.get(key: "none", queue: self.queue) {
            switch $0 {
            case .failure(KeyChainClient.Error.notFound): break
            default: XCTFail()
            }
            e2.fulfill()
        }
        wait(for: [e1, e2], timeout: 2.0)
    }
    
    // MARK: NIO
    func testNIOPutExistsGet() {
        let data = (0..<32).map { UInt8($0) }
        
        XCTAssertNoThrow(
            try self.client.put(key: "alfa",
                                data: data,
                                threadPool: self.threadPool,
                                eventLoop: self.eventLoop).wait()
        )
        XCTAssertNoThrow(
            try self.client.put(key: "beta",
                                data: data + data,
                                threadPool: self.threadPool,
                                eventLoop: self.eventLoop).wait()
        )
        XCTAssertNoThrow(
            try self.client.put(key: "gamma",
                                data: data + data + data,
                                threadPool: self.threadPool,
                                eventLoop: self.eventLoop).wait()
        )
        XCTAssertNoThrow(
            try self.client.put(key: "delta",
                                data: data + data + data + data,
                                threadPool: self.threadPool,
                                eventLoop: self.eventLoop).wait()
        )
        
        XCTAssertNoThrow(
            XCTAssert(try self.client.exists(key: "alfa",
                                             threadPool: self.threadPool,
                                             eventLoop: self.eventLoop).wait())
        )
        XCTAssertNoThrow(
            XCTAssert(try self.client.exists(key: "beta",
                                             threadPool: self.threadPool,
                                             eventLoop: self.eventLoop).wait())
        )
        XCTAssertNoThrow(
            XCTAssert(try self.client.exists(key: "gamma",
                                             threadPool: self.threadPool,
                                             eventLoop: self.eventLoop).wait())
        )
        XCTAssertNoThrow(
            XCTAssert(try self.client.exists(key: "delta",
                                             threadPool: self.threadPool,
                                             eventLoop: self.eventLoop).wait())
        )
        XCTAssertNoThrow(
            XCTAssertEqual(data,
                           try self.client.get(key: "alfa",
                                               threadPool: self.threadPool,
                                               eventLoop: self.eventLoop).wait())
        )
        XCTAssertNoThrow(
            XCTAssertEqual(data + data,
                           try self.client.get(key: "beta",
                                               threadPool: self.threadPool,
                                               eventLoop: self.eventLoop).wait())
        )
        XCTAssertNoThrow(
            XCTAssertEqual(data + data + data,
                           try self.client.get(key: "gamma",
                                               threadPool: self.threadPool,
                                               eventLoop: self.eventLoop).wait())
        )
        XCTAssertNoThrow(
            XCTAssertEqual(data + data + data + data,
                           try self.client.get(key: "delta",
                                               threadPool: self.threadPool,
                                               eventLoop: self.eventLoop).wait())
        )
    }
    
    func testNIONotFound() {
        XCTAssertNoThrow(
            XCTAssertFalse(try self.client.exists(key: "none",
                                                  threadPool: self.threadPool,
                                                  eventLoop: self.eventLoop).wait())
        )
        
        XCTAssertThrowsError(
            try self.client.get(key: "none",
                            threadPool: self.threadPool,
                            eventLoop: self.eventLoop).wait()
        ) { error in
            switch error {
            case KeyChainClient.Error.notFound:
                break
            default: XCTFail()
            }
        }
    }
}
