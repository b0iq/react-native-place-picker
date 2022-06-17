#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(PlacePicker, NSObject)

RCT_EXTERN_METHOD(multiply:(float)a withB:(float)b
                 withResolver:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(sqrt:(int)a
                 withResolver:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(functionWithPromise: (RCTPromiseResolveBlock)resolve rejecter: (RCTPromiseRejectBlock)reject)

@end
