#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>

@class BNBEffectPlayer;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, EPOrientation) {
    EPOrientationAngles0,
    EPOrientationAngles90,
    EPOrientationAngles180,
    EPOrientationAngles270
};


typedef struct
{
    /**
     * size of input image
     */
    CGSize imageSize;
    /**
     * Image orientation, Angles0 means head at the top, other angles mean counterlockwise rotation
     */
    EPOrientation orientation;
    /**
     * Resulted image orientation. If coincide with orientation then image will be returned in the same orientation.
     * Set to EPOrientationAngles0 to keep OEP default orientation.
     */
    EPOrientation resultedImageOrientation;
    /**
     * If YES then resulted image will be mirrored
     */
    BOOL isMirrored;
    /**
     * if YES, (0,0) in bottom left, else in top left. This parameter overrided if orientation and resultedImageOrientation are equal except the case then this value is EPOrientationAngles0
     */
    BOOL isYFlip;
    /**
     * TODO: Add support to return YUV with Alpha. Returns BGRA since YUV-Alpha is not supported yet
     * Used for the cases then returned image should include valid alpha channel
     */
    BOOL needAlphaInOutput;
    /**
     * Input image format determines output image format, conversion takes time. EffectPlayer produce images in RGBA, if you request BGRA the time to get BGRA is minimal.
     */
    BOOL overrideOutputToBGRA;
    /**
     * Omit conversion, returned pixel buffer is the CVPixelBuffer which associated with Rendered Texture. Buffer type is BGRA, but texture is RGBA, so if such buffer will be drawn without additional processing its colors will looks unexpectedly.
     */
    BOOL outputTexture;
} EpImageFormat;

/**
 * void block for completions
 */
typedef void (^BNBOEPVoidBlock)(void);
/**
 * block to return resulted image after processing
 * NOTE: pixelBuffer can be null if frame dropped because of queue or because passed unsupported image format for target image
 */
typedef void (^BNBOEPImageReadyBlock)(_Nullable CVPixelBufferRef pixelBuffer, NSNumber* timeStamp);

/**
 * All methods must be called from the same thread
 * (in which the object was created BNBOffscreenEffectPlayer)
 * All methods are synchronous
 *
 * WARNING: SDK should be initialized with BNBUtilityManager before BNBOfscreenEffectPlayer creation
 */
@interface BNBOffscreenEffectPlayer : NSObject

/**
 * Initialize with configured BNBEffectPlayer
 */
- (instancetype)initWithEffectPlayer:(BNBEffectPlayer*)effectPlayer
                      offscreenWidth:(NSUInteger)width
                      offscreenHight:(NSUInteger)height;

/**
 * effectWidth andHeight the size of the inner area where the effect is drawn
 * NOTE: There is an assumption that it is user responsibility to make sure that
 *       size of rendering area is equal to the image size passed to processImage
 */
- (instancetype)initWithEffectWidth:(NSUInteger)width
                          andHeight:(NSUInteger)height
                        manualAudio:(BOOL)manual;

/**
 * EpImageFormat::imageSize - size of input image
 * the size of the output image is equal to the size of the inner area where the effect is drawn
 */
- (nullable CVPixelBufferRef)processImage:(CVPixelBufferRef)pixelBuffer withFormat:(EpImageFormat*)imageFormat CF_RETURNS_RETAINED;

/**
 * Async version of processImage method
 */
- (void)processImage:(CVPixelBufferRef)pixelBuffer withFormat:(EpImageFormat*)imageFormat frameTimestamp:(NSNumber*)timestamp completion:(BNBOEPImageReadyBlock _Nonnull)completion;

/**
 * Load effect with specified name (used folder name)
 * effectName - usually it is folder name with effect resources on local storage
 */
- (void)loadEffect:(NSString*)effectName;

/**
 * Load effect with specified name asynchronously
 * effectName - usually it is folder name with effect resources on local storage
 */
- (void)loadEffect:(NSString* _Nonnull)effectName completion:(BNBOEPVoidBlock _Nonnull)completion;

/**
 * Deactivate current effect, the same can be reached by loading effect with the empty name via loadEffect
 */
- (void)unloadEffect;

/**
 * let effect player know that surface has changed
 */
- (void)surfaceChanged:(NSUInteger)width withHeight:(NSUInteger)height;

/**
 * When you use EffectPlayer with CallKit you should enable audio manually at the point when CallKit
 * notifies that its Audio Session is ready (CallKit's session is created in privileged mode, so it should be respected).
 */
- (void)enableAudio:(BOOL)enable;

/**
 * Let you call methods defined in the active effect's script passing additional data or changing effect's behaviour
 */
- (void)callJsMethod:(NSString*)method withParam:(NSString*)param;

@end

NS_ASSUME_NONNULL_END
