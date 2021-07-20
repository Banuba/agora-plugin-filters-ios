//
//  AppDelegate.swift
//  BanubaAgoraFilters
//
//  Created by Banuba on 20.07.21.
//

import UIKit
import BanubaEffectPlayer

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    setupEffectPlayer()
    
    let viewController = ViewController(nibName: "ViewController", bundle: nil)
    self.window = UIWindow(frame: UIScreen.main.bounds)
    self.window?.rootViewController = viewController
    self.window?.makeKeyAndVisible()
    
    return true
  }
  
  private func setupEffectPlayer() {
    let effectsPath = Bundle.main.bundleURL.appendingPathComponent("effects/", isDirectory: true).path
    let bundleRoot = Bundle.init(for: BNBEffectPlayer.self).bundlePath
    let dirs = [bundleRoot + "/bnb-resources", bundleRoot + "/bnb-res-ios"] + [effectsPath]
    BNBUtilityManager.initialize(
        dirs,
        clientToken: banubaClientToken.trimmingCharacters(in: .whitespacesAndNewlines)
    )
  }
}

