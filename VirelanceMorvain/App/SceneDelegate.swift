import UIKit
import SwiftUI
import AppTrackingTransparency
import AppsFlyerLib

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = GateRootFactory.shared.makeRootViewController()
        window?.makeKeyAndVisible()
        handleDeepLinkConnectionOptions(connectionOptions)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        AppsFlyerLib.shared().handleOpen(url, options: nil)
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        AppsFlyerLib.shared().continue(userActivity, restorationHandler: nil)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        requestTrackingAuthorizationIfNeeded()
        routePendingPushURLIfNeeded(in: scene)
    }

    private func requestTrackingAuthorizationIfNeeded() {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ATTrackingManager.requestTrackingAuthorization { _ in }
        }
    }

    private func handleDeepLinkConnectionOptions(_ options: UIScene.ConnectionOptions) {
        if let urlContext = options.urlContexts.first {
            AppsFlyerLib.shared().handleOpen(urlContext.url, options: nil)
        }
        if let activity = options.userActivities.first {
            AppsFlyerLib.shared().continue(activity, restorationHandler: nil)
        }
    }

    private func routePendingPushURLIfNeeded(in scene: UIScene) {
        guard let windowScene = scene as? UIWindowScene else { return }
        guard let url = PushDeepLinkBuffer.shared.consumePendingURL() else { return }

        let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first
        window?.rootViewController = PortalWebController(url: url)
    }
}
