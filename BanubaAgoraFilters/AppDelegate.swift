//
//  AppDelegate.swift
//  BanubaAgoraFilters
//
//  Created by Banuba on 20.07.21.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let viewController = ViewController(nibName: "ViewController", bundle: nil)
    self.window = UIWindow(frame: UIScreen.main.bounds)
    self.window?.rootViewController = viewController
    self.window?.makeKeyAndVisible()
    
    return true
  }
}

