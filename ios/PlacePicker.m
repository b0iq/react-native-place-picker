#import "PlacePicker.h"

@implementation PlacePicker
RCT_EXPORT_MODULE()

@interface RCT_EXTERN_MODULE(PlacePicker, NSObject)

RCT_EXTERN_METHOD(pickPlace:(NSDictionary) options
                  withResolver:(RCTPromiseResolveBlock *)resolve
                  withRejector:(RCTPromiseRejectBlock *)reject)

// Don't compile this code when we build for the old architecture.
#ifdef RCT_NEW_ARCH_ENABLED
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativePlacePickerSpecJSI>(params);
}
#endif

@end
