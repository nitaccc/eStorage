//
//  SceneDelegate.swift
//  e2
//
//  Created by 李京樺 on 2024/2/3.
//

import Foundation
import SwiftUI
import UserNotifications

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            
//            let contentView = ContentView() //
            let contentView = MainView() //

            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
        
        // Request notification authorization
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification authorization granted")
            } else {
                print("Notification authorization denied")
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called when the scene is no longer active.
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from the background to the active state.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene is about to move from the active to the inactive state.
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
    }
}
