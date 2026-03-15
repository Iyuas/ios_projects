//
//  SceneDelegate.swift
//  NumberRush
//
//  Created by Serdaly Muhammed on 12.03.2026.
//


import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let baseURL = URL(string: "https://69b2fb29e224ec066bdb2f7f.mockapi.io/records")!
        let api = LeaderboardAPI(baseURL: baseURL)
        let viewModel = GameViewModel(api: api)
        let rootViewController = ViewController(viewModel: viewModel, api: api)

        window = UIWindow(windowScene: windowScene)
        window?.windowScene = windowScene
        window?.rootViewController = UINavigationController(rootViewController: rootViewController)
        window?.makeKeyAndVisible()
    }
}
