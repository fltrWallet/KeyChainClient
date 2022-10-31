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
#if canImport(Security)
import Security

public struct KeyChainClientLiveSettingsStruct {
    public let KeyAccessibilityLevel: CFString
    public let KeyCreateFlags: SecAccessControlCreateFlags
    public let KeyPrefix: String

    public init(KeyAccessibilityLevel: CFString,
                KeyCreateFlags: SecAccessControlCreateFlags,
                KeyPrefix: String) {
        self.KeyAccessibilityLevel = KeyAccessibilityLevel
        self.KeyCreateFlags = KeyCreateFlags
        self.KeyPrefix = KeyPrefix
    }
}

public extension KeyChainClientLiveSettingsStruct {
    static let live: Self = .init(KeyAccessibilityLevel: kSecAttrAccessibleWhenUnlocked,
                                  KeyCreateFlags: [ .userPresence, ],
                                  KeyPrefix: "app.fltr.")
}

#if DEBUG
public var KeyChainClientLiveSettings: KeyChainClientLiveSettingsStruct = .live
#else
public let KeyChainClientLiveSettings: KeyChainClientLiveSettingsStruct = .live
#endif
#endif
