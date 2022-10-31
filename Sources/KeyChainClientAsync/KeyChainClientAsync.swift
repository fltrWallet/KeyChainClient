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
import KeyChainClientAPI

#if canImport(Combine)
import Combine
#endif

#if canImport(Dispatch)
import Dispatch

public extension KeyChainClient {
    @inlinable
    func exists(key: String, queue: DispatchQueue, callback: @escaping (Bool) -> Void) {
        queue.async {
            callback(
                self.exists(key: key)
            )
        }
    }
    
    @inlinable
    func get(key: String, queue: DispatchQueue, callback: @escaping (Result<[UInt8], KeyChainClient.Error>) -> Void) {
        queue.async {
            callback(
                Result {
                    try self.get(key: key)
                }
                .mapError { $0 as! KeyChainClient.Error }
            )
        }
    }
    
    @inlinable
    func put(key: String, data: [UInt8], queue: DispatchQueue, callback: @escaping () -> Void) {
        queue.async {
            let _: Void = self.put(key: key, data: data)
            return callback()
        }
    }
    
    @inlinable
    func put(system key: String, data: [UInt8], queue: DispatchQueue, callback: @escaping () -> Void) {
        queue.async {
            let _: Void = self.put(system: key, data: data)
            return callback()
        }
    }
    
    #if canImport(Combine)
    @inlinable
    func exists(key: String) -> Deferred<Future<Bool, Never>> {
        Deferred {
            Future { promise in
                promise(
                    .success(
                        self.exists(key: key)
                    )
                )
            }
        }
    }
    
    @inlinable
    func get(key: String) -> Deferred<Future<[UInt8], Self.Error>> {
        Deferred {
            Future { promise in
                let result = Result { () throws -> [UInt8] in
                    try self.get(key: key)
                }
                .mapError { $0 as! KeyChainClient.Error }

                promise(result)
            }
        }
    }
    
    @inlinable
    func put(key: String, data: [UInt8]) -> Deferred<Future<Void, Never>> {
        Deferred {
            Future { promise in
                promise(
                    .success(
                        self.put(key: key, data: data)
                    )
                )
            }
        }
    }

    @inlinable
    func put(system key: String, data: [UInt8]) -> Deferred<Future<Void, Never>> {
        Deferred {
            Future { promise in
                promise(
                    .success(
                        self.put(system: key, data: data)
                    )
                )
            }
        }
    }
    #endif
}
#endif
