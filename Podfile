platform :ios, '12.0'
workspace 'BanubaAgoraFilters'

source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/sdk-banuba/banuba-sdk-podspecs.git'

target 'BanubaAgoraFilters' do
  project 'BanubaAgoraFilters'
  use_frameworks!

  pod 'BanubaSdk', '1.5.4'
  pod 'AgoraRtcEngine_iOS/RtcBasic', '4.1.1'
  pod 'BanubaFiltersAgoraExtension', '2.2.0'
  
  # The following pods are only used by the plugin developers, you can ignore them
  ## Pre-release binary framework check
  # pod 'BanubaFiltersAgoraExtension', :path => '../banuba-filters-agora-extension-framework/'
  
  ## Integration of local source files
  # pod 'BanubaFiltersAgoraExtension', :path => '../banuba_agora_extension_ios/'
  # pod 'libyuv', :path => '../banuba_agora_extension_ios/'
end
