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
@_implementationOnly import CryptoKit
@_implementationOnly import Dispatch
@_implementationOnly import HaByLo

public struct KeyChainClient {
    @inlinable
    public init(exists: @escaping (String) -> Bool,
                get: @escaping (String) throws -> [UInt8],
                put: @escaping (String, [UInt8], ItemMode) -> Void) {
        self._exists = exists
        self._get = get
        self._put = put
    }
    
    @usableFromInline
    let _exists: (String) -> Bool
    
    @inlinable
    public func exists(key: String) -> Bool {
        let key = key.filter { !$0.isWhitespace && $0.isASCII }
        return self._exists(key)
    }
    
    @usableFromInline
    let _get: (String) throws -> [UInt8]
    
    public enum Error: Swift.Error, Hashable {
        case decryptionFailed
        case userCancelledOrFailedAuthentication
        case notFound
    }
    
    @inlinable
    public func get(key: String) throws -> [UInt8] {
        let key = key.filter { !$0.isWhitespace && $0.isASCII }
        let encrypted = try self._get(key)
        return try self.decrypt(encrypted, password: KeyChainClientAPISettings.EncryptionKey)
    }
    
    public enum ItemMode: Hashable {
        case system
        case userPresence
        case query
    }
    
    @usableFromInline
    let _put: (String, [UInt8], ItemMode) -> Void
    
    @inlinable
    public func put(key: String, data: [UInt8]) -> Void {
        let key = key.filter { !$0.isWhitespace && $0.isASCII }
        let encrypted = self.encrypt(data, password: KeyChainClientAPISettings.EncryptionKey)
        
        self._put(key, encrypted, .userPresence)
    }
    
    @inlinable
    public func put(system key: String, data: [UInt8]) -> Void {
        let key = key.filter { !$0.isWhitespace && $0.isASCII }
        let encrypted = self.encrypt(data, password: KeyChainClientAPISettings.EncryptionKey)
        
        self._put(key, encrypted, .system)
    }
}

extension KeyChainClient {
    @usableFromInline
    func encrypt(_ input: [UInt8], password: [UInt8]) -> [UInt8] {
        let symmetricKey = SymmetricKey(data: password.sha256)
        let data = try! ChaChaPoly.seal(input, using: symmetricKey).combined
        
        return Array(data)
    }
    
    @usableFromInline
    func decrypt(_ bytes: [UInt8], password: [UInt8]) throws -> [UInt8] {
        let symmetricKey = SymmetricKey(data: password.sha256)
        
        guard let sealedBox = try? ChaChaPoly.SealedBox(combined: bytes)
        else {
            preconditionFailure("encrypted data tampered with and cannot be decoded")
        }
        
        guard let decryptedData = try? ChaChaPoly.open(sealedBox, using: symmetricKey)
        else { throw Error.decryptionFailed }

        return Array(decryptedData)
    }
}
