#import <UIKit/UIKit.h>
@interface POTwoFingerTransformGestureRecognizer : UIGestureRecognizer
@property (nonatomic, weak) UIView *coordinateView;
@property (nonatomic, readonly) CGFloat scaleFactor;
@property (nonatomic, readonly) CGPoint translation;
@property (nonatomic, readonly) CGPoint initialCenter;
@end
