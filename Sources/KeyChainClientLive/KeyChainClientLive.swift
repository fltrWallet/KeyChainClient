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
@_implementationOnly import Foundation
import KeyChainClientAPI

#if canImport(LocalAuthentication)
@_implementationOnly import LocalAuthentication
#if canImport(Security)
import Security

extension KeyChainClient.ItemMode {
    var acl: SecAccessControl? {
        switch self {
        case .system:
            return SecAccessControlCreateWithFlags(nil,
                                                   kSecAttrAccessibleAfterFirstUnlock,
                                                   [],
                                                   nil)
        case .userPresence:
            return SecAccessControlCreateWithFlags(nil,
                                                   KeyChainClientLiveSettings.KeyAccessibilityLevel,
                                                   KeyChainClientLiveSettings.KeyCreateFlags,
                                                   nil)
        case .query:
            return nil
        }
    }

    @usableFromInline
    func dictionary(_ key: String, appending: () -> Dictionary<CFString, Any>) -> CFDictionary {
        self.dictionary(key, appending: appending())
    }
    
    @usableFromInline
    func dictionary(_ key: String, appending: Dictionary<CFString, Any> = [:]) -> CFDictionary {
        let dictionary = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Bundle.main.bundleIdentifier!,
            kSecAttrAccount: KeyChainClientLiveSettings.KeyPrefix + key,
        ]
        .merging(self.acl.map { [ kSecAttrAccessControl: $0 ] } ?? [:]) { _, new in new }
        .merging(appending) { _, new in new } as CFDictionary
        
        return dictionary
    }
}

public extension KeyChainClient {
    @discardableResult
    @usableFromInline
    internal static func deleteKeyChainItem(key: String) -> Bool {
        let query = KeyChainClient.ItemMode.query.dictionary(key)
        let status = SecItemDelete(query)
        
        switch status {
        case errSecSuccess: return true
        case errSecItemNotFound: return false
        default: return Self.fail(with: status)
        }
    }
    
    @usableFromInline
    internal static func fail<T>(with status: OSStatus, event: StaticString = #function) -> T {
        let errorMessage: (OSStatus) -> String = { status in
            SecCopyErrorMessageString(status, nil)
                as String?
                ?? "unknown"
        }
        
        preconditionFailure("during \(event)\n"
                                + "    status: \(status)\n"
                                + "    with error message: \(errorMessage(status))")
    }


    @usableFromInline
    internal static func exists(key: String) -> Bool {
        let laContext = LAContext()
        laContext.interactionNotAllowed = true
        
        let query = KeyChainClient.ItemMode.query.dictionary(key) {
            [ kSecUseAuthenticationContext: laContext, ]
        }
        
        var resultOptional: AnyObject?
        let status = SecItemCopyMatching(query, &resultOptional)
        
        switch status {
        case errSecSuccess, errSecInteractionNotAllowed:
            return true
        case errSecItemNotFound:
            return false
        default:
            return Self.fail(with: status)
        }
    }
    
    enum GetKeyChainOption {
        case `default`
        case biometric
        
        var isBiometric: Bool {
            switch self {
            case .default:
                return false
            case .biometric:
                return true
            }
        }
    }
    
    @usableFromInline
    internal static func isSystem(key: String) -> Bool {
        let laContext = LAContext()
        laContext.interactionNotAllowed = true

        let query = KeyChainClient.ItemMode.system.dictionary(key) {
            [ kSecMatchLimit: kSecMatchLimitOne,
              kSecUseAuthenticationContext: laContext, ]
        }
        
        var resultOptional: AnyObject?
        let status = SecItemCopyMatching(query, &resultOptional)
        
        switch status {
        case errSecSuccess, errSecInteractionNotAllowed:
            return true
        case errSecItemNotFound:
            return false
        default:
            return Self.fail(with: status)
        }
    }
    
    @usableFromInline
    internal static func getKeyChain(key: String, options: GetKeyChainOption) throws -> [UInt8] {
        let laContext = LAContext()
        
        let localizedReason = "Private Key Access"
        
        laContext.localizedReason = localizedReason
        laContext.localizedCancelTitle = "Cancel"
        laContext.localizedFallbackTitle = "Fallback"

        func authenticate(context: LAContext, with policy: LAPolicy) -> Bool {
            var error: NSError?
            guard context.canEvaluatePolicy(policy, error: &error)
            else {
                return false
            }

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                   localizedReason: localizedReason,
                                   reply: { _, _ in () })
            return true
        }
        
        switch options {
        case .biometric:
            guard !Self.isSystem(key: key)
            else {
                break
            }
        
            if authenticate(context: laContext, with: .deviceOwnerAuthenticationWithBiometrics) {
                break
            } else if authenticate(context: laContext, with: .deviceOwnerAuthentication) {
                break
            } else {
                throw Error.userCancelledOrFailedAuthentication
            }
        case .default:
            break
        }
        
        let query = KeyChainClient.ItemMode.query.dictionary(key) {
            [ kSecMatchLimit: kSecMatchLimitOne,
              kSecReturnData: true,
              kSecUseAuthenticationContext: laContext, ]
        }
        
        var resultOptional: AnyObject?
        let status = SecItemCopyMatching(query, &resultOptional)

        switch status {
        case errSecSuccess:
            guard let data = resultOptional as? Data
            else {
                return Self.fail(with: status)
            }

            return Array(data)
        case errSecItemNotFound:
            throw KeyChainClient.Error.notFound
        case errSecAuthFailed, errSecUserCanceled:
            throw KeyChainClient.Error.userCancelledOrFailedAuthentication
        default:
            return Self.fail(with: status)
        }
        
    }
    
    @usableFromInline
    internal static func putKeyChain(key: String, data: [UInt8], mode: KeyChainClient.ItemMode) {
        Self.deleteKeyChainItem(key: key)

        let query = mode.dictionary(key) {
            [ kSecValueData: Data(data),
              kSecReturnData: true, ]
        }
        
        var result: AnyObject?
        let status = SecItemAdd(query, &result)

        guard let _ = result, status == errSecSuccess
        else {
            return Self.fail(with: status)
        }
    }
    
    static let biometric: Self = .init(exists: Self.exists(key:),
                                       get: { try Self.getKeyChain(key: $0, options: .biometric) },
                                       put: Self.putKeyChain(key:data:mode:))
    
    static let passcode: Self = .init(exists: Self.exists(key:),
                                      get: { try Self.getKeyChain(key: $0, options: .default) },
                                      put: Self.putKeyChain(key:data:mode:))
}

#endif
#endif
