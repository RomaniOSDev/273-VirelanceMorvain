//
//  GateHostController.swift
//  1TrulbargrovarStrinel
//
//  Показывает загрузку в стиле приложения (градиент + анимированный индикатор), запрашивает конфиг,
//  затем переходит на ContentView или PortalWebController. Адаптируется под портрет и ландшафт.
//

import Network
import UIKit
import SwiftUI

/// Максимальное ожидание conversion data перед fallback (учитывает organic-retry AppsFlyer ~5 с).
private let conversionDataMaxWaitInterval: TimeInterval = 30
/// Глобальный таймаут загрузки (чуть больше ожидания attribution).
private let maxLoadingTimeInterval: TimeInterval = 35
/// Задержка перед стартом обычного config-flow (когда нет pending push URL).
private let ordinaryStartDelayInterval: TimeInterval = 5
/// Окно свежести conversion data: данные старше считаются устаревшими для config-запроса.
private let conversionDataFreshnessInterval: TimeInterval = 120

final class GateHostController: UIViewController {

    private let loadingHosting = UIHostingController(rootView: AnyView(GateSplashView()))
    private var didFinishTransition = false
    private var timeoutWorkItem: DispatchWorkItem?
    private var conversionWaitWorkItem: DispatchWorkItem?
    private var conversionObserver: NSObjectProtocol?
    private var didStartConfigRequest = false
    private var ordinaryStartWorkItem: DispatchWorkItem?
    private var networkMonitor: NWPathMonitor?
    private var isConfigFlowInProgress = false
    private var isShowingNoInternet = false
    private var hasEnteredOnlineConfigFlow = false
    private var isAwaitingConversionData = false
    private var didRetryConfigAfterFailure = false

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(loadingHosting)
        view.addSubview(loadingHosting.view)
        loadingHosting.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingHosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingHosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingHosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            loadingHosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        loadingHosting.didMove(toParent: self)
        subscribeToConversionDataNotifications()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startConfigFlow()
    }

    deinit {
        stopOfflineNetworkMonitoring()
    }

    private func startConfigFlow() {
        if didFinishTransition { return }
        if let pushURL = PushDeepLinkBuffer.shared.consumePendingURL() {
            ordinaryStartWorkItem?.cancel()
            ordinaryStartWorkItem = nil
            isConfigFlowInProgress = true
            didFinishTransition = true
            replaceRoot(with: PortalWebController(url: pushURL))
            return
        }

        if isShowingNoInternet {
            retryAfterNoInternet()
            return
        }

        guard !isConfigFlowInProgress, ordinaryStartWorkItem == nil else { return }
        isConfigFlowInProgress = true
        showLoadingState()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.ordinaryStartWorkItem = nil
            guard !self.didFinishTransition, self.isConfigFlowInProgress else { return }
            self.startConfigFlowWithoutPush()
        }
        ordinaryStartWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + ordinaryStartDelayInterval, execute: workItem)
    }

    private func retryAfterNoInternet() {
        guard !didFinishTransition else { return }
        stopOfflineNetworkMonitoring()
        isShowingNoInternet = false
        isConfigFlowInProgress = true
        hasEnteredOnlineConfigFlow = false
        didStartConfigRequest = false
        isAwaitingConversionData = false
        didRetryConfigAfterFailure = false
        showLoadingState()
        // Устаревшие данные из прошлой сессии сбрасываем, чтобы дождаться свежей атрибуции от SDK.
        ConversionPayloadStore.shared.clearConversionDataIfStale(olderThan: conversionDataFreshnessInterval)
        ConversionPayloadStore.shared.restartConversionFetch()
        startConfigFlowWithoutPush()
    }

    private func startConfigFlowWithoutPush() {
        if didFinishTransition { return }
        isConfigFlowInProgress = true
        showLoadingState()

        LinkPathMonitor.checkConnection { [weak self] isConnected in
            guard let self = self, !self.didFinishTransition else { return }
            if !isConnected {
                self.showNoInternetState()
                return
            }
            self.startConfigFlowWithInternet()
        }
    }

    private func startConfigFlowWithInternet() {
        if didFinishTransition { return }
        hasEnteredOnlineConfigFlow = true
        didStartConfigRequest = false

        timeoutWorkItem = DispatchWorkItem { [weak self] in
            self?.finishByTimeout()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + maxLoadingTimeInterval, execute: timeoutWorkItem!)

        if RemoteGateConfig.shared.isSavedURLValid, let url = RemoteGateConfig.shared.savedURL {
            cancelScheduledWork()
            transitionToWebView(url: url)
            return
        }

        waitForConversionDataThenRequestConfig()
    }

    private func showLoadingState() {
        loadingHosting.rootView = AnyView(GateSplashView())
    }

    private func showNoInternetState() {
        isShowingNoInternet = true
        isConfigFlowInProgress = false
        hasEnteredOnlineConfigFlow = false
        isAwaitingConversionData = false
        cancelScheduledWork()
        startOfflineNetworkMonitoring()
        loadingHosting.rootView = AnyView(
            OfflineGateView(
                onRetry: { [weak self] in
                    self?.retryAfterNoInternet()
                }
            )
        )
    }

    private func startOfflineNetworkMonitoring() {
        stopOfflineNetworkMonitoring()
        let monitor = NWPathMonitor()
        networkMonitor = monitor
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                guard let self,
                      self.isShowingNoInternet,
                      !self.didFinishTransition,
                      path.status == .satisfied else { return }
                ConversionPayloadStore.shared.restartConversionFetch()
            }
        }
        monitor.start(queue: DispatchQueue(label: "loading.offline.network"))
    }

    private func stopOfflineNetworkMonitoring() {
        networkMonitor?.cancel()
        networkMonitor = nil
    }

    private func subscribeToConversionDataNotifications() {
        guard conversionObserver == nil else { return }
        conversionObserver = NotificationCenter.default.addObserver(
            forName: .appsFlyerConversionDataReady,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleConversionDataReady()
        }
    }

    private func handleConversionDataReady() {
        guard !didFinishTransition else { return }

        if isShowingNoInternet {
            LinkPathMonitor.checkConnection { [weak self] isConnected in
                guard let self, isConnected else { return }
                self.retryAfterNoInternet()
            }
            return
        }

        guard hasEnteredOnlineConfigFlow, !didStartConfigRequest else { return }
        isAwaitingConversionData = false
        conversionWaitWorkItem?.cancel()
        conversionWaitWorkItem = nil
        performConfigRequest()
    }

    private func cancelScheduledWork() {
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
        ordinaryStartWorkItem?.cancel()
        ordinaryStartWorkItem = nil
        conversionWaitWorkItem?.cancel()
        conversionWaitWorkItem = nil
    }

    private func removeConversionObserver() {
        if let observer = conversionObserver {
            NotificationCenter.default.removeObserver(observer)
            conversionObserver = nil
        }
    }

    private func finishByTimeout() {
        guard !didFinishTransition else { return }
        if didStartConfigRequest { return }

        if ConversionPayloadStore.shared.conversionDataString != nil {
            performConfigRequest()
            return
        }

        isAwaitingConversionData = false
        transitionToContentViewOrSavedWebView()
    }

    private func performConfigRequest() {
        guard !didFinishTransition, !didStartConfigRequest else { return }

        guard ConversionPayloadStore.shared.conversionDataString != nil else {
            waitForConversionDataThenRequestConfig()
            return
        }

        didStartConfigRequest = true
        isAwaitingConversionData = false
        cancelScheduledWork()

        RemoteGateConfig.shared.requestConfig { [weak self] result in
            guard let self = self, !self.didFinishTransition else { return }
            switch result {
            case .success(let response):
                if response.ok, let urlString = response.url, let url = URL(string: urlString) {
                    self.removeConversionObserver()
                    self.transitionToWebView(url: url)
                } else {
                    self.handleConfigFailure()
                }
            case .failure:
                self.handleConfigFailure()
            }
        }
    }

    private func handleConfigFailure() {
        didStartConfigRequest = false

        if let url = RemoteGateConfig.shared.savedURL {
            removeConversionObserver()
            transitionToWebView(url: url)
            return
        }

        if isAwaitingConversionData {
            return
        }

        // Конфиг отклонил запрос. Если conversion data не свежие (могли быть неполными),
        // делаем одну повторную попытку: ждём реальную атрибуцию от SDK и шлём конфиг заново,
        // вместо мгновенного ухода в ContentView.
        if !didRetryConfigAfterFailure,
           !ConversionPayloadStore.shared.hasFreshConversionData(within: conversionDataFreshnessInterval) {
            didRetryConfigAfterFailure = true
            ConversionPayloadStore.shared.clearStoredConversionString()
            waitForConversionDataThenRequestConfig()
            return
        }

        removeConversionObserver()
        transitionToContentView()
    }

    private func waitForConversionDataThenRequestConfig() {
        subscribeToConversionDataNotifications()
        isAwaitingConversionData = true

        if ConversionPayloadStore.shared.conversionDataString != nil {
            isAwaitingConversionData = false
            performConfigRequest()
            return
        }

        ConversionPayloadStore.shared.restartConversionFetch()

        conversionWaitWorkItem?.cancel()
        conversionWaitWorkItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            guard !self.didFinishTransition, !self.didStartConfigRequest else { return }
            self.isAwaitingConversionData = false

            if ConversionPayloadStore.shared.conversionDataString != nil {
                self.performConfigRequest()
            } else {
                self.transitionToContentViewOrSavedWebView()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + conversionDataMaxWaitInterval, execute: conversionWaitWorkItem!)
    }

    private func transitionToContentViewOrSavedWebView() {
        stopOfflineNetworkMonitoring()
        removeConversionObserver()
        if let url = RemoteGateConfig.shared.savedURL {
            transitionToWebView(url: url)
        } else {
            transitionToContentView()
        }
    }

    private func transitionToWebView(url: URL) {
        stopOfflineNetworkMonitoring()
        AlertOptInCoordinator.shared.shouldShowCustomNotificationScreen { [weak self] shouldShow in
            guard let self = self, !self.didFinishTransition else { return }
            self.didFinishTransition = true
            self.removeConversionObserver()
            if shouldShow {
                let notificationVC = AlertOptInHostController(url: url, window: self.view.window)
                self.replaceRoot(with: notificationVC)
            } else {
                self.replaceRoot(with: PortalWebController(url: url))
            }
        }
    }

    private func transitionToContentView() {
        didFinishTransition = true
        stopOfflineNetworkMonitoring()
        removeConversionObserver()
        let content = UIHostingController(rootView: ContentView())
        replaceRoot(with: content)
    }

    private func replaceRoot(with vc: UIViewController) {
        guard let window = view.window else { return }
        window.rootViewController = vc
    }
}
