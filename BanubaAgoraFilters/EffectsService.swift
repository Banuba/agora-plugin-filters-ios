//
//  EffectsService.swift
//  BanubaAgoraFilters
//
//  Created by Banuba on 27.08.21.
//

import Foundation

class EffectsService {
  
  static let shared = EffectsService()
  
  let fm = FileManager.default
  let path = Bundle.main.bundlePath + "/effects"
  
  func loadEffects(path: String) -> [String] {
    do {
      return try fm.contentsOfDirectory(atPath: path)
        .filter { content in
          var isDir: ObjCBool = false
          return fm.fileExists(atPath: path + "/" + content, isDirectory: &isDir)
        }
    } catch {
      print("\(error)")
      return []
    }
  }
  
  func getEffectPreview(_ effectName: String) -> UIImage? {
    let previewPath = path + "/" + effectName + "/preview.png"
    return UIImage(contentsOfFile: previewPath)
  }
}
