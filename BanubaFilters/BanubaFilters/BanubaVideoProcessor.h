#pragma once

#include <string>
#include <AgoraRtcKit/AgoraRefPtr.h>
#include <AgoraRtcKit/NGIAgoraMediaNode.h>
#include <AgoraRtcKit/AgoraMediaBase.h>
#include <AgoraRtcKit/NGIAgoraVideoFrame.h>

#include <BanubaEffectPlayer/BNBOffscreenEffectPlayer.h>

namespace agora::extension {

    class BanubaVideoProcessor : public RefCountInterface {

    public:
        BanubaVideoProcessor();
        void process_frame(const agora_refptr<rtc::IVideoFrame> &input_frame);
        void set_parameter(const std::string &key, const std::string &parameter);

        int set_extension_control(
                agora::agora_refptr<rtc::IExtensionVideoFilter::Control> control
        ) {
            m_control = control;
            return 0;
        };

    protected:
        ~BanubaVideoProcessor() = default;

    private:
        void send_event(const char *key, const char *data);

        void initialize();
        void create_ep(int32_t width, int32_t height);

        CVPixelBufferRef get_NV12_buffer_from_captured_frame(rtc::VideoFrameData &captured_frame);
        CVPixelBufferRef copy_pixel_buffer_NV12(CVPixelBufferRef source_buffer);

        std::string m_path_to_effects;
        std::string m_client_token;
        bool m_is_initialized = false;
        bool m_effect_is_loaded = false;

        agora::agora_refptr<rtc::IExtensionVideoFilter::Control> m_control;
        BNBOffscreenEffectPlayer* m_oep {nullptr};
        uint32_t m_width = 0;
        uint32_t m_height = 0;
        EPOrientation m_orientation = EPOrientationAngles0;
    };
}
