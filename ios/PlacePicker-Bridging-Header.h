
#ifdef RCT_NEW_ARCH_ENABLED
#import "RNPlacePickerSpec.h"

@interface PlacePicker : NSObject <NativePlacePickerSpec>
#else
#import <React/RCTBridgeModule.h>

@interface PlacePicker : NSObject <RCTBridgeModule>
#endif

@end
