//
//  File.swift
//  BanubaAgoraFilters
//
//  Created by Andrei Sak on 19.11.21.
//

import Foundation

/// Banuba JS method wrapper
/// Use this struct to interact with BanubaFiltersAgoraPlugin
struct BanubaJSMethod: Codable {
  /// JSON method name
  let methodName: String
  /// JSON method params
  let methodParams: String
  
  init(methodName: String, methodParams: String) {
    self.methodName = methodName
    self.methodParams = methodParams
  }
}
