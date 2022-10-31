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
import NIOCore
import NIOPosix

public extension KeyChainClient {
    @inlinable
    func exists(key: String,
                threadPool: NIOThreadPool,
                eventLoop: EventLoop) -> EventLoopFuture<Bool> {
        threadPool.runIfActive(eventLoop: eventLoop) {
            self.exists(key: key)
        }
    }
    
    @inlinable
    func get(key: String,
             threadPool: NIOThreadPool,
             eventLoop: EventLoop) -> EventLoopFuture<[UInt8]> {
        threadPool.runIfActive(eventLoop: eventLoop) {
            try self.get(key: key)
        }
    }
    
    @inlinable
    func put(key: String,
             data: [UInt8],
             threadPool: NIOThreadPool,
             eventLoop: EventLoop) -> EventLoopFuture<Void> {
        threadPool.runIfActive(eventLoop: eventLoop) {
            self.put(key: key, data: data)
        }
    }

    @inlinable
    func put(system key: String,
             data: [UInt8],
             threadPool: NIOThreadPool,
             eventLoop: EventLoop) -> EventLoopFuture<Void> {
        threadPool.runIfActive(eventLoop: eventLoop) {
            self.put(system: key, data: data)
        }
    }
}
