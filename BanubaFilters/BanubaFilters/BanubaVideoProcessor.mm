#include "BanubaVideoProcessor.h"
#include <libyuv.h>

#include <BNBSdkCore/BNBUtilityManager.h>

namespace agora::extension
{

    static bool is_utility_initialized = false;
    BanubaVideoProcessor::BanubaVideoProcessor() = default;

    void BanubaVideoProcessor::process_frame(const agora_refptr<rtc::IVideoFrame>& input_frame)
    {
        if (!m_is_initialized) {
            m_control->deliverVideoFrame(input_frame);
            return;
        }

        rtc::VideoFrameData captured_frame;
        input_frame->getVideoFrameData(captured_frame);
        if (!m_oep || m_width != captured_frame.width || m_height != captured_frame.height) {
            create_ep(captured_frame.width, captured_frame.height);
        }

        @autoreleasepool {
            if (m_effect_is_loaded) {
                /** Banuba SDK distinguishes input and output frame buffers, this lets to avoid data copying to improve the performance.
                 *  Since the Agora plugin assumes to use the same memory buffer as input and output,
                 *  we are compelled to make a copy of input frame data to prevent the destruction of the frame, processing by the Banuba SDK.
                 */
                CVPixelBufferRef source_buffer = copy_to_NV12_buffer_from_captured_frame(captured_frame);

                auto format = EpImageFormat();
                format.imageSize = CGSizeMake(m_width, m_height);
                format.orientation = EPOrientationAngles0;
                format.resultedImageOrientation = EPOrientationAngles0;
                format.isMirrored = true;
                format.needAlphaInOutput = false;
                format.overrideOutputToBGRA = false;
                format.outputTexture = false;

                auto callback = [this, input_frame, source_buffer](CVPixelBufferRef processed_buffer, NSNumber* timeStamp) {
                    CVPixelBufferRelease(source_buffer);
                    if (processed_buffer) {
                        copy_to_Agora_frame_from_processed_buffer(input_frame, processed_buffer);
                        m_control->deliverVideoFrame(input_frame);
                    }
                };

                NSNumber* timestamp = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
                [m_oep processImage:source_buffer withFormat:&format frameTimestamp:timestamp completion:callback];
            } else {
                m_control->deliverVideoFrame(input_frame);
            }
        }
    }

    void BanubaVideoProcessor::set_parameter(
        const std::string& key,
        const std::string& parameter
    )
    {
        NSString* param = @(parameter.c_str());
        if (m_oep && key == "load_effect") {
            [m_oep loadEffect:param];
            m_effect_is_loaded = true;
            return;
        }
        if (m_oep && key == "unload_effect") {
            [m_oep unloadEffect];
            m_effect_is_loaded = false;
            return;
        }
        if (key == "set_effects_path") {
            m_path_to_effects = parameter;
            initialize();
            return;
        }
        if (key == "set_token") {
            m_client_token = parameter;
            initialize();
            return;
        }
        if (key == "eval_js") {
            [m_oep evalJs:param resultCallback:nil];
            return;
        }
    }

    void BanubaVideoProcessor::initialize()
    {
        if (is_utility_initialized) {
            m_is_initialized = true;
            return;
        }
        if (m_client_token.empty() || m_path_to_effects.empty()) {
            return;
        }

        NSString* effectPlayerBundlePath = [[NSBundle mainBundle] bundlePath];
        NSString* pathToEffects = @(m_path_to_effects.c_str());
        NSArray* paths = @[
            [effectPlayerBundlePath stringByAppendingString:@"/bnb-resources"],
            [effectPlayerBundlePath stringByAppendingString:@"/bnb-res-ios"],
            pathToEffects
        ];
        NSString* clientToken = @(m_client_token.c_str());
        [BNBUtilityManager initialize:paths clientToken:clientToken];
        
        is_utility_initialized = true;
        m_is_initialized = true;
    }

    void BanubaVideoProcessor::create_ep(int32_t width, int32_t height)
    {
        m_oep = [[BNBOffscreenEffectPlayer alloc] initWithEffectWidth:width andHeight:height manualAudio:false];
        m_width = width;
        m_height = height;
    }

    void BanubaVideoProcessor::send_event(const char* key, const char* data)
    {
        if (m_control) {
            m_control->postEvent(key, data);
        }
    }

    CVPixelBufferRef BanubaVideoProcessor::copy_to_NV12_buffer_from_captured_frame(rtc::VideoFrameData &captured_frame)
    {
        auto pixels = captured_frame.pixels.data;
        uint8_t* src_y_adress = static_cast<uint8_t*>(pixels);
        int src_y_width = captured_frame.width;
        int src_y_height = captured_frame.height;
        int src_y_bytes_per_row = captured_frame.width;

        uint8_t* src_uv_adress = static_cast<uint8_t*>(pixels + captured_frame.width * captured_frame.height);
        auto src_uv_bytes_per_row = captured_frame.width;

        CVPixelBufferRef destination_buffer = NULL;
        NSDictionary* pixel_attributes = @{(id) kCVPixelBufferIOSurfacePropertiesKey: @{}};
        auto result = CVPixelBufferCreate(
            kCFAllocatorDefault,
            src_y_width,
            src_y_height,
            kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
            (__bridge CFDictionaryRef)(pixel_attributes),
            &destination_buffer
            );
        NSCAssert(result == kCVReturnSuccess && destination_buffer != NULL, @"Cannot create PixelBuffer!");

        CVPixelBufferLockBaseAddress(destination_buffer, 0);
        uint8_t* dst_y_adress = static_cast<uint8_t*>(CVPixelBufferGetBaseAddressOfPlane(destination_buffer, 0));
        auto dst_y_bytes_per_row = (int) CVPixelBufferGetBytesPerRowOfPlane(destination_buffer, 0);

        uint8_t* dst_uv_adress = static_cast<uint8_t*>(CVPixelBufferGetBaseAddressOfPlane(destination_buffer, 1));
        auto dst_uv_bytes_per_row = (int) CVPixelBufferGetBytesPerRowOfPlane(destination_buffer, 1);

        libyuv::NV12Copy(src_y_adress, src_y_bytes_per_row, src_uv_adress, src_uv_bytes_per_row, dst_y_adress, dst_y_bytes_per_row, dst_uv_adress, dst_uv_bytes_per_row, src_y_width, src_y_height);
        CVPixelBufferUnlockBaseAddress(destination_buffer, 0);

        return destination_buffer;
    }

    void BanubaVideoProcessor::copy_to_Agora_frame_from_processed_buffer(const agora_refptr<rtc::IVideoFrame> &input_frame, const CVPixelBufferRef buffer)
    {
        rtc::VideoFrameData captured_frame;
        input_frame->getVideoFrameData(captured_frame);
        auto pixels = captured_frame.pixels.data;

        CVPixelBufferLockBaseAddress(buffer, 1);
        uint8_t* y_adress = static_cast<uint8_t*>(CVPixelBufferGetBaseAddressOfPlane(buffer, 0));
        auto y_width = static_cast<int>(CVPixelBufferGetWidthOfPlane(buffer, 0));
        auto y_height = static_cast<int>(CVPixelBufferGetHeightOfPlane(buffer, 0));
        auto y_bytes_per_row = static_cast<int>(CVPixelBufferGetBytesPerRowOfPlane(buffer, 0));

        uint8_t* uv_adress = static_cast<uint8_t*>(CVPixelBufferGetBaseAddressOfPlane(buffer, 1));
        auto uv_bytes_per_row = static_cast<int>(CVPixelBufferGetBytesPerRowOfPlane(buffer, 1));

        libyuv::NV12Copy(y_adress, y_bytes_per_row, uv_adress, uv_bytes_per_row, static_cast<uint8_t*>(pixels), m_width, static_cast<uint8_t*>(pixels + m_width * m_height), m_width, y_width, y_height);
        CVPixelBufferUnlockBaseAddress(buffer, 1);
    }
}
