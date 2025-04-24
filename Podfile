platform :ios, '13.0'
workspace 'BanubaAgoraFilters'

source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/sdk-banuba/banuba-sdk-podspecs.git'

target 'BanubaAgoraFilters' do
  project 'BanubaAgoraFilters'
  use_frameworks!


  bnb_version = '1.17.0'
  pod 'BNBBackground', bnb_version
  pod 'BNBMakeup', bnb_version  


  pod 'AgoraRtcEngine_iOS/RtcBasic', '4.3.2'
  pod 'BanubaFiltersAgoraExtension', '2.5.1'
  
  # The following pods are only used by the plugin developers, you can ignore them
  ## Pre-release binary framework check
  # pod 'BanubaFiltersAgoraExtension', :path => '../banuba-filters-agora-extension-framework/'
  
  ## Integration of local source files
  # pod 'BanubaFiltersAgoraExtension', :path => '../banuba_agora_extension_ios/'
  # pod 'libyuv', :path => '../banuba_agora_extension_ios/'
end
