//
//  ViewController.swift
//  BanubaAgoraFilters
//
//  Created by Banuba on 20.07.21.
//

import UIKit
import AgoraRtcKit

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
  }
  
  private func setupEngine() {
    let config = AgoraRtcEngineConfig()
    config.appId = agoraAppID
    
    agoraKit = AgoraRtcEngineKit.sharedEngine(
      with: config,
      delegate: self
    )
    
    agoraKit?.enableExtension(
      withVendor: "Banuba",
      extension: "BanubaFilter",
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
    agoraKit?.joinChannel(byToken: agoraClientToken, channelId: agoraChannelId, info: nil, uid: 0, joinSuccess: { channel, uid, elapsed in
      print("Did join channel")
    })
    agoraKit?.startPreview()
    agoraKit?.setEnableSpeakerphone(true)
  }
}

// MARK: - AgoraRtcEngineDelegate
extension ViewController: AgoraRtcEngineDelegate {
  func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteVideoFrameOfUid uid: UInt, size: CGSize, elapsed: Int) {
    setupRemoteVideo(uid: uid)
  }
  
  private func setupRemoteVideo(uid: UInt) {
    let videoCanvas = AgoraRtcVideoCanvas()
    videoCanvas.uid = uid
    videoCanvas.view = remoteVideo
    videoCanvas.renderMode = .hidden
    agoraKit?.setupRemoteVideo(videoCanvas)
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
    EffectsService.shared.loadEffects(path: EffectsService.shared.path)
      .sorted()
      .forEach { effectName in
      guard let effectPreviewImage = EffectsService.shared.getEffectPreview(effectName) else {
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
  
  private func loadEffect(_ effectName: String) {
    agoraKit?.setExtensionPropertyWithVendor(
      "Banuba",
      extension: "BanubaFilter",
      key: "load_effect",
      value: effectName
    )
  }
  
  private func unloadEffect() {
    agoraKit?.setExtensionPropertyWithVendor(
      "Banuba",
      extension: "BanubaFilter",
      key: "unload_effect",
      value: " "
    )
  }
}
