//
//  NinjaNightApp.swift
//  NinjaNight
//
//  Created by 陳彥琮 on 2024/11/4.
//

import SwiftUI
import FirebaseCore

@main
struct NinjaNightApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}
