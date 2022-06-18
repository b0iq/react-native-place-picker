#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(PlacePicker, NSObject)

RCT_EXTERN_METHOD(pickPlaceWithOptions:(NSDictionary) options
                  withResolver:(RCTPromiseResolveBlock *)resolve
                  withRejector:(RCTPromiseRejectBlock *)reject)

RCT_EXTERN_METHOD(pickPlace:
                  (RCTPromiseResolveBlock *)resolve
                  withRejector:(RCTPromiseRejectBlock *)reject)
                  
+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

@end
