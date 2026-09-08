//
//  GateRootFactory.swift
//  1TrulbargrovarStrinel
//
//  Загрузочный менеджер: при старте показывает GateHostController, который запрашивает конфиг
//  и затем переключает на ContentView или PortalWebController в зависимости от ответа сервера.
//

import UIKit
import SwiftUI

/// Менеджер выбора стартового экрана при запуске приложения.
final class GateRootFactory {

    static let shared = GateRootFactory()

    private init() {}

    /// Возвращает корневой контроллер: экран загрузки, который запрашивает конфиг и затем
    /// переходит на ContentView или PortalWebController (с сохранённой или новой ссылкой).
    func makeRootViewController() -> UIViewController {
        return GateHostController()
    }
}
