Examples for Banuba SDK on iOS and [Agora.io](https://www.agora.io/en/) SDK integration via Agora Plugin Filters to enhance video calls with real-time face filters and virtual backgrounds.

> **Important**
>
> [master](../../tree/master) branch is always compatible with latest SDK version. Please use [v0.x](../../tree/v0.x) branch for SDK version 0.x (e.g. v0.38).
>
> The sample has been tested with `4.0.1` version of the Agora SDK and `1.5.3` version of Banuba SDK.

# Getting Started

1. Visit agora.io to sign up and get the app id, client token and channel id. Please consult with [Agora documentation about account management](https://docs.agora.io/en/voice-calling/reference/manage-agora-account) to find out exactly how mentioned IDs are created.

2. Activate the [Banuba Face AR SDK extension](https://console.agora.io/marketplace/extension/introduce?serviceName=banuba) to get the app key and app secret. Please check out the [extension integration documentation](https://docs.agora.io/en/video-calling/develop/use-an-extension?platform=ios) if you have any questions regarding this step.

3. Open a terminal and run the following command to clone the project to your computer:
```sh
git clone https://github.com/Banuba/agora-plugin-filters-ios.git
```

4. In the terminal open the project directory and run the 'pod install' command to get the Banuba and Agora SDKs and plugin framework:
```sh
cd agora-plugin-filters-ios/
pod install
```

5. Open the BanubaAgoraFilters.xcworkspace file in Xcode.

6. Copy and paste your Agora token, app and chanel ID to the appropriate section of `/BanubaAgoraFilters/Token.swift` with “ ” symbols. For example: 
``` swift
internal let agoraAppID = "Agora App ID"
internal let agoraClientToken = "Agora Token"
internal let agoraChannelId = "Agora Channel ID"
```

7. Copy and Paste your Banuba extension credentials received from the sales representative to the appropriate section of `/BanubaAgoraFilters/Token.swift` with “ ” symbols. For example: 
``` swift
let appKey = "Banuba Extension App Key"
let appSecret = "Banuba Extension App Secret"
```

8. Download the needed effects from [here](https://docs.banuba.com/face-ar-sdk-v1/overview/demo_face_filters). This guarantees, that you will use the up-to-date version of the effects. The effects must be copied to the `agora-plugin-filters-ios -> BanubaAgoraFilters -> effects` folder.

9. Run the `BanubaAgoraFilters` target.

# Connecting Banuba SDK and AgoraRtcKit to your own project

Connecting Banuba SDK to your project is similar to the steps in the `Getting Started` section. 

As for AgoraRtcKit you can install it using either Swift Package Manager of Cocoapods. You should use the following settings for SPM:
URL: `https://github.com/AgoraIO/AgoraRtcEngine_iOS`  
Version Rule: `Exact`  
Version: `4.0.1`

In case of Cocoapods add the following line to your Podfile:
```ruby
pod 'AgoraRtcEngine_iOS', '4.0.1'
```

# Plugin installation

The `BanubaFiltersAgoraExtension` plugin can be installed with Cocoapods. Simply add the following line to your Podfile:
```ruby
pod 'BanubaFiltersAgoraExtension', '2.0.0'
```
Please make sure that you have also added our custom Podspecs source to your Podfile:
```ruby
source 'https://github.com/sdk-banuba/banuba-sdk-podspecs.git'
```

Alternatively you can also install the extension by downloading the prebuilt xcframework from [here](https://github.com/Banuba/banuba-filters-agora-extension-framework) and manually linking it to your project.

# How to use `BanubaFiltersAgoraExtension`

To control `BanubaFiltersAgoraExtension` with Agora libs use the following keys from `BanubaPluginKeys.h` file:
```objc
extern NSString * __nonnull const BNBKeyVendorName;
extern NSString * __nonnull const BNBKeyExtensionName;
extern NSString * __nonnull const BNBKeyLoadEffect;
extern NSString * __nonnull const BNBKeyUnloadEffect;
extern NSString * __nonnull const BNBKeySetAppKey;
extern NSString * __nonnull const BNBKeySetAppSecret;
extern NSString * __nonnull const BNBKeySetEffectsPath;
extern NSString * __nonnull const BNBKeyEvalJSMethod;
```

To enable/disable `BanubaFiltersAgoraExtension` use the following method:
```swift
import BanubaFiltersAgoraExtension

agoraKit?.enableExtension(
    withVendor: BNBKeyVendorName,
    extension: BNBKeyExtensionName,
    enabled: true
)
```

Before applying an effect to your video you have to initialize `BanubaFiltersAgoraExtension` with the path to effects and extension credentials (app key and app secret). Look how it can be achieved:
```swift
agoraKit?.setExtensionPropertyWithVendor(BNBKeyVendorName,
                                         extension: BNBKeyExtensionName,
                                         key: BNBKeySetEffectsPath,
                                         value: BanubaEffectsManager.effectsURL.path)
                                         
agoraKit?.setExtensionPropertyWithVendor(BNBKeyVendorName,
                                         extension: BNBKeyExtensionName,
                                         key: BNBKeySetAppKey,
                                         value: appKey)
                                         
agoraKit?.setExtensionPropertyWithVendor(BNBKeyVendorName,
                                         extension: BNBKeyExtensionName,
                                         key: BNBKeySetAppSecret,
                                         value: appSecret)
```

After those steps you can tell `BanubaFiltersAgoraExtension` to enable or disable the mask:

```swift
agoraKit?.setExtensionPropertyWithVendor(
    BNBKeyVendorName,
    extension: BNBKeyExtensionName,
    key: BNBKeyLoadEffect,
    value: "put_effect_name_here"
)
  
agoraKit?.setExtensionPropertyWithVendor(
    BNBKeyVendorName,
    extension: BNBKeyExtensionName,
    key: BNBKeyUnloadEffect,
    value: " "
)
```

If the mask has parameters and you want to change them, you can do it the next way:

```swift
agoraKit?.setExtensionPropertyWithVendor(
    BNBKeyVendorName,
    extension: BNBKeyExtensionName,
    key: BNBKeyEvalJSMethod,
    value: string
)      
```
`string` must be a string with method’s name and parameters. You can find an example in our [documentation](https://docs.banuba.com/face-ar-sdk-v1/effect_api/face_beauty).

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
