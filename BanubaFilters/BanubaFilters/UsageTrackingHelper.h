#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SecurityAlgorithm) {
    MD5,
    SHA1,
    SHA224,
    SHA256,
    SHA384,
    SHA512
};

extern NSString *EncodedSecString(SecurityAlgorithm algorithmType, NSString *key, NSString *dataStr);

@interface UsageTrackingHelper : NSObject

@property (nonatomic, copy) NSString *appKey;
@property (nonatomic, copy) NSString *appSecret;

- (instancetype)initWithAppKey:(NSString *)appKey appSecret:(NSString *)appSecret;

- (void)startTracking;
- (void)stopTracking;
- (void)logUsageTime:(NSTimeInterval) usageTime;

@end

NS_ASSUME_NONNULL_END
