#import <Foundation/Foundation.h>
#import "../Shared/POGestureWire.h"
@interface PORemoteGestureBridge : NSObject
@property (nonatomic, readonly, copy) NSString *bundle;
@property (nonatomic, readonly) BOOL ready;
- (BOOL)startForBundle:(NSString *)bundle handler:(void (^)(PORemoteTransform event))handler;
- (void)publishScale:(double)scale centerX:(double)x centerY:(double)y;
- (void)stop;
@end
