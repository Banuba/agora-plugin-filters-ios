//
//  EffectsService.swift
//  BanubaAgoraFilters
//
//  Created by Banuba on 27.08.21.
//

import Foundation

class EffectsService {
  
  let manager = FileManager.default
  let effectsPath: String
  
  init(effectsPath: String) {
    self.effectsPath = effectsPath
  }
  
  func getEffectNames() -> [String] {
    do {
      return try manager.contentsOfDirectory(atPath: effectsPath)
        .filter { content in
          var isDir: ObjCBool = false
          return manager.fileExists(atPath: effectsPath + "/" + content, isDirectory: &isDir)
        }
    } catch {
      print("\(error)")
      return []
    }
  }
  
  func getEffectPreview(_ effectName: String) -> UIImage? {
    let previewPath = effectsPath + "/" + effectName + "/preview.png"
    return UIImage(contentsOfFile: previewPath)
  }
}
