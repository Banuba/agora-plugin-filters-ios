Examples for [Banuba SDK on iOS](https://docs.banuba.com/face-ar-sdk/ios/ios_overview) and [Agora.io](https://www.agora.io/en/) SDK integration via Agora Plugin Filters to enhance video calls with real-time face filters and virtual backgrounds.

# Getting Started

1. Get the latest Banuba SDK archive for Android and the client token. Please fill in our form on [form on banuba.com](https://www.banuba.com/face-filters-sdk) website, or contact us via [info@banuba.com](mailto:info@banuba.com).
2. Drag `BanubaEffectPlayer.xcframework` file from the Banuba SDK to Frameworks, Libraries, and Embedded Content section in your target configuration.
3. Copy and Paste your banuba client token into appropriate section of `/BanubaAgoraFilters/BanubaAgoraFilters/Token.swift` with “ ” symbols. For example:  ``` let banubaClientToken = “place_your_banuba_token_here”```
4. Visit agora.io to sign up and get token, app and channel ID
5. Copy and Paste your agora token, app and chanel ID into appropriate section of `/BanubaAgoraFilters/BanubaAgoraFilters/Token.swift` with “ ” symbols. For example: 
``` swift
internal let agoraAppID = "place_your_agora_app_id_here"
internal let agoraClientToken = "place_your_agora_client_token_here"
internal let agoraChannelId = "place_your_agora_channel_id_here"
```
6. Open the project in Xcode and run the necessary target using the usual steps.
