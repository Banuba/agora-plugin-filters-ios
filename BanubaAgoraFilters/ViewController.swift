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
  @IBOutlet weak var toggleExtStateButton: UIButton!
  
  private var agoraKit: AgoraRtcEngineKit?
  private var isEnabled: Bool = false

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
    adjustUIState()
  }
    
  @IBAction func onToggleExtensionBtnPressed(_ sender: Any) {
    isEnabled.toggle()
    adjustUIState()
    
    agoraKit?.enableExtension(
      withVendor: BNBKeyVendorName,
      extension: BNBKeyExtensionName,
      enabled: isEnabled
    )
  }
  
  private func adjustUIState() {
    let toggleBtnTitle = isEnabled ? "Disable Ext" : "Enable Ext"
    toggleExtStateButton.setTitle(toggleBtnTitle, for: .normal)
  }
  
  private func setupEngine() {
    let config = AgoraRtcEngineConfig()
    config.appId = agoraAppID
    
    agoraKit = AgoraRtcEngineKit.sharedEngine(
      with: config,
      delegate: self
    )
    
    agoraKit?.enableExtension(
      withVendor: BNBKeyVendorName,
      extension: BNBKeyExtensionName,
      enabled: true
    )
    isEnabled = true
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
        print("[Agora] Did join channel")
      })
    if let result = result { print("[Agora] join result = \(result)") }
    agoraKit?.startPreview()
    agoraKit?.setEnableSpeakerphone(true)
  }
}

// MARK: - AgoraRtcEngineDelegate
extension ViewController: AgoraRtcEngineDelegate {
  func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
    print("[Agora] didJoinedOfUid \(uid)")
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
    print("[Agora] Error occured: AgoraErrorCode = \(errorCode)")
  }

  func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurWarning warningCode: AgoraWarningCode) {
    print("[Agora] Warning occured: AgoraWarningCode = \(warningCode)")
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
      agoraKit?.setExtensionPropertyWithVendor(BNBKeyVendorName,
                                               extension: BNBKeyExtensionName,
                                               key: BNBKeySetEffectsPath,
                                               value: BanubaEffectsManager.effectsURL.path)
      agoraKit?.setExtensionPropertyWithVendor(BNBKeyVendorName,
                                               extension: BNBKeyExtensionName,
                                               key: BNBKeySetBanubaLicenseToken,
                                               value: banubaLicenseToken)
  }
  
  private func loadEffect(_ effectName: String) {
    agoraKit?.setExtensionPropertyWithVendor(
      BNBKeyVendorName,
      extension: BNBKeyExtensionName,
      key: BNBKeyLoadEffect,
      value: effectName
    )
  }
  
  private func unloadEffect() {
    agoraKit?.setExtensionPropertyWithVendor(
      BNBKeyVendorName,
      extension: BNBKeyExtensionName,
      key: BNBKeyUnloadEffect,
      value: " "
    )
  }
  
  /// To control BanubaEffectPlayer via json methods refer to this method
  private func sendJSONToBanubaPlugin(string: String) {
      agoraKit?.setExtensionPropertyWithVendor(
        BNBKeyVendorName,
        extension: BNBKeyExtensionName,
        key: BNBKeyEvalJSMethod,
        value: string
      )
  }
}
