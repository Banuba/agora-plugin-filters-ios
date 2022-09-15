Examples for Banuba SDK on iOS and [Agora.io](https://www.agora.io/en/) SDK integration via Agora Plugin Filters to enhance video calls with real-time face filters and virtual backgrounds.

> **Important**
>
> [master](../../tree/master) branch is always compatible with latest SDK version. Please use [v0.x](../../tree/v0.x) branch for SDK version 0.x (e.g. v0.38).
>
> The sample has been tested with `4.0.0-rc.1` version of the Agora SDK.

# Getting Started

1. Execute 'pod install' to get the Banuba SDK.

2. Open the BanubaAgoraFilters.xcworkspace file in Xcode.

3. Update SPM dependencies to get Agora SDK.

4. Copy and Paste your Banuba extension credentials from Agora Console into the appropriate section of `/BanubaAgoraFilters/Token.swift` with “ ” symbols. For example: 
``` swift
let appKey = "Banuba Extension App Key"
let appSecret = "Banuba Extension App Secret"
```
5. Visit agora.io to sign up and get the token, app and channel ID.

6. Copy and Paste your agora token, app and chanel ID into appropriate section of `/BanubaAgoraFilters/Token.swift` with “ ” symbols. For example: 
``` swift
internal let agoraAppID = "Agora App ID"
internal let agoraClientToken = "Agora Token"
internal let agoraChannelId = "Agora Channel ID"
```

7. Donwload the needed effects from [here](https://docs.banuba.com/face-ar-sdk-v1/overview/demo_face_filters). This guarantees, that you will use the up-to-date version of the effects. The effects must be copied to the `agora-plugin-filters-ios -> BanubaAgoraFilters -> effects` folder.

8. Run the `BanubaAgoraFilters` target.

:exclamation: If you have any problems with installing Agora frameworks with Swift Package Manager refer to this [page](https://github.com/agorabuilder/AgoraRtcEngine_iOS_Preview)

# Connecting Banuba SDK and AgoraRtcKit to your own project

Connecting Banuba SDK to your project is similar to the steps in the `Getting Started` section. As for AgoraRtcKit, we advise to use Swift Package Manager. You should use the following settings:  
URL: `https://github.com/AgoraIO/AgoraRtcEngine_iOS`  
Version Rule: `Exact`  
Version: `4.0.0-rc.1`

# How to use `BanubaFiltersAgoraExtension`

To control `BanubaFiltersAgoraExtension` with Agora libs look available keys listed below:
```swift
public struct BanubaPluginKeys {
    public static let vendorName = "Banuba"
    public static let extensionName = "BanubaFilter"
    public static let loadEffect = "load_effect"
    public static let unloadEffect = "unload_effect"
    public static let setAppKey = "set_app_key"
    public static let setAppSecret = "set_app_secret"
    public static let setEffectsPath = "set_effects_path"
    public static let evalJSMethod = "eval_js"
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

Before applying an effect on your video you have to initialize `BanubaFiltersAgoraExtension` with the path to effects and extension credentials (app key and app secret). Look how it can be achieved:
```swift
      agoraKit?.setExtensionPropertyWithVendor(BanubaPluginKeys.vendorName,
                                               extension: BanubaPluginKeys.extensionName,
                                               key: BanubaPluginKeys.setEffectsPath,
                                               value: BanubaEffectsManager.effectsURL.path)
                                               
      agoraKit?.setExtensionPropertyWithVendor(BanubaPluginKeys.vendorName,
                                               extension: BanubaPluginKeys.extensionName,
                                               key: BanubaPluginKeys.setAppKey,
                                               value: appKey)
                                               
      agoraKit?.setExtensionPropertyWithVendor(BanubaPluginKeys.vendorName,
                                               extension: BanubaPluginKeys.extensionName,
                                               key: BanubaPluginKeys.setAppSecret,
                                               value: appSecret)
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

If the mask has parameters and you want to change them, you can do it the next way:

```swift
agoraKit?.setExtensionPropertyWithVendor(
    BanubaPluginKeys.vendorName,
    extension: BanubaPluginKeys.extensionName,
    key: BanubaPluginKeys.evalJSMethod,
    value: string
)      
```
`string` must be a string with  method’s name and  parameters. You can find an example in our [documentation](https://docs.banuba.com/face-ar-sdk-v1/effect_api/face_beauty).

# How to build `BanubaFiltersAgoraExtension`

To build the BanubaFiltersAgoraExtension manually, please follow the steps bellow:

1. Execute 'pod install' to get the Banuba SDK.

2. Open the BanubaAgoraFilters.xcworkspace file in Xcode.

3. Choose "File->Packages->Reset Package Cashes" from Xcode menu.

4. Build the target `BanubaFiltersAgoraExtension`. It will be built with your Swift version. After this you should open the section `Products` in the `Project Navigator` (the left part of the Xcode screen). Click on the `BanubaFiltersAgoraExtension` with the right click of the mouse and choose «Show in Finder». Copy the `BanubaFiltersAgoraExtension.framework` from the folder.

5. Then put the framework to the `/Frameworks` folder of the BanubaAgoraFilters.xcodeproj (or of your project). Then you can build BanubaAgoraFilters or your project.

The reconnection of the `BanubaFiltersAgoraExtension.framework` to the example project may be required. To do it, you should remove the `BanubaFiltersAgoraExtension.framework` from the Project Settings: "General-> Frameworks, Libraries and Embedded Content". Then you should drag&drop the `BanubaFiltersAgoraExtension.framework` to this section. You should choose «Embed&Sign» for this framework.

# Effects managing

To retrieve effects list use the following code:

```swift
let effectsPath = BanubaEffectsManager.effectsURL.path
let effectsService = EffectsService(effectsPath: effectsPath)
let effectViewModels = effectsService
    .getEffectNames()
    .sorted()
    .compactMap { effectName in
        guard let effectPreviewImage = effectsService.getEffectPreview(effectName) else {
          return nil
        }

        let effectViewModel = EffectViewModel(image: effectPreviewImage, effectName: effectName)
        return effectViewModel
      }
```

`EffectViewModel` has the next properties:
```swift
class EffectViewModel {
    let image: UIImage
    let effectName: String?
    var cancelEffectModel: Bool {
        return effectName == nil
    }
}
```
