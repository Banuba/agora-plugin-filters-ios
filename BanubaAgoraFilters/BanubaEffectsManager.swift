//
//  BanubaEffectsManager.swift
//  BanubaAgoraFilters
//
//  Created by Banuba on 31.08.21.
//

import Foundation

class BanubaEffectsManager {
  /// Returns url to folder with Banuba effects
  static var effectsURL: URL {
    let effectsURL = Bundle.main.bundleURL.appendingPathComponent("effects/", isDirectory: true)
    return effectsURL
  }
}
