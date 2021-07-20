#import "BNBOffscreenEffectPlayer.h"
#import "BNBEffectPlayer.h"
#import "BNBNnMode.h"
#import "BNBEffectManager.h"
#import "BNBEffect.h"
#import <bnb/types/BNBFullImageData+Private.h>

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>
#import <OpenGLES/EAGLDrawable.h>

#import <thread>
#import <vector>

#include <bnb/renderer_common/internal/gl/program.hpp>

#import <Accelerate/Accelerate.h>
#import <CoreMotion/CoreMotion.h>

using namespace std::literals;

namespace
{
    // clang-format off
    const char* vs_default_base =
            " precision highp float; \n "
            " layout (location = 0) in vec3 aPos; \n"
            " layout (location = 1) in vec2 aTexCoord; \n"
            "out vec2 vTexCoord;\n"
            "void main()\n"
            "{\n"
                " gl_Position = vec4(aPos, 1.0); \n"
                " vTexCoord = aTexCoord; \n"
            "}\n";

    const char* ps_default_base =
            "precision mediump float;\n"
            "in vec2 vTexCoord;\n"
            "out vec4 FragColor;\n"
            "uniform sampler2D uTexture;\n"
            "void main()\n"
            "{\n"
                "FragColor = texture(uTexture, vTexCoord);\n"
            "}\n";
    // clang-format on

    class oep_frame_surface_handler
    {
        uint32_t m_orientation = 0;
        uint32_t m_y_flip = 0;
        static const auto v_size = static_cast<uint32_t>(bnb::camera_orientation::deg_270) + 1;
        unsigned int m_vao = 0;
        unsigned int m_vbo = 0;
        unsigned int m_ebo = 0;

    public:
        /**
        * First array determines texture orientation for vertical flip transformation
        * Second array determines texture's orientation
        * Third one determines the plane vertices` positions in correspondence to the texture coordinates
        */
        static const float vertices[2][v_size][5 * 4];

        explicit oep_frame_surface_handler(bnb::camera_orientation orientation, bool is_y_flip)
            : m_orientation(static_cast<uint32_t>(orientation))
            , m_y_flip(static_cast<uint32_t>(is_y_flip))
        {
            glGenVertexArrays(1, &m_vao);
            glGenBuffers(1, &m_vbo);
            glGenBuffers(1, &m_ebo);

            glBindVertexArray(m_vao);

            glBindBuffer(GL_ARRAY_BUFFER, m_vbo);
            glBufferData(GL_ARRAY_BUFFER, sizeof(vertices[m_y_flip][m_orientation]), vertices[m_y_flip][m_orientation], GL_STATIC_DRAW);

            // clang-format off

            unsigned int indices[] = {
                // clang-format off
                0, 1, 3, // first triangle
                1, 2, 3  // second triangle
                // clang-format on
            };

            // clang-format on

            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_ebo);
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

            // position attribute
            glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*) 0);
            glEnableVertexAttribArray(0);
            // texture coord attribute
            glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*) (3 * sizeof(float)));
            glEnableVertexAttribArray(1);

            glBindVertexArray(0);
            glBindBuffer(GL_ARRAY_BUFFER, 0);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        }

        uint32_t get_vertext_index()
        {
            return m_orientation + m_y_flip;
        }

        virtual ~oep_frame_surface_handler() final
        {
            if (m_vao != 0)
                glDeleteVertexArrays(1, &m_vao);

            if (m_vbo != 0)
                glDeleteBuffers(1, &m_vbo);

            if (m_ebo != 0)
                glDeleteBuffers(1, &m_ebo);

            m_vao = 0;
            m_vbo = 0;
            m_ebo = 0;
        }

        oep_frame_surface_handler(const oep_frame_surface_handler&) = delete;
        oep_frame_surface_handler(oep_frame_surface_handler&&) = delete;

        oep_frame_surface_handler& operator=(const oep_frame_surface_handler&) = delete;
        oep_frame_surface_handler& operator=(oep_frame_surface_handler&&) = delete;

        void update_vertices_buffer()
        {
            glBindBuffer(GL_ARRAY_BUFFER, m_vbo);
            glBufferData(GL_ARRAY_BUFFER, sizeof(vertices[m_y_flip][m_orientation]), vertices[m_y_flip][m_orientation], GL_STATIC_DRAW);
            glBindBuffer(GL_ARRAY_BUFFER, 0);
        }

        void set_orientation(bnb::camera_orientation orientation)
        {
            if (m_orientation != static_cast<uint32_t>(orientation)) {
                m_orientation = static_cast<uint32_t>(orientation);
            }
        }

        void set_y_flip(bool y_flip)
        {
            if (m_y_flip != static_cast<uint32_t>(y_flip)) {
                m_y_flip = static_cast<uint32_t>(y_flip);
            }
        }

        void draw()
        {
            glBindVertexArray(m_vao);
            glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, nullptr);
            glBindVertexArray(0);
        }
    };

    // clang-format off
    const float oep_frame_surface_handler::vertices[2][oep_frame_surface_handler::v_size][5 * 4] =
    {{ /* verical flip 0 */
        {
            // positions        // texture coords
            1.0f,  1.0f, 0.0f, 1.0f, 0.0f, // top right
            1.0f, -1.0f, 0.0f, 1.0f, 1.0f, // bottom right
            -1.0f, -1.0f, 0.0f, 0.0f, 1.0f, // bottom left
            -1.0f,  1.0f, 0.0f, 0.0f, 0.0f,  // top left
        },
        {
            // positions        // texture coords
            1.0f,  1.0f, 0.0f, 0.0f, 0.0f, // top right
            1.0f, -1.0f, 0.0f, 1.0f, 0.0f, // bottom right
            -1.0f, -1.0f, 0.0f, 1.0f, 1.0f, // bottom left
            -1.0f,  1.0f, 0.0f, 0.0f, 1.0f,  // top left
        },
        {
            // positions        // texture coords
            1.0f,  1.0f, 0.0f, 0.0f, 1.0f, // top right
            1.0f, -1.0f, 0.0f, 0.0f, 0.0f, // bottom right
            -1.0f, -1.0f, 0.0f, 1.0f, 0.0f, // bottom left
            -1.0f,  1.0f, 0.0f, 1.0f, 1.0f,  // top left
        },
        {
            // positions        // texture coords
            1.0f,  1.0f, 0.0f, 1.0f, 1.0f, // top right
            1.0f, -1.0f, 0.0f, 0.0f, 1.0f, // bottom right
            -1.0f, -1.0f, 0.0f, 0.0f, 0.0f, // bottom left
            -1.0f,  1.0f, 0.0f, 1.0f, 0.0f,  // top left
        }
    },
    { /* verical flip 1 */
        {
            // positions        // texture coords
            1.0f, -1.0f, 0.0f, 1.0f, 1.0f, // top right
            1.0f,  1.0f, 0.0f, 1.0f, 0.0f, // bottom right
            -1.0f,  1.0f, 0.0f, 0.0f, 0.0f, // bottom left
            -1.0f, -1.0f, 0.0f, 0.0f, 1.0f,  // top left
        },
        {
            // positions        // texture coords
            1.0f, -1.0f, 0.0f, 1.0f, 0.0f, // top right
            1.0f,  1.0f, 0.0f, 0.0f, 0.0f, // bottom right
            -1.0f,  1.0f, 0.0f, 0.0f, 1.0f, // bottom left
            -1.0f, -1.0f, 0.0f, 1.0f, 1.0f,  // top left
        },
        {
            // positions        // texture coords
            1.0f, -1.0f, 0.0f, 0.0f, 0.0f, // top right
            1.0f,  1.0f, 0.0f, 0.0f, 1.0f, // bottom right
            -1.0f,  1.0f, 0.0f, 1.0f, 1.0f, // bottom left
            -1.0f, -1.0f, 0.0f, 1.0f, 0.0f,  // top left
        },
        {
            // positions        // texture coords
            1.0f, -1.0f, 0.0f, 0.0f, 1.0f, // top right
            1.0f,  1.0f, 0.0f, 1.0f, 1.0f, // bottom right
            -1.0f,  1.0f, 0.0f, 1.0f, 0.0f, // bottom left
            -1.0f, -1.0f, 0.0f, 0.0f, 0.0f,  // top left
        }
    }};
    // clang-format on


    class offscreen_renderer
    {
    public:
        offscreen_renderer(size_t width, size_t height)
            : m_width(width)
            , m_height(height)
        {
            m_eagl_context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
            activateContext();

            m_program = std::make_unique<bnb::program>("OrientationChange", vs_default_base, ps_default_base);
            m_frame_surface_handler = std::make_unique<oep_frame_surface_handler>(bnb::camera_orientation::deg_0, false);

            setupTextureCache();

            setup_render_buffers();
        }

        ~offscreen_renderer()
        {
            if (m_videoTextureCache) {
                CFRelease(m_videoTextureCache);
            }
            cleanup_render_buffers();
        }

        void setup_render_buffers()
        {
            glGenFramebuffers(1, &m_framebuffer);
            glGenFramebuffers(1, &m_postProcessingFramebuffer);

            glBindFramebuffer(GL_FRAMEBUFFER, m_framebuffer);

            setupOffscreenPixelBuffer();

            setupOffscreenRenderTarget();
        }

        void cleanup_render_buffers()
        {
            if (m_offscreenRenderPixelBuffer) {
                CFRelease(m_offscreenRenderPixelBuffer);
                m_offscreenRenderPixelBuffer = nullptr;
            }
            if (m_offscreenRenderTexture) {
                CFRelease(m_offscreenRenderTexture);
                m_offscreenRenderTexture = nullptr;
            }
            if (m_framebuffer != 0) {
                glDeleteFramebuffers(1, &m_framebuffer);
                m_framebuffer = 0;
            }
            cleanPostProcessRenderingTargets();
            if (m_postProcessingFramebuffer != 0) {
                glDeleteFramebuffers(1, &m_postProcessingFramebuffer);
                m_postProcessingFramebuffer = 0;
            }
        }

        void surface_Ñhanged(uint32_t width, uint32_t height)
        {
            cleanup_render_buffers();

            m_width = width;
            m_height = height;

            setup_render_buffers();
        }

        void cleanPostProcessRenderingTargets()
        {
            if (m_offscreenPostProcessingPixelBuffer) {
                CFRelease(m_offscreenPostProcessingPixelBuffer);
                m_offscreenPostProcessingPixelBuffer = nullptr;
            }
            if (m_offscreenPostProcessingRenderTexture) {
                CFRelease(m_offscreenPostProcessingRenderTexture);
                m_offscreenPostProcessingRenderTexture = nullptr;
            }
        }

        void setupTextureCache()
        {
            CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, nil, m_eagl_context, nil, &m_videoTextureCache);

            if (err != noErr) {
                @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                               reason:@"Cannot initialize texture cache for the class BNBOffscreenEffectPlayer"
                                             userInfo:nil];
            }
        }

        void setupOffscreenPixelBuffer()
        {
            CFDictionaryRef empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
            CFMutableDictionaryRef attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
            CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
            CVReturn err = CVPixelBufferCreate(kCFAllocatorDefault, m_width, m_height, kCVPixelFormatType_32BGRA, attrs, &m_offscreenRenderPixelBuffer);
            if (err != noErr) {
                @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                               reason:@"Cannot create offscreen pixel buffer for the class BNBOffscreenEffectPlayer"
                                             userInfo:nil];
            }
            CFRelease(empty);
            CFRelease(attrs);
        }

        std::tuple<int, int> getWidthHeight(EPOrientation orientation)
        {
            auto width = orientation == EPOrientation::EPOrientationAngles90 || orientation == EPOrientation::EPOrientationAngles270 ? m_height : m_width;
            auto height = orientation == EPOrientation::EPOrientationAngles90 || orientation == EPOrientation::EPOrientationAngles270 ? m_width : m_height;
            return {width, height};
        }

        void setupOffscreenPostProcessingPixelBuffer(EPOrientation orientation)
        {
            auto [width, height] = getWidthHeight(orientation);
            CFDictionaryRef empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
            CFMutableDictionaryRef attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
            CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
            CVReturn err = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attrs, &m_offscreenPostProcessingPixelBuffer);
            if (err != noErr) {
                @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                               reason:@"Cannot create offscreen pixel buffer 2 for the class BNBOffscreenEffectPlayer"
                                             userInfo:nil];
            }
            CFRelease(empty);
            CFRelease(attrs);
        }

        void setupOffscreenRenderTarget()
        {
            CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, m_videoTextureCache, m_offscreenRenderPixelBuffer, NULL, GL_TEXTURE_2D, GL_RGBA, (GLsizei) m_width, (GLsizei) m_height, GL_RGBA, GL_UNSIGNED_BYTE, 0, &m_offscreenRenderTexture);

            if (err != noErr) {
                @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                               reason:@"Cannot create GL texture from pixel buffer for the class BNBOffscreenEffectPlayer"
                                             userInfo:nil];
            }
        }

        void setupOffscreenPostProcessingRenderTarget(EPOrientation orientation)
        {
            auto [width, height] = getWidthHeight(orientation);
            CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, m_videoTextureCache, m_offscreenPostProcessingPixelBuffer, NULL, GL_TEXTURE_2D, GL_RGBA, (GLsizei) width, (GLsizei) height, GL_RGBA, GL_UNSIGNED_BYTE, 0, &m_offscreenPostProcessingRenderTexture);

            if (err != noErr) {
                @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                               reason:@"Cannot create GL texture 2 from pixel buffer for the class BNBOffscreenEffectPlayer"
                                             userInfo:nil];
            }
        }

        void activateContext()
        {
            [EAGLContext setCurrentContext:m_eagl_context];
        }

        void prepareRendering()
        {
            activateContext();
            glBindFramebuffer(GL_FRAMEBUFFER, m_framebuffer);
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, CVOpenGLESTextureGetTarget(m_offscreenRenderTexture), CVOpenGLESTextureGetName(m_offscreenRenderTexture), 0);

            if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
                GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
                NSLog(@"Failed to make complete framebuffer object %d", status);

                return;
            }
        }

        void preparePostProcessingRendering()
        {
            activateContext();

            glBindFramebuffer(GL_FRAMEBUFFER, m_postProcessingFramebuffer);
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, CVOpenGLESTextureGetTarget(m_offscreenPostProcessingRenderTexture), CVOpenGLESTextureGetName(m_offscreenPostProcessingRenderTexture), 0);

            if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
                GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
                NSLog(@"Failed to make complete framebuffer2 object %d", status);

                return;
            }

            auto width = CVPixelBufferGetWidth(m_offscreenPostProcessingPixelBuffer);
            auto height = CVPixelBufferGetHeight(m_offscreenPostProcessingPixelBuffer);
            glViewport(0, 0, GLsizei(width), GLsizei(height));

            glActiveTexture(GLenum(GL_TEXTURE0));
            glBindTexture(CVOpenGLESTextureGetTarget(m_offscreenRenderTexture), CVOpenGLESTextureGetName(m_offscreenRenderTexture));
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR);
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR);
            glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GLfloat(GL_CLAMP_TO_EDGE));
            glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GLfloat(GL_CLAMP_TO_EDGE));
            // glUniform1i(samplerUniformRGBALocation, 0);
        }

        bnb::camera_orientation get_camera_orientation(EPOrientation orientation)
        {
            switch (orientation) {
                case EPOrientation::EPOrientationAngles180:
                    return bnb::camera_orientation::deg_180;
                case EPOrientation::EPOrientationAngles90:
                    return bnb::camera_orientation::deg_90;
                case EPOrientation::EPOrientationAngles270:
                    return bnb::camera_orientation::deg_270;
                default:
                    return bnb::camera_orientation::deg_0;
            }
        }

        CVPixelBufferRef get_oriented_image(EPOrientation orientation, bool is_y_flip)
        {
            glFlush();
            if (orientation != EPOrientation::EPOrientationAngles0 || is_y_flip) {
                if (m_prev_orientation != static_cast<int>(orientation)) {
                    if (m_offscreenPostProcessingPixelBuffer != nullptr) {
                        cleanPostProcessRenderingTargets();
                    }
                    m_prev_orientation = static_cast<int>(orientation);
                }

                if (m_offscreenPostProcessingPixelBuffer == nullptr) {
                    setupOffscreenPostProcessingPixelBuffer(orientation);
                    setupOffscreenPostProcessingRenderTarget(orientation);
                }

                preparePostProcessingRendering();
                m_program->use();
                m_frame_surface_handler->set_orientation(get_camera_orientation(orientation));
                m_frame_surface_handler->set_y_flip(is_y_flip);
                // Call once for perf
                m_frame_surface_handler->update_vertices_buffer();
                m_frame_surface_handler->draw();
                m_program->unuse();
                glFlush();
                return m_offscreenPostProcessingPixelBuffer;
            }
            return m_offscreenRenderPixelBuffer;
        }

    private:
        size_t m_width;
        size_t m_height;
        int m_prev_orientation = -1;
        EAGLContext* m_eagl_context = nil;
        GLuint m_framebuffer{0};
        GLuint m_postProcessingFramebuffer{0};
        CVOpenGLESTextureCacheRef m_videoTextureCache;
        CVPixelBufferRef m_offscreenRenderPixelBuffer;
        CVPixelBufferRef m_offscreenPostProcessingPixelBuffer{nullptr};
        CVOpenGLESTextureRef m_offscreenRenderTexture;
        CVOpenGLESTextureRef m_offscreenPostProcessingRenderTexture{nullptr};

        std::unique_ptr<bnb::program> m_program;
        std::unique_ptr<oep_frame_surface_handler> m_frame_surface_handler;
    };
}

@interface BNBOffscreenEffectPlayer ()

- (void)initOEPWithWidth:(NSUInteger)width andHight:(NSUInteger)height;

- (CVPixelBufferRef)processOutputInYUVFullRange:(CVPixelBufferRef)inputPixelBuffer CF_RETURNS_RETAINED;
- (CVPixelBufferRef)processOutputInYUVVideoRange:(CVPixelBufferRef)inputPixelBuffer CF_RETURNS_RETAINED;

- (CVPixelBufferRef)processOutputInBGRA:(CVPixelBufferRef)inputPixelBuffer CF_RETURNS_RETAINED;

- (CVPixelBufferRef)convertYUVVideoRangeToARGB:(CVPixelBufferRef)pixelBuffer CF_RETURNS_NOT_RETAINED;

- (void)oep_execute_async_completion:(BNBOEPVoidBlock _Nonnull)op completion:(BNBOEPVoidBlock _Nonnull)completion;
- (void)oep_execute_sync:(BNBOEPVoidBlock _Nonnull)op;

- (NSInteger)getFaceOrientation:(EpImageFormat*)imageFormat;

- (EPOrientation)getOEPOrientation;

- (CVPixelBufferRef)processImage:(BNBFullImageData*)inputData targetOrientation:(EPOrientation)targetOrientation isYFlip:(BOOL)isYFlip;

@property(nonatomic, strong) dispatch_queue_t oepSerialQueue;
@property(nonatomic, strong) dispatch_queue_t oepSerialCompletionQueue;

@property(nonatomic, strong) CMMotionManager* motionManager;
@property(nonatomic, strong) BNBEffectPlayer* effectPlayer;
@end

@implementation BNBOffscreenEffectPlayer
{
    NSUInteger _width;
    NSUInteger _height;
    std::atomic<unsigned int> _incomingFrameQueueTaskCount;
    std::unique_ptr<offscreen_renderer> _offscreen_renderer;
}

- (id)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"-init is not a valid initializer for the class BNBOffscreenEffectPlayer"
                                 userInfo:nil];
}

- (void)oep_execute_async_completion:(BNBOEPVoidBlock)op completion:(BNBOEPVoidBlock)completion
{
    dispatch_async(self.oepSerialQueue, ^{
      op();
      dispatch_async(self.oepSerialCompletionQueue, ^{
        completion();
      });
    });
}

- (void)oep_execute_sync:(BNBOEPVoidBlock)op
{
    dispatch_sync(self.oepSerialQueue, ^{
      op();
    });
}

- (void)enableAudio:(BOOL)enable
{
    NSAssert(self.effectPlayer != nil, @"No OffscreenEffectPlayer");
    [self.effectPlayer enableAudio:enable];
}

- (void)initOEPWithWidth:(NSUInteger)width andHight:(NSUInteger)height
{
    self.oepSerialQueue = dispatch_queue_create("com.banuba.oep.serial.queue", DISPATCH_QUEUE_SERIAL);
    self.oepSerialCompletionQueue = dispatch_queue_create("com.banuba.oep.serial.queue.completion", DISPATCH_QUEUE_SERIAL);

    self.motionManager = [[CMMotionManager alloc] init];
    [self.motionManager startDeviceMotionUpdates];

    _incomingFrameQueueTaskCount = 0;

    _width = width;
    _height = height;
}

- (instancetype)initWithEffectPlayer:(BNBEffectPlayer*)effectPlayer
                      offscreenWidth:(NSUInteger)width
                      offscreenHight:(NSUInteger)height
{
    if (self.effectPlayer != nil) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"Offscreen effect player already initialized."
                                     userInfo:nil];
    }
    if (effectPlayer == nil) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"Invalid instance of Effect Player."
                                     userInfo:nil];
    }

    self = [super init];

    if (self != nil) {
        [self initOEPWithWidth:width andHight:height];

        [self oep_execute_sync:^{
          _offscreen_renderer = std::make_unique<offscreen_renderer>(width, height);
          self.effectPlayer = effectPlayer;
          // Context activated in offscreen rendered constructor
          [self.effectPlayer surfaceCreated:(int32_t) width height:(int32_t) height];
        }];
    }

    return self;
}

- (instancetype)initWithEffectWidth:(NSUInteger)width
                          andHeight:(NSUInteger)height
                        manualAudio:(BOOL)manual
{
    if (self.effectPlayer != nil) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"Offscreen effect player already initialized."
                                     userInfo:nil];
    }

    self = [super init];

    if (self != nil) {
        [self initOEPWithWidth:width andHight:height];

        [self oep_execute_sync:^{
          _offscreen_renderer = std::make_unique<offscreen_renderer>(width, height);
          BNBEffectPlayerConfiguration* config = [BNBEffectPlayerConfiguration effectPlayerConfigurationWithFxWidth:(int32_t) width fxHeight:(int32_t) height nnEnable:BNBNnMode::BNBNnModeAutomatically faceSearch:BNBFaceSearchMode::BNBFaceSearchModeGood jsDebuggerEnable:NO manualAudio:manual];
          self.effectPlayer = [BNBEffectPlayer create:config];
          // Context activated in offscreen rendered constructor
          [self.effectPlayer surfaceCreated:(int32_t) width height:(int32_t) height];
        }];
    }

    return self;
}

- (void)dealloc
{
    if (self.effectPlayer) {
        [self.effectPlayer surfaceDestroyed];
    }
    [self.motionManager stopDeviceMotionUpdates];
}

- (EPOrientation)getOEPOrientation
{
    const auto& graviy = self.motionManager.deviceMotion.gravity;
    if (abs(graviy.y) < abs(graviy.x)) {
        return graviy.x > 0 ? EPOrientationAngles180 /*landscapeRight*/ : EPOrientationAngles0 /*landscapeLeft*/;
    } else {
        return graviy.y > 0 ? EPOrientationAngles90 /*portraitUpsideDown*/ : EPOrientationAngles270 /*portrait*/;
    }
}

- (NSInteger)getFaceOrientation:(EpImageFormat*)imageFormat
{
    __block NSInteger faceOrientation = 0;

    /**
     * The face_orientation parameter gives a clue about a head direction on the image, after image oriented according to the orientation parameter if ui orientation is locked.
     * e.g. image passed by long side head directed to the left - image orientation 90, but device has orientation 0, therefore head directed to the top, so after applying orientation to the image,
     * face will be oriented to the right (rotation 90 degries clockwise or 270 counterclockwise) it means that we should rotate image additionally to 90 degrees (counterclockwise) to get head directed to the top.
     * However, if image mirrored (corresponding parameters is true), then it will be applied as a part of image orientation process and then face orientation should change its rotation direction to negative one,
     * e.g. in the example above after applying image orientation head will be directed to the left, because of mirroring (in general incorrectly applied, but c'est la vie), so the face orientation in this case will be -90
     * (rotate clockwise).
     */
    auto determineFaceOrientation = ^{
      EPOrientation oepOrientation = [self getOEPOrientation];
      if (oepOrientation == EPOrientationAngles0 || oepOrientation == EPOrientationAngles180) {
          faceOrientation = (imageFormat->isMirrored ? 1 : -1) * (oepOrientation == EPOrientationAngles0 ? 90 : -90);
      } else if (oepOrientation == EPOrientationAngles90) {
          faceOrientation = 180;
      }
    };

    // It will not work if image dimensions are equal.
    if (imageFormat->imageSize.width > imageFormat->imageSize.height) {
        // case 1: frame passed in landscape mode
        if (imageFormat->orientation == EPOrientationAngles90 || imageFormat->orientation == EPOrientationAngles270) {
            // portrait, check if landscape detected
            determineFaceOrientation();
        }
    } else {
        // case 2: frame passed in portrait mode
        if (imageFormat->orientation == EPOrientationAngles0 || imageFormat->orientation == EPOrientationAngles180) {
            // portrait, check if landscape detected
            determineFaceOrientation();
        }
    }
    return faceOrientation;
}

- (CVPixelBufferRef)processImage:(BNBFullImageData*)inputData targetOrientation:(EPOrientation)targetOrientation isYFlip:(BOOL)isYFlip
{
    _offscreen_renderer->prepareRendering();

    [self.effectPlayer pushFrame:inputData];

    while ([self.effectPlayer draw] < 0) {
        std::this_thread::yield();
    }

    return _offscreen_renderer->get_oriented_image(targetOrientation, isYFlip != NO);
}

- (void)processImage:(CVPixelBufferRef)pixelBuffer withFormat:(EpImageFormat*)imageFormat frameTimestamp:(NSNumber*)timestamp completion:(BNBOEPImageReadyBlock _Nonnull)completion
{
    __block OSType pixelFormatType = CVPixelBufferGetPixelFormatType(pixelBuffer);
    // TODO: BanubaSdk doesn't support videoRannge(420v) only fullRange(420f) (the YUV on rendering will be processed as 420f), need to add support for BT601 and BT709 videoRange, process as ARGB
    if (pixelFormatType == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) {
        pixelBuffer = [self convertYUVVideoRangeToARGB:pixelBuffer];
    }
    BNBFullImageData* inputData = [[BNBFullImageData alloc] init:pixelBuffer cameraOrientation:(BNBCameraOrientation) imageFormat->orientation requireMirroring:(imageFormat->isMirrored ? YES : NO) faceOrientation:[self getFaceOrientation:imageFormat] fieldOfView:(float) 60];

    BOOL isYFlip = imageFormat->isYFlip;
    EPOrientation targetOrientation = imageFormat->resultedImageOrientation;
    bool outputOGLTexture = imageFormat->outputTexture != NO;
    if (imageFormat->needAlphaInOutput || imageFormat->overrideOutputToBGRA) {
        pixelFormatType = kCVPixelFormatType_32BGRA;
    }

    __block CVPixelBufferRef retBuffer = nullptr;
    __weak auto self_weak_ = self;
    _incomingFrameQueueTaskCount++;
    [self
        oep_execute_async_completion:^{
          if (_incomingFrameQueueTaskCount <= 1) {
              __strong auto self = self_weak_;
              auto oepImagePixelBuffer = [self processImage:inputData targetOrientation:targetOrientation isYFlip:isYFlip];

              if (outputOGLTexture) {
                  // retain buffer since method returns retained one.
                  CVPixelBufferRetain(oepImagePixelBuffer);
                  retBuffer = oepImagePixelBuffer;
              } else {
                  switch (pixelFormatType) {
                      case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
                          retBuffer = [self processOutputInYUVVideoRange:oepImagePixelBuffer];
                          break;
                      case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:
                          retBuffer = [self processOutputInYUVFullRange:oepImagePixelBuffer];
                          break;
                      case kCVPixelFormatType_32BGRA:
                          retBuffer = [self processOutputInBGRA:oepImagePixelBuffer];
                          break;
                      default:
                          // Frame dropped: unsupported target pixel format.
                          break;
                  }
              }
          } else {
              // Frame dropped: too many frames in queue.
          }
          _incomingFrameQueueTaskCount--;
        }
        completion:^{
          if (completion) {
              completion(retBuffer, timestamp);
              if (retBuffer) {
                  CVPixelBufferRelease(retBuffer);
              }
          }
        }];
}

- (CVPixelBufferRef)processImage:(CVPixelBufferRef)pixelBuffer withFormat:(EpImageFormat*)imageFormat
{
    OSType pixelFormatType = CVPixelBufferGetPixelFormatType(pixelBuffer);
    // TODO: BanubaSdk doesn't support videoRannge(420v) only fullRange(420f) (the YUV on rendering will be processed as 420f), need to add support for BT601 and BT709 videoRange, process as ARGB
    if (pixelFormatType == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) {
        pixelBuffer = [self convertYUVVideoRangeToARGB:pixelBuffer];
    }
    BNBFullImageData* inputData = [[BNBFullImageData alloc] init:pixelBuffer cameraOrientation:(BNBCameraOrientation) imageFormat->orientation requireMirroring:(imageFormat->isMirrored ? YES : NO) faceOrientation:[self getFaceOrientation:imageFormat] fieldOfView:(float) 60];

    BOOL isYFlip = imageFormat->isYFlip;
    EPOrientation targetOrientation = imageFormat->resultedImageOrientation;
    __block CVPixelBufferRef oepImagePixelBuffer;
    [self oep_execute_sync:^{
      oepImagePixelBuffer = [self processImage:inputData targetOrientation:targetOrientation isYFlip:isYFlip];
    }];

    if (imageFormat->outputTexture) {
        // retain buffer since method returns retained one.
        CVPixelBufferRetain(oepImagePixelBuffer);
        return oepImagePixelBuffer;
    }

    if (imageFormat->needAlphaInOutput || imageFormat->overrideOutputToBGRA) {
        pixelFormatType = kCVPixelFormatType_32BGRA;
    }
    CVPixelBufferRef retBuffer = nullptr;
    switch (pixelFormatType) {
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
            retBuffer = [self processOutputInYUVVideoRange:oepImagePixelBuffer];
            break;
        case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:
            retBuffer = [self processOutputInYUVFullRange:oepImagePixelBuffer];
            break;
        case kCVPixelFormatType_32BGRA:
            retBuffer = [self processOutputInBGRA:oepImagePixelBuffer];
            break;
        default:
            break;
    }
    return retBuffer;
}

- (CVPixelBufferRef)processOutputInYUVFullRange:(CVPixelBufferRef)inputPixelBuffer
{
    CVPixelBufferLockBaseAddress(inputPixelBuffer, kCVPixelBufferLock_ReadOnly);
    unsigned char* baseAddress = (unsigned char*) CVPixelBufferGetBaseAddress(inputPixelBuffer);
    auto width = CVPixelBufferGetWidth(inputPixelBuffer);
    auto height = CVPixelBufferGetHeight(inputPixelBuffer);
    auto bytesPerRow = CVPixelBufferGetBytesPerRow(inputPixelBuffer);

    NSDictionary* pixelAttributes = @{(id) kCVPixelBufferIOSurfacePropertiesKey: @{}};
    CVPixelBufferRef pixelBuffer = NULL;
    auto result = CVPixelBufferCreate(
        kCFAllocatorDefault,
        width,
        height,
        kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
        (__bridge CFDictionaryRef)(pixelAttributes),
        &pixelBuffer);
    NSParameterAssert(result == kCVReturnSuccess && pixelBuffer != NULL);

    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void* yDestPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    size_t yWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
    size_t yHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
    size_t yBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);

    void* uvDestPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    size_t uvWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1);
    size_t uvHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1);
    size_t uvBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);

    vImage_Buffer sourceBufferInfo = {
        .width = static_cast<vImagePixelCount>(width),
        .height = static_cast<vImagePixelCount>(height),
        .rowBytes = bytesPerRow,
        .data = baseAddress};
    vImage_Buffer yBufferInfo = {
        .width = yWidth,
        .height = yHeight,
        .rowBytes = yBytesPerRow,
        .data = yDestPlane};
    vImage_Buffer uvBufferInfo = {
        .width = uvWidth,
        .height = uvHeight,
        .rowBytes = uvBytesPerRow,
        .data = uvDestPlane};

    const uint8_t permuteMap[4] = {3, 0, 1, 2}; // Convert to ARGB pixel format

    static vImage_ARGBToYpCbCr info;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      vImage_YpCbCrPixelRange pixelRange = (vImage_YpCbCrPixelRange){0, 128, 255, 255, 255, 1, 255, 0};
      vImageConvert_ARGBToYpCbCr_GenerateConversion(
          kvImage_ARGBToYpCbCrMatrix_ITU_R_601_4,
          &pixelRange,
          &info,
          kvImageARGB8888,
          kvImage420Yp8_CbCr8,
          0);
    });

    vImageConvert_ARGB8888To420Yp8_CbCr8(
        &sourceBufferInfo,
        &yBufferInfo,
        &uvBufferInfo,
        &info,
        permuteMap,
        kvImageDoNotTile);

    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

    CVPixelBufferUnlockBaseAddress(inputPixelBuffer, kCVPixelBufferLock_ReadOnly);

    return pixelBuffer;
}

- (CVPixelBufferRef)processOutputInYUVVideoRange:(CVPixelBufferRef)inputPixelBuffer
{
    CVPixelBufferLockBaseAddress(inputPixelBuffer, kCVPixelBufferLock_ReadOnly);
    unsigned char* baseAddress = (unsigned char*) CVPixelBufferGetBaseAddress(inputPixelBuffer);
    auto width = CVPixelBufferGetWidth(inputPixelBuffer);
    auto height = CVPixelBufferGetHeight(inputPixelBuffer);
    auto bytesPerRow = CVPixelBufferGetBytesPerRow(inputPixelBuffer);

    NSDictionary* pixelAttributes = @{(id) kCVPixelBufferIOSurfacePropertiesKey: @{}};
    CVPixelBufferRef pixelBuffer = NULL;
    auto result = CVPixelBufferCreate(
        kCFAllocatorDefault,
        width,
        height,
        kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
        (__bridge CFDictionaryRef)(pixelAttributes),
        &pixelBuffer);
    NSParameterAssert(result == kCVReturnSuccess && pixelBuffer != NULL);

    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void* yDestPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    size_t yWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
    size_t yHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
    size_t yBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);

    void* uvDestPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    size_t uvWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1);
    size_t uvHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1);
    size_t uvBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);

    vImage_Buffer sourceBufferInfo = {
        .width = static_cast<vImagePixelCount>(width),
        .height = static_cast<vImagePixelCount>(height),
        .rowBytes = bytesPerRow,
        .data = baseAddress};
    vImage_Buffer yBufferInfo = {
        .width = yWidth,
        .height = yHeight,
        .rowBytes = yBytesPerRow,
        .data = yDestPlane};
    vImage_Buffer uvBufferInfo = {
        .width = uvWidth,
        .height = uvHeight,
        .rowBytes = uvBytesPerRow,
        .data = uvDestPlane};

    const uint8_t permuteMap[4] = {3, 0, 1, 2}; // Convert to ARGB pixel format

    static vImage_ARGBToYpCbCr info;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      vImage_YpCbCrPixelRange pixelRange = (vImage_YpCbCrPixelRange){16, 128, 235, 240, 255, 0, 255, 1};
      vImageConvert_ARGBToYpCbCr_GenerateConversion(
          kvImage_ARGBToYpCbCrMatrix_ITU_R_601_4,
          &pixelRange,
          &info,
          kvImageARGB8888,
          kvImage420Yp8_CbCr8,
          0);
    });

    vImageConvert_ARGB8888To420Yp8_CbCr8(
        &sourceBufferInfo,
        &yBufferInfo,
        &uvBufferInfo,
        &info,
        permuteMap,
        kvImageDoNotTile);

    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

    CVPixelBufferUnlockBaseAddress(inputPixelBuffer, kCVPixelBufferLock_ReadOnly);

    return pixelBuffer;
}

- (CVPixelBufferRef)processOutputInBGRA:(CVPixelBufferRef)inputPixelBuffer
{
    CVPixelBufferLockBaseAddress(inputPixelBuffer, kCVPixelBufferLock_ReadOnly);
    unsigned char* baseAddress = (unsigned char*) CVPixelBufferGetBaseAddress(inputPixelBuffer);
    auto width = CVPixelBufferGetWidth(inputPixelBuffer);
    auto height = CVPixelBufferGetHeight(inputPixelBuffer);
    auto bytesPerRow = CVPixelBufferGetBytesPerRow(inputPixelBuffer);

    NSDictionary* pixelAttributes = @{(id) kCVPixelBufferIOSurfacePropertiesKey: @{}};
    CVPixelBufferRef pixelBuffer = NULL;
    auto result = CVPixelBufferCreate(
        kCFAllocatorDefault,
        width,
        height,
        kCVPixelFormatType_32BGRA,
        (__bridge CFDictionaryRef)(pixelAttributes),
        &pixelBuffer);
    NSParameterAssert(result == kCVReturnSuccess && pixelBuffer != NULL);

    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void* rgbOut = CVPixelBufferGetBaseAddress(pixelBuffer);
    size_t rgbOutWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
    size_t rgbOutHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
    size_t rgbOutBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);

    vImage_Buffer sourceBufferInfo = {
        .width = static_cast<vImagePixelCount>(width),
        .height = static_cast<vImagePixelCount>(height),
        .rowBytes = bytesPerRow,
        .data = baseAddress};
    vImage_Buffer outputBufferInfo = {
        .width = rgbOutWidth,
        .height = rgbOutHeight,
        .rowBytes = rgbOutBytesPerRow,
        .data = rgbOut};

    const uint8_t permuteMap[4] = {2, 1, 0, 3}; // Convert to BGRA pixel format

    vImagePermuteChannels_ARGB8888(&sourceBufferInfo, &outputBufferInfo, permuteMap, kvImageNoFlags);

    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

    CVPixelBufferUnlockBaseAddress(inputPixelBuffer, kCVPixelBufferLock_ReadOnly);

    return pixelBuffer;
}

- (CVPixelBufferRef)convertYUVVideoRangeToARGB:(CVPixelBufferRef)pixelBuffer
{
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void* yPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    size_t yWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
    size_t yHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
    size_t yBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);

    void* uvPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    size_t uvWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1);
    size_t uvHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1);
    size_t uvBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);

    NSDictionary* pixelAttributes = @{(id) kCVPixelBufferIOSurfacePropertiesKey: @{}};
    CVPixelBufferRef pixelBufferTmp = NULL;
    auto result = CVPixelBufferCreate(
        kCFAllocatorDefault,
        yWidth,
        yHeight,
        kCVPixelFormatType_32ARGB,
        (__bridge CFDictionaryRef)(pixelAttributes),
        &pixelBufferTmp);
    NSParameterAssert(result == kCVReturnSuccess && pixelBuffer != NULL);
    CFAutorelease(pixelBufferTmp);
    CVPixelBufferLockBaseAddress(pixelBufferTmp, 0);

    void* rgbTmp = CVPixelBufferGetBaseAddress(pixelBufferTmp);
    size_t rgbTmpWidth = CVPixelBufferGetWidthOfPlane(pixelBufferTmp, 0);
    size_t rgbTmpHeight = CVPixelBufferGetHeightOfPlane(pixelBufferTmp, 0);
    size_t rgbTmpBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBufferTmp, 0);

    vImage_Buffer ySrcBufferInfo = {
        .width = yWidth,
        .height = yHeight,
        .rowBytes = yBytesPerRow,
        .data = yPlane};
    vImage_Buffer uvSrcBufferInfo = {
        .width = uvWidth,
        .height = uvHeight,
        .rowBytes = uvBytesPerRow,
        .data = uvPlane};

    vImage_Buffer tmpBufferInfo = {
        .width = rgbTmpWidth,
        .height = rgbTmpHeight,
        .rowBytes = rgbTmpBytesPerRow,
        .data = rgbTmp};

    const uint8_t permuteMap[4] = {0, 1, 2, 3};

    static vImage_YpCbCrToARGB infoYpCbCr;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      vImage_YpCbCrPixelRange pixelRangeVideoRange = (vImage_YpCbCrPixelRange){16, 128, 235, 240, 255, 0, 255, 1};
      vImageConvert_YpCbCrToARGB_GenerateConversion(
          kvImage_YpCbCrToARGBMatrix_ITU_R_709_2,
          &pixelRangeVideoRange,
          &infoYpCbCr,
          kvImage420Yp8_Cb8_Cr8,
          kvImageARGB8888,
          0);
    });

    vImageConvert_420Yp8_CbCr8ToARGB8888(
        &ySrcBufferInfo,
        &uvSrcBufferInfo,
        &tmpBufferInfo,
        &infoYpCbCr,
        permuteMap,
        0,
        kvImageDoNotTile);


    CVPixelBufferUnlockBaseAddress(pixelBufferTmp, 0);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

    return pixelBufferTmp;
}

- (void)loadEffect:(NSString* _Nonnull)effectName completion:(BNBOEPVoidBlock _Nonnull)completion
{
    NSAssert(self.effectPlayer != nil, @"No OffscreenEffectPlayer");
    __weak auto self_weak_ = self;
    [self
        oep_execute_async_completion:^{
          __strong auto self = self_weak_;
          _offscreen_renderer->activateContext();

          BNBEffectManager* em = [self.effectPlayer effectManager];
          if (em) {
              [em load:effectName];
          }
        }
        completion:^{
          if (completion) {
              completion();
          }
        }];
}

- (void)loadEffect:(NSString* _Nonnull)effectName
{
    NSAssert(self.effectPlayer != nil, @"No OffscreenEffectPlayer");
    [self oep_execute_sync:^{
      _offscreen_renderer->activateContext();

      BNBEffectManager* em = [self.effectPlayer effectManager];
      if (em) {
          [em load:effectName];
      }
    }];
}


- (void)unloadEffect
{
    NSAssert(self.effectPlayer != nil, @"No OffscreenEffectPlayer");
    [self oep_execute_sync:^{
      _offscreen_renderer->activateContext();

      BNBEffectManager* em = [self.effectPlayer effectManager];
      if (em) {
          [em load:@""];
      }
    }];
}


- (void)surfaceChanged:(NSUInteger)width withHeight:(NSUInteger)height
{
    NSAssert(self.effectPlayer != nil, @"No OffscreenEffectPlayer");
    [self oep_execute_sync:^{
      _offscreen_renderer->activateContext();
      _offscreen_renderer->surface_Ñhanged((int32_t) width, (int32_t) height);

      [self.effectPlayer surfaceChanged:(int32_t) width height:(int32_t) height];
      BNBEffectManager* em = [self.effectPlayer effectManager];
      if (em) {
          [em setEffectSize:(int32_t) width fxHeight:(int32_t) height];
      }
    }];
}

- (void)callJsMethod:(NSString* _Nonnull)method withParam:(NSString* _Nonnull)param
{
    NSAssert(self.effectPlayer != nil, @"No OffscreenEffectPlayer");
    [self oep_execute_sync:^{
      _offscreen_renderer->activateContext();

      BNBEffectManager* em = [self.effectPlayer effectManager];
      if (em) {
          BNBEffect* curEffect = [em current];
          if (curEffect) {
              [curEffect callJsMethod:method params:param];
          }
      }
    }];
}


@end
