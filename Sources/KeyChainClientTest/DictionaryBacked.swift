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
@_implementationOnly import Foundation

public extension KeyChainClient {
    static let dict: Self = {
        var backend: [String : [UInt8]] = [:]
        var lock = os_unfair_lock()
        
        return .init(
            exists: { key in
                defer { os_unfair_lock_unlock(&lock) }
                os_unfair_lock_lock(&lock)
                
                return backend[key].map { _ in true } ?? false
            },
            get: { key in
                defer { os_unfair_lock_unlock(&lock) }
                os_unfair_lock_lock(&lock)

                guard let result = backend[key]
                else { throw Error.notFound }
                
                return result
            },
            put: { key, data, _ in
                defer { os_unfair_lock_unlock(&lock) }
                os_unfair_lock_lock(&lock)

                backend[key] = data
            })
    }()
}
