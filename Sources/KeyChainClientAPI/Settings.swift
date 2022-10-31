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
public struct KeyChainClientAPISettingsStruct {
    public let EncryptionKey: [UInt8]

    public init(EncryptionKey: [UInt8]) {
        self.EncryptionKey = EncryptionKey
    }
}

public extension KeyChainClientAPISettingsStruct {
    static let live: Self = .init(
        EncryptionKey: Array("🦊 The quick brown fox jumps over the lazy dog 🐶"
                                .decomposedStringWithCanonicalMapping
                                .utf8)
    )
}

#if DEBUG
public var KeyChainClientAPISettings: KeyChainClientAPISettingsStruct = .live
#else
public let KeyChainClientAPISettings: KeyChainClientAPISettingsStruct = .live
#endif
