//
//  BaseScrollView.m
//  PullOverPro
//
//  Created by Will Smillie on 4/8/19.
//

#import "BaseScrollView.h"
#import "POHandle.h"

@implementation BaseScrollView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    UIView *hitTestResult = [super hitTest:point withEvent:event];
    
    for (UIView *view = hitTestResult; view && view != self; view = view.superview) {
        if ([view isKindOfClass:[POHandle class]]) return view;
    }
    return nil;
}

-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event{
    for (UIView *view in self.subviews) {
        if (![view isKindOfClass:[POHandle class]] || view.hidden || view.alpha <= 0.01) continue;
        if ([view pointInside:[view convertPoint:point fromView:self] withEvent:event]) return YES;
    }
    return [super pointInside:point withEvent:event];
}

@end
