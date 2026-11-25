#import <UIKit/UIKit.h>
#import "../Shared/POKeyboardWire.h"
@interface POFloatingKeyboard : UIView
@property(nonatomic,copy) BOOL (^keyHandler)(NSInteger key);
@property(nonatomic,copy) void (^dismissHandler)(void);
@property(nonatomic,copy) void (^nativeHandler)(void);
- (void)placeInBounds:(CGRect)bounds safeInsets:(UIEdgeInsets)insets;
- (void)reportStatus:(POKeyStatus)status;
@end
