//
//  CallJSMethodWrapper.h
//  BanubaFiltersAgoraExtension
//
//  Created by Andrei Sak on 19.11.21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CallJSMethodWrapper : NSObject

@property(strong, nonatomic) NSString *methodName;
@property(strong, nonatomic) NSString *methodParams;

+ (CallJSMethodWrapper *)makeWrapperFromJSONString:(NSString *)jsonString;

@end

NS_ASSUME_NONNULL_END
