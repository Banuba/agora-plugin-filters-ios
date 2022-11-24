Examples for Banuba SDK on iOS and [Agora.io](https://www.agora.io/en/) SDK integration via Agora Plugin Filters to enhance video calls with real-time face filters and virtual backgrounds.

> **Important**
>
> [master](../../tree/master) branch is always compatible with latest SDK version. Please use [v0.x](../../tree/v0.x) branch for SDK version 0.x (e.g. v0.38).
>
> The sample has been tested with `4.0.0-beta.2` version of the AgoraRtcKit.

# Getting Started

1. Open a terminal and run the following command to clone the project to your computer:
    ```sh
        git clone https://github.com/Banuba/agora-plugin-filters-ios.git
    ```

2. In the terminal open the project directory and run the 'pod install' command to get the Banuba SDK:
    ```sh
        cd agora-plugin-filters-ios/
        pod install
    ```

3. Download the effects you need from [HERE](https://docs.banuba.com/face-ar-sdk-v1/overview/demo_face_filters). Unzip the downloaded `.zip` files with effects to a folder [`app/src/main/assets/effects`](./BanubaAgoraFilters/effects). Each unpacked effect should be put into a separate folder. The folder name will be the effect name for loading.

3. Get the following Banuba trial client token. To receive a trial token or a full commercial licence from Banuba - please fill in our form on [form on banuba.com](https://www.banuba.com/face-filters-sdk) website, or contact us via [info@banuba.com](mailto:info@banuba.com).

4. Copy and Paste your Banuba client token into appropriate section of [`Token.swift`](./BanubaAgoraFilters/Token.swift) with " " symbols.

5. Visit [agora.io](https://console.agora.io) to sign up and get [Agora token, Agora app ID and Agora channel ID](https://docs.agora.io/en/Agora%20Platform/channel_key?platform=Android). You can read more about how you can get an Agora token at [THIS LINK](https://docs.agora.io/en/Agora%20Platform/channel_key?platform=Android).

6. Copy and Paste your Agora token, Agora app ID and Agora channel ID into appropriate section of [`Token.swift`](./BanubaAgoraFilters/Token.swift) with " " symbols.

7. As a result of the four previous steps, in the file [`Token.swift`](./BanubaAgoraFilters/Token.swift) you should have the following: 
``` swift
import Foundation

// MARK: - Agora Tokens
internal let agoraAppID: String = "this_is_your_AGORA_APP_ID"
internal let agoraClientToken: String? = "this_is_your_AGORA_CLIENT_TOKEN"
internal let agoraChannelId: String = "this_is_your_AGORA_CHANNEL_ID"

// MARK: - BanubaToken
internal let banubaClientToken = "this_is_your_BANUBA_CLIENT_TOKEN"
```

8. Open the `BanubaAgoraFilters.xcworkspace` project in Xcode and run the `BanubaAgoraFilters` target.

:exclamation: If you have any problems with installing Agora frameworks with Swift Package Manager refer to this [page](https://github.com/agorabuilder/AgoraRtcEngine_iOS_Preview)

# Connecting Banuba SDK and AgoraRtcKit to your own project

Connecting Banuba SDK to your project is similar to the steps in the `Getting Started` section. As for AgoraRtcKit, we advise to use Swift Package Manager. You should use the following settings:  
URL: `https://github.com/agorabuilder/AgoraRtcEngine_iOS_Preview.git`  
Version Rule: `Exact`  
Version: `4.0.0-beta.2`

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
