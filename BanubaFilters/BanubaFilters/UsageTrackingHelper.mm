#import <Foundation/Foundation.h>
#import "UsageTrackingHelper.h"
#import <CommonCrypto/CommonCrypto.h>

NSTimeInterval const USAGE_TRACKING_INTERVAL = 60.0;
// TODO - add stage/prod urls
NSString* const LOG_USAGE_REQUEST_URL = @"https://5u2dm7oc6qqbfmjtk3rujkkg740nffnt.lambda-url.us-east-1.on.aws/customer-project-billing-add";
NSString* const PARAMS_FORMAT = @"{\"appKey\": \"%@\", \"amount\": %i, \"signature\": \"%@\"}";

@interface UsageTrackingHelper()

@property(nonatomic, assign) NSTimeInterval currentUsageTime;
@property(nonatomic, strong) NSTimer *trackingTimer;

- (void)trackUsageInformation;
- (void)createTrackingTimer;
- (void)invalidateTrackingTimer;

@end

@implementation UsageTrackingHelper

- (instancetype)initWithAppKey:(NSString *)appKey appSecret:(NSString *)appSecret {
    self = [super init];
    if (self) {
        self.currentUsageTime = 0.0;
        self.appKey = appKey;
        self.appSecret = appSecret;
    }
    
    return self;
}

- (void)dealloc {
    [self invalidateTrackingTimer];
}

- (void)startTracking {
    [self invalidateTrackingTimer];
    [self createTrackingTimer];
}

- (void)stopTracking {
    [self invalidateTrackingTimer];
    [self trackUsageInformation];
}

- (void)logUsageTime:(NSTimeInterval)usageTime {
    self.currentUsageTime += usageTime;
}

- (void)trackUsageInformation {
    int usageDuration = (int)round(self.currentUsageTime);
    if (usageDuration == 0) {
        return;
    }
    
    NSString *value = [self.appKey stringByAppendingString:@(usageDuration).stringValue];
    NSString *signature = EncodedSecString(SHA1, self.appSecret, value);
    NSString *content = [NSString stringWithFormat:PARAMS_FORMAT, self.appKey, usageDuration, signature];
    
    NSURLSessionConfiguration *sessionCfg = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionCfg.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    sessionCfg.URLCache = nil;
    NSURLSession *session = [NSURLSession sessionWithConfiguration: sessionCfg];
    
    NSURL *url = [NSURL URLWithString: LOG_USAGE_REQUEST_URL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url];
    request.HTTPBody = [content dataUsingEncoding: NSUTF8StringEncoding];
    request.HTTPMethod = @"POST";
    
    NSTimeInterval loggedTime = self.currentUsageTime;
    self.currentUsageTime = 0.0;
    
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSError *parseError = nil;
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        
        BOOL isStatusSuccess = false;
        if (parseError == nil && responseData != nil) {
            NSString *status = [responseData objectForKey:@"status"];
            isStatusSuccess = [status isEqualToString:@"success"];
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        // If request was unsuccessful, restore logged duration back.
        if ([httpResponse statusCode] != 200 || error != nil || !isStatusSuccess) {
            self.currentUsageTime += loggedTime;
        }
    }];
    [postDataTask resume];
}

- (void)createTrackingTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.trackingTimer = [NSTimer scheduledTimerWithTimeInterval:USAGE_TRACKING_INTERVAL
                                                              target:self
                                                            selector:@selector(trackUsageInformation)
                                                            userInfo:nil
                                                             repeats:YES];
    });
}

- (void)invalidateTrackingTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.trackingTimer invalidate];
        self.trackingTimer = nil;
    });
}

@end

extern NSString *EncodedSecString(SecurityAlgorithm algorithmType, NSString *key, NSString *dataStr) {
    NSUInteger size;
    uint32_t algorithm;
    
    switch (algorithmType) {
        case MD5:       size = CC_MD5_DIGEST_LENGTH;    algorithm = kCCHmacAlgMD5;      break;
        case SHA1:      size = CC_SHA1_DIGEST_LENGTH;   algorithm = kCCHmacAlgSHA1;     break;
        case SHA224:    size = CC_SHA224_DIGEST_LENGTH; algorithm = kCCHmacAlgSHA224;   break;
        case SHA256:    size = CC_SHA256_DIGEST_LENGTH; algorithm = kCCHmacAlgSHA256;   break;
        case SHA384:    size = CC_SHA384_DIGEST_LENGTH; algorithm = kCCHmacAlgSHA384;   break;
        case SHA512:    size = CC_SHA512_DIGEST_LENGTH; algorithm = kCCHmacAlgSHA512;   break;
    }
    
    unsigned char* resultData[size];
    memset(resultData, 0, size);
    const char *cKey = [key cStringUsingEncoding:NSUTF8StringEncoding];
    const char *cData = [dataStr cStringUsingEncoding:NSUTF8StringEncoding];
    CCHmac(CCHmacAlgorithm(algorithm), cKey, strlen(cKey), cData, strlen(cData), resultData);
    
    NSData *result = [NSData dataWithBytes:resultData length:size];
    NSString *resultStr = [result base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength];
    
    return resultStr;
}
