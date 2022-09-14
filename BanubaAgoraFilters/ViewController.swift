//
//  ViewController.swift
//  BanubaAgoraFilters
//
//  Created by Banuba on 20.07.21.
//

import UIKit
import AgoraRtcKit
import BanubaFiltersAgoraExtension

private struct Defaults {
  static let renderSize = AgoraVideoDimension640x480
}

class ViewController: UIViewController {
  
  @IBOutlet weak var remoteVideo: UIView!
  @IBOutlet weak var localVideo: UIView!
  @IBOutlet weak var effectSelectorView: BanubaEffectSelectorView!
  
  private var agoraKit: AgoraRtcEngineKit?

  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupEngine()
    setupVideo()
    setupLocalVideo()
    setupEffectSelectorView()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    joinChannel()
    setupBanubaPlugin()
  }
  
  private func setupEngine() {
    let config = AgoraRtcEngineConfig()
    config.appId = agoraAppID
    
    agoraKit = AgoraRtcEngineKit.sharedEngine(
      with: config,
      delegate: self
    )
    
    agoraKit?.enableExtension(
      withVendor: BanubaPluginKeys.vendorName,
      extension: BanubaPluginKeys.extensionName,
      enabled: true
    )
  }
  
  private func setupVideo() {
    agoraKit?.setChannelProfile(.liveBroadcasting)
    agoraKit?.setClientRole(.broadcaster)
    agoraKit?.enableVideo()
    
    let encoderConfig = AgoraVideoEncoderConfiguration(
      size: Defaults.renderSize,
      frameRate: .fps30,
      bitrate: AgoraVideoBitrateStandard,
      orientationMode: .adaptative,
      mirrorMode: .auto
    )
    
    agoraKit?.setVideoEncoderConfiguration(encoderConfig)
  }
  
  private func setupLocalVideo() {
    let videoCanvas = AgoraRtcVideoCanvas()
    // UID = 0 means we let Agora pick a UID for us
    videoCanvas.uid = 0
    videoCanvas.view = localVideo
    videoCanvas.renderMode = .hidden
    videoCanvas.mirrorMode = .disabled
    agoraKit?.setupLocalVideo(videoCanvas)
  }
  
  private func joinChannel() {
    let result = agoraKit?.joinChannel(
      byToken: agoraClientToken,
      channelId: agoraChannelId,
      info: nil,
      uid: 0,
      joinSuccess: { channel, uid, elapsed in
        print("Did join channel")
      })
    if let result = result { print("join result = \(result)") }
    agoraKit?.startPreview()
    agoraKit?.setEnableSpeakerphone(true)
  }
}

// MARK: - AgoraRtcEngineDelegate
extension ViewController: AgoraRtcEngineDelegate {
  func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
    print("didJoinedOfUid \(uid)")
    setupRemoteVideo(uid: uid)
  }
  
  private func setupRemoteVideo(uid: UInt) {
    let videoCanvas = AgoraRtcVideoCanvas()
    videoCanvas.uid = uid
    videoCanvas.view = remoteVideo
    videoCanvas.renderMode = .hidden
    agoraKit?.setupRemoteVideo(videoCanvas)
  }

  func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
    print("Agora error occured: AgoraErrorCode = \(errorCode)")
  }

  func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurWarning warningCode: AgoraWarningCode) {
    print("Agora warning occured: AgoraWarningCode = \(warningCode)")
  }
}

// MARK: - EffectSelectorView
extension ViewController {
  private func setupEffectSelectorView() {
    let resetEffectViewModel = EffectViewModel(
      image: UIImage(named: "no_effect")!,
      effectName: nil
    )
    var effectViewModels = [resetEffectViewModel]
    let effectsPath = BanubaEffectsManager.effectsURL.path
    let effectsService = EffectsService(effectsPath: effectsPath)
    
    effectsService
      .getEffectNames()
      .sorted()
      .forEach { effectName in
        guard let effectPreviewImage = effectsService.getEffectPreview(effectName) else {
          return
        }
        effectViewModels.append(EffectViewModel(image: effectPreviewImage, effectName: effectName))
      }
    effectSelectorView.effectViewModels = effectViewModels
    effectSelectorView.didSelectEffectViewModel = { [weak self] effectModel in
      if let effectName = effectModel.effectName {
        self?.loadEffect(effectName)
      } else {
        self?.unloadEffect()
      }
    }
    effectSelectorView.selectedEffectViewModel = effectViewModels.first
  }
}

// MARK: - BanubaFilterPlugin interactions
extension ViewController {
  private func setupBanubaPlugin() {
      agoraKit?.setExtensionPropertyWithVendor(BanubaPluginKeys.vendorName,
                                               extension: BanubaPluginKeys.extensionName,
                                               key: BanubaPluginKeys.setEffectsPath,
                                               value: BanubaEffectsManager.effectsURL.path)
      // TODO remove separate client token as App Secret should hold its value
      let clientToken = banubaClientToken.trimmingCharacters(in: .whitespacesAndNewlines)
      agoraKit?.setExtensionPropertyWithVendor(BanubaPluginKeys.vendorName,
                                               extension: BanubaPluginKeys.extensionName,
                                               key: BanubaPluginKeys.setToken,
                                               value: clientToken)
      
      agoraKit?.setExtensionPropertyWithVendor(BanubaPluginKeys.vendorName,
                                               extension: BanubaPluginKeys.extensionName,
                                               key: BanubaPluginKeys.setAppKey,
                                               value: appKey)
      agoraKit?.setExtensionPropertyWithVendor(BanubaPluginKeys.vendorName,
                                               extension: BanubaPluginKeys.extensionName,
                                               key: BanubaPluginKeys.setAppSecret,
                                               value: appSecret)
  }
  
  private func loadEffect(_ effectName: String) {
    agoraKit?.setExtensionPropertyWithVendor(
      BanubaPluginKeys.vendorName,
      extension: BanubaPluginKeys.extensionName,
      key: BanubaPluginKeys.loadEffect,
      value: effectName
    )
  }
  
  private func unloadEffect() {
    agoraKit?.setExtensionPropertyWithVendor(
      BanubaPluginKeys.vendorName,
      extension: BanubaPluginKeys.extensionName,
      key: BanubaPluginKeys.unloadEffect,
      value: " "
    )
  }
  
  /// To control BanubaEffectPlayer via json methods refer to this method
  private func sendJSONToBanubaPlugin(string: String) {
      agoraKit?.setExtensionPropertyWithVendor(
        BanubaPluginKeys.vendorName,
        extension: BanubaPluginKeys.extensionName,
        key: BanubaPluginKeys.evalJSMethod,
        value: string
      )
  }
}
