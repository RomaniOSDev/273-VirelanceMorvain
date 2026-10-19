//
//  PushDeepLinkBuffer.swift
//  1TrulbargrovarStrinel
//
//  Extracts URL from push payload and stores one-time pending URL.
//

import Foundation

final class PushDeepLinkBuffer {
    static let shared = PushDeepLinkBuffer()

    private init() {}

    private var pendingURL: URL?

    func setPendingURL(_ url: URL) {
        pendingURL = url
    }

    func consumePendingURL() -> URL? {
        defer { pendingURL = nil }
        return pendingURL
    }

    /// Supports both payload shapes:
    /// - { "url": "https://..." }
    /// - { "data": { "url": "https://..." } }
    /// - { "message": { "data": { "url": "https://..." } } } (FCM HTTP v1 example shape)
    func extractURL(from userInfo: [AnyHashable: Any]) -> URL? {
        // 1) Top-level: { "url": "https://..." }
        if let url = parseURL(from: userInfo, key: "url") { return url }

        // 2) Top-level: { "data": { "url": "https://..." } }
        if let dataDict = userInfo["data"] as? [AnyHashable: Any],
           let url = parseURL(from: dataDict, key: "url") {
            return url
        }

        // 3) FCM HTTP v1 example shape: { "message": { "data": { "url": "https://..." } } }
        if let messageDict = userInfo["message"] as? [AnyHashable: Any] {
            // { "message": { "url": "..." } } (rare but harmless)
            if let url = parseURL(from: messageDict, key: "url") { return url }

            if let messageDataDict = messageDict["data"] as? [AnyHashable: Any],
               let url = parseURL(from: messageDataDict, key: "url") {
                return url
            }
        }

        // 4) Common string-key variants (some providers flatten custom keys)
        if let url = parseURL(from: userInfo, key: "gcm.notification.url") { return url }
        if let url = parseURL(from: userInfo, key: "custom.url") { return url }

        return nil
    }

    func extractMessageID(from userInfo: [AnyHashable: Any]) -> String? {
        if let value = parseString(from: userInfo, key: "message_id") {
            return value
        }
        if let dataDict = userInfo["data"] as? [AnyHashable: Any],
           let value = parseString(from: dataDict, key: "message_id") {
            return value
        }
        if let messageDict = userInfo["message"] as? [AnyHashable: Any] {
            if let value = parseString(from: messageDict, key: "message_id") {
                return value
            }
            if let messageDataDict = messageDict["data"] as? [AnyHashable: Any],
               let value = parseString(from: messageDataDict, key: "message_id") {
                return value
            }
        }
        return nil
    }

    private func parseURL(from dict: [AnyHashable: Any], key: String) -> URL? {
        guard let urlString = parseString(from: dict, key: key) else { return nil }
        return URL(string: urlString)
    }

    private func parseString(from dict: [AnyHashable: Any], key: String) -> String? {
        guard let raw = dict[key] else { return nil }
        if let string = raw as? String {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        if let number = raw as? NSNumber {
            return number.stringValue
        }
        return nil
    }
}
