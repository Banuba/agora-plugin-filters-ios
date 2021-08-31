Examples for [Banuba SDK on iOS] and [Agora.io](https://www.agora.io/en/) SDK integration via Agora Plugin Filters to enhance video calls with real-time face filters and virtual backgrounds.

# Getting Started

1. Get
(a)the latest Banuba SDK archive,
(b)[BanubaFiltersAgoraExtension for iOS](https://f.hubspotusercontent10.net/hubfs/4992313/Agora_Banuba_Extension/AgoraBanubaExtension(iOS).zip),
(c) [Banuba trial client token](https://docs.agora.io/en/extension_customer/Banuba_downloads).
To receive full commercial licence from Banuba - please fill in our form on [form on banuba.com](https://www.banuba.com/face-filters-sdk) website, or contact us via [info@banuba.com](mailto:info@banuba.com).
2. Put received `BanubaEffectPlayer.xcframework` adn `BanubaFiltersAgoraExtension.framework` to “Frameworks, Libraries, and Embedded Content” section in your project.
3. Copy and Paste your Banuba client token into appropriate section of `/BanubaAgoraFilters/Token.swift` with “ ” symbols. For example: 
``` swift
let banubaClientToken = “place_your_banuba_token_here”
```
4. Visit agora.io to sign up and get token, app and channel ID.
5. Put received `Agoraffmpeg.framework` and `AgoraRtcKit.framework` to “Frameworks, Libraries, and Embedded Content” section in your project.

<img src="screenshots/screenshot_1.png" alt="Screenshot" width="100%" height="auto">&nbsp;

6. Copy and Paste your agora token, app and chanel ID into appropriate section of `/BanubaAgoraFilters/Token.swift` with “ ” symbols. For example: 
``` swift
internal let agoraAppID = "place_your_agora_app_id_here"
internal let agoraClientToken = "place_your_agora_client_token_here"
internal let agoraChannelId = "place_your_agora_channel_id_here"
```
7. Open the BanubaAgoraFilters.xcodporj project in Xcode and run the `BanubaAgoraFilters` target.


# How to use `BanubaFiltersAgoraExtension`

To control `BanubaFiltersAgoraExtension` with Agora libs look available keys listed below:
```swift
public struct BanubaPluginKeys {
  public static let vendorName = "Banuba"
  public static let extensionName = "BanubaFilter"
  public static let loadEffect = "load_effect"
  public static let unloadEffect = "unload_effect"
  public static let setEffectsPath = "set_effects_path"
  public static let setToken = "set_token"
}
```

To enable/disable `BanubaFiltersAgoraExtension` use the following method:
```swift
import BanubaFiltersAgoraExtension

agoraKit?.enableExtension(
    withVendor: BanubaPluginKeys.vendorName,
    extension: BanubaPluginKeys.extensionName,
    enabled: true
)
```

Before applying an effect on your video you have to initialize `BanubaFiltersAgoraExtension` with the path to effects and banuba client token. Look how it can be achieved:
```swift
agoraKit?.setExtensionPropertyWithVendor(
    BanubaPluginKeys.vendorName,
    extension: BanubaPluginKeys.extensionName,
    key: BanubaPluginKeys.setEffectsPath,
    value: "place_path_to_effects_folder_here"
)
    
agoraKit?.setExtensionPropertyWithVendor(
    BanubaPluginKeys.vendorName,
    extension: BanubaPluginKeys.extensionName,
    key: BanubaPluginKeys.setToken,
    value: "place_your_banuba_token_here".trimmingCharacters(in: .whitespacesAndNewlines)
)
```

After those steps you can tell `BanubaFiltersAgoraExtension` to enable or disable the mask:

```swift
agoraKit?.setExtensionPropertyWithVendor(
    BanubaPluginKeys.vendorName,
    extension: BanubaPluginKeys.extensionName,
    key: BanubaPluginKeys.loadEffect,
    value: "put_effect_name_here"
)
  
agoraKit?.setExtensionPropertyWithVendor(
    BanubaPluginKeys.vendorName,
    extension: BanubaPluginKeys.extensionName,
    key: BanubaPluginKeys.unloadEffect,
    value: " "
)
```
