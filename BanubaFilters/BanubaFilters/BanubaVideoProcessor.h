#pragma once

#include <string>
#include <AgoraRtcKit/AgoraRefPtr.h>
#include <AgoraRtcKit/NGIAgoraMediaNode.h>
#include <AgoraRtcKit/AgoraMediaBase.h>
#include <AgoraRtcKit/NGIAgoraVideoFrame.h>
#include "UsageTrackingHelper.h"
#include <BNBSdkCore/BNBOffscreenEffectPlayer.h>

namespace agora::extension
{

    class BanubaVideoProcessor : public RefCountInterface
    {

    public:
        BanubaVideoProcessor();
        void process_frame(const agora_refptr<rtc::IVideoFrame>& input_frame);
        void set_parameter(const std::string &key, const std::string& parameter);
        void onProcessingStarted();
        void onProcessingStopped();

        int set_extension_control(
            agora::agora_refptr<rtc::IExtensionVideoFilter::Control> control
        )
        {
            m_control = control;
            return 0;
        };

    protected:
        ~BanubaVideoProcessor();

    private:
        void send_event(const char* key, const char* data);

        void initialize();
        void setupTrackingHelper();
        void create_ep(int32_t width, int32_t height);

        CVPixelBufferRef copy_to_NV12_buffer_from_captured_frame(rtc::VideoFrameData& captured_frame);
        void copy_to_Agora_frame_from_processed_buffer(const agora_refptr<rtc::IVideoFrame>& input_frame, const CVPixelBufferRef buffer);

        std::string m_path_to_effects;
        // TODO remove separate m_client_token as app_secret should work as SDK token.
        std::string m_client_token;
        std::string m_client_app_key;
        std::string m_client_app_secret;
        
        bool m_is_initialized = false;
        bool m_effect_is_loaded = false;
        NSDate *m_previous_processedframe_timestamp = nil;
        UsageTrackingHelper *trackingHelper = nil;

        agora::agora_refptr<rtc::IExtensionVideoFilter::Control> m_control;
        BNBOffscreenEffectPlayer* m_oep{nullptr};
        uint32_t m_width = 0;
        uint32_t m_height = 0;
        EPOrientation m_orientation = EPOrientationAngles0;
    };
} // namespace agora::extension
