//
//  CallJSMethodWrapper.m
//  BanubaFiltersAgoraExtension
//
//  Created by Andrei Sak on 19.11.21.
//

#import "CallJSMethodWrapper.h"

@implementation CallJSMethodWrapper

- (instancetype)initWithMethodName:(NSString *)methodName methodParams:(NSString *)methodParams {
  self = [super init];
  
  if (self) {
    self.methodName = methodName;
    self.methodParams = methodParams;
  }
  
  return self;
}

+ (CallJSMethodWrapper *)makeWrapperFromJSONString:(NSString *)jsonString {
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *jsonError;
    NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                               options:kNilOptions
                                                                 error:&jsonError];
    
    if (jsonObject) {
      NSLog(@"json object %@", jsonObject);
      // JSON string should have next structure
      NSString *methodName = [jsonObject objectForKey:@"methodName"];
      NSString *methodParams = [jsonObject objectForKey:@"methodParams"];
      CallJSMethodWrapper *wrapper = [[CallJSMethodWrapper alloc] initWithMethodName:methodName
                                                                        methodParams:methodParams];
      return wrapper;
    } else {
      NSLog(@"json error %@", jsonError);
      return nil;
    }
}

@end
