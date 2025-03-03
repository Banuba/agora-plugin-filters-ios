Examples for Banuba SDK on iOS and [Agora.io](https://www.agora.io/en/) SDK integration via Agora Plugin Filters to enhance video calls with real-time face filters and virtual backgrounds.

# Getting Started

## Prerequisites

1. Visit agora.io to sign up and get the app id, client token and channel id. Please consult with [Agora documentation about account management](https://docs.agora.io/en/voice-calling/reference/manage-agora-account) to find out exactly how mentioned IDs are created.

2. Activate the [Banuba Face AR SDK extension](https://console.agora.io/marketplace/extension/introduce?serviceName=banuba). Our sales representatives will provide you the license token used by extension. Please check out the [extension integration documentation](https://docs.agora.io/en/video-calling/develop/use-an-extension?platform=ios) if you have any questions regarding this step.

## Dependencies

|                             | Version |                    Description                    | 
|-----------------------------|:-------:|:-------------------------------------------------:|
| AgoraRtcEngine_iOS/RtcBasic |  4.2.0  |               Agora RTC dependency                |
| BanubaSdk                   |  1.7.0  | Banuba Face AR dependency for applying AR filters |
| BanubaFiltersAgoraExtension |  2.3.0  |            Banuba Extension for Agora             |

## Installation

1. Open Terminal and run the following command to clone the project to your computer:
```sh
git clone https://github.com/Banuba/agora-plugin-filters-ios.git
```

2. In the terminal open the project directory and run the 'pod install' command to get the Banuba and Agora SDKs and plugin framework:
```sh
cd agora-plugin-filters-ios/
pod install --repo-update
```

3. Open the BanubaAgoraFilters.xcworkspace file in Xcode.

4. Copy and paste your Agora token, app and chanel ID to the appropriate section of `/BanubaAgoraFilters/Token.swift` with “ ” symbols. For example: 
``` swift
internal let agoraAppID = "Agora App ID"
internal let agoraClientToken = "Agora Token"
internal let agoraChannelId = "Agora Channel ID"
```

5. Copy and Paste your Banuba license token received from the sales representative to the appropriate section of `/BanubaAgoraFilters/Token.swift` with “ ” symbols. For example: 
``` swift
let banubaLicenseToken = "Banuba Extension License Token"
```

6. The sample includes a few basic AR effects, however you can download additional effects from [here](https://docs.banuba.com/far-sdk/tutorials/capabilities/demo_face_filters). This guarantees, that you will use the up-to-date version of the effects. The effects must be copied to the `agora-plugin-filters-ios -> BanubaAgoraFilters -> effects` folder.

7. Run the `BanubaAgoraFilters` target.

# Integrating Banuba SDK and AgoraRtcKit in your own project

Integrating Banuba SDK to your project is similar to the steps in the `Getting Started` section. 

# BanubaFiltersAgoraExtension

The `BanubaFiltersAgoraExtension` plugin and Banuba SDK can be installed with Cocoapods. Simply add the following lines to your Podfile:
```ruby
pod 'BanubaFiltersAgoraExtension', '2.3.0'
pod 'BanubaSdk', '1.7.0'
```
Please make sure that you have also added our custom Podspecs source to your Podfile:
```ruby
source 'https://github.com/sdk-banuba/banuba-sdk-podspecs.git'
```

Alternatively you can also install the extension by downloading the prebuilt xcframework from [here](https://github.com/Banuba/banuba-filters-agora-extension-framework) and manually linking it to your project.

## AgoraRtcKit

Add the following line to your Podfile:
```ruby
pod 'AgoraRtcEngine_iOS', '4.2.0'
```

# How to use `BanubaFiltersAgoraExtension`

To control `BanubaFiltersAgoraExtension` with Agora libs use the following keys from `BanubaPluginKeys.h` file:
```objc
extern NSString * __nonnull const BNBKeyVendorName;
extern NSString * __nonnull const BNBKeyExtensionName;
extern NSString * __nonnull const BNBKeyLoadEffect;
extern NSString * __nonnull const BNBKeyUnloadEffect;
extern NSString * __nonnull const BNBKeySetBanubaLicenseToken;
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

Before applying an effect to your video you have to initialize `BanubaFiltersAgoraExtension` with the path to effects and extension license token. Look at how it can be achieved:
```swift
agoraKit?.setExtensionPropertyWithVendor(BNBKeyVendorName,
                                         extension: BNBKeyExtensionName,
                                         key: BNBKeySetEffectsPath,
                                         value: BanubaEffectsManager.effectsURL.path)
                                         
agoraKit?.setExtensionPropertyWithVendor(BNBKeyVendorName,
                                         extension: BNBKeyExtensionName,
                                         key: BNBKeySetBanubaLicenseToken,
                                         value: banubaLicenseToken)
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
`string` must be a string with method’s name and parameters. You can find an example in our [documentation](https://docs.banuba.com/far-sdk/effects/makeup_deprecated/face_beauty).

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

`EffectViewModel` has the following properties:
```swift
class EffectViewModel {
    let image: UIImage
    let effectName: String?
    var cancelEffectModel: Bool {
        return effectName == nil
    }
}
```
