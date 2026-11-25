#pragma once
#import <Foundation/Foundation.h>
static inline BOOL POGestureBundleSupported(NSString *bundle) {
    return [bundle isEqualToString:@"com.openai.chat"] || [bundle isEqualToString:@"com.360buy.jdmobile"];
}
static inline NSString *POGestureChannel(NSString *bundle,NSString *suffix) {
    return [NSString stringWithFormat:@"com.johndie.pulloverpro.gesture.v1.%@.%@",bundle,suffix];
}
