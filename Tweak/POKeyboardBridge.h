#import <Foundation/Foundation.h>
#import "../Shared/POKeyboardWire.h"
@interface POKeyboardBridge : NSObject
- (BOOL)startForBundle:(NSString *)bundle status:(void (^)(POKeyStatus))status;
- (void)stop;
- (BOOL)sendKey:(NSInteger)key;
@end
