//
//  AlertOptInCoordinator.swift
//  1TrulbargrovarStrinel
//
//  Stores when the user declined the custom notification screen.
//  Custom screen is hidden for 3 days after decline.
//

import Foundation
import UserNotifications

enum AlertOptInKeys {
    static let lastCustomDeclineDate = "AlertOptInLastDeclineDate"
    static let shouldSendTokenOnce = "AlertOptInShouldSendTokenOnce"
    static let acceptedOnce = "AlertOptInAcceptedOnce"
}

private let customDeclineCooldownDays: Int = 3

final class AlertOptInCoordinator {

    static let shared = AlertOptInCoordinator()

    private init() {}

    /// Call when user taps "Decline" on the custom notification screen.
    func recordCustomDecline() {
        UserDefaults.standard.set(Date(), forKey: AlertOptInKeys.lastCustomDeclineDate)
    }

    /// Call when user taps "Enable" and grants notifications at least once.
    func recordCustomAccept() {
        UserDefaults.standard.set(true, forKey: AlertOptInKeys.acceptedOnce)
    }

    /// Mark that after the next FCM token reception we should send config once with push token.
    func markShouldSendTokenOnce() {
        UserDefaults.standard.set(true, forKey: AlertOptInKeys.shouldSendTokenOnce)
    }

    /// Returns true once when a token-triggered config request should be sent, then resets the flag.
    func consumeShouldSendTokenOnce() -> Bool {
        let flag = UserDefaults.standard.bool(forKey: AlertOptInKeys.shouldSendTokenOnce)
        if flag {
            UserDefaults.standard.set(false, forKey: AlertOptInKeys.shouldSendTokenOnce)
        }
        return flag
    }

    /// Shows custom screen only if system permission is not determined and
    /// 3-day cooldown after custom "Skip" has passed.
    func shouldShowCustomNotificationScreen(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else {
                DispatchQueue.main.async { completion(false) }
                return
            }

            let shouldShow: Bool
            if let date = UserDefaults.standard.object(forKey: AlertOptInKeys.lastCustomDeclineDate) as? Date {
                let interval = Date().timeIntervalSince(date)
                let threeDays: TimeInterval = TimeInterval(customDeclineCooldownDays * 24 * 60 * 60)
                shouldShow = interval >= threeDays
            } else {
                shouldShow = true
            }
            DispatchQueue.main.async { completion(shouldShow) }
        }
    }
}
