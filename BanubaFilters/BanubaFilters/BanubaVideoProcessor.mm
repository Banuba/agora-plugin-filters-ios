#include "BanubaVideoProcessor.h"
#include <chrono>
#include <optional>
#include <utility>
#include <libyuv.h>
#include "utility.hpp"

namespace agora::extension {

    BanubaVideoProcessor::BanubaVideoProcessor() = default;

void BanubaVideoProcessor::process_frame(const agora_refptr<rtc::IVideoFrame> &in) {
        in->getVideoFrameData(m_captured_frame);
        if (!m_oep ||
            m_image_format.width != m_captured_frame.width ||
            m_image_format.height != m_captured_frame.height) {
            create_ep(m_captured_frame.width, m_captured_frame.height);
        }
#ifdef DEBUG
        std::chrono::steady_clock::time_point time_begin = std::chrono::steady_clock::now();
#endif
        auto pixels = m_captured_frame.pixels.data;
        int32_t y_size = m_captured_frame.width * m_captured_frame.height;
        auto yuv_image = bnb::full_image_t(
                bnb::yuv_image_t{
                        bnb::color_plane_weak(pixels),
                        bnb::color_plane_weak(pixels + y_size),
                        m_image_format
                }
        );
        auto image_ptr = std::make_shared<bnb::full_image_t>(std::move(yuv_image));
        auto pb = m_oep->process_image(image_ptr, m_target_orient);
      auto convert_callback = [this, pixels, pb, in](std::optional<bnb::full_image_t> image) {
        if (image.has_value()) {
          auto &rgba_image = image->get_data<bnb::bpc8_image_t>();
          int32_t y_size = m_captured_frame.width * m_captured_frame.height;
                    libyuv::ABGRToNV12(rgba_image.get_data(), m_image_format.width * 4,
                                         pixels, m_captured_frame.width,
                                         pixels + y_size, m_captured_frame.width,
                                         m_captured_frame.width, m_captured_frame.height);
//          libyuv::ARGBToNV12(rgba_image.get_data(), m_image_format.width * 4,
//                               pixels, m_captured_frame.width,
//                               pixels + y_size, m_captured_frame.width,
//                               m_captured_frame.width, m_captured_frame.height);
          m_control->deliverVideoFrame(in);
        }
        pb->unlock();
      };
      pb->get_rgba_async(convert_callback);
#ifdef DEBUG
        std::chrono::steady_clock::time_point time_end = std::chrono::steady_clock::now();
        auto time_result = std::chrono::duration_cast<std::chrono::milliseconds>(
                time_end - time_begin).count();
        send_event("processFrame",
                   std::string("Processing time ms: ").append(std::to_string(time_result)).c_str());
#endif
    }

    void BanubaVideoProcessor::set_parameter(
            const std::string &key,
            const std::string &parameter
    ) {
        if (m_oep && key == "load_effect") {
            m_oep->load_effect(parameter);
            return;
        }
        if (m_oep && key == "unload_effect") {
            m_oep->unload_effect();
            return;
        }
    }

    void BanubaVideoProcessor::create_ep(int32_t width, int32_t height) {
        auto ort = std::make_shared<bnb::offscreen_render_target>(width, height);
        m_oep = bnb::interfaces::offscreen_effect_player::create(width, height, ort);
        m_oep->enable_audio(false);

        m_image_format.width = width;
        m_image_format.height = height;
        m_image_format.orientation = bnb::camera_orientation::deg_180;
    }

    void BanubaVideoProcessor::send_event(const char *key, const char *data) {
        if (m_control) {
            m_control->postEvent(key, data);
        }
    }
}
