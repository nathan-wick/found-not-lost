//
//  IFoundItApp.swift
//  Shared
//
//  Created by Nathan Wick on 2/23/22.
//

import SwiftUI
import Firebase
import GoogleSignIn

@main
struct IFoundItApp: App {
    // Connect App Delegates
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    // Display Main Scene
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    // Intialze Firebase
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
    // Implement Google Sign In
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
      return GIDSignIn.sharedInstance.handle(url)
    }
}
