//
//  PullOverWindow.m
//  PullOverPro
//
//  Created by Will Smillie on 4/8/19.
//

#import "PullOverWindow.h"
#import "POApplicationHelper.h"

@implementation PullOverWindow
@synthesize controller;

+ (id)sharedWindow {
    static PullOverWindow *window = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        window = [[self alloc] init];
    });
    
    return window;
}

- (id)init{
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if(self){
        self.windowLevel = UIWindowLevelAlert-1;
        [self setHidden:YES];
        self.alpha = 0;
        self.rootViewController = controller = [[PullOverViewController alloc] init];
        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor clearColor];
        [self attachSceneIfNeeded];
    }
    return self;
}

// A window needs a scene to show up: use SpringBoard's main display scene. If SpringBoard has not connected
// it yet when the tweak starts, the window stays invisible, so this is called again each time visibility is
// worked out (unlock, scene activation) until it has one.
- (void)attachSceneIfNeeded {
    if (self.windowScene && [[UIApplication sharedApplication].connectedScenes containsObject:self.windowScene]) return;
    self.windowScene = nil;
    UIWindowScene *fallback = nil;
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) continue;
        if (((UIWindowScene *)scene).screen == [UIScreen mainScreen]) { fallback = (UIWindowScene *)scene; break; }
        if (!fallback) fallback = (UIWindowScene *)scene;
    }
    if (fallback) {
        self.windowScene = fallback;

    }
}

- (void)applySettings{
    NSDictionary *settings = [POApplicationHelper settings];
    [controller invalidate];
    // A fresh controller picks up dark mode, scale, labels, left-handed etc.
    self.rootViewController = controller = [[PullOverViewController alloc] init];
    self.transform = [settings[@"leftHanded"] boolValue] ? CGAffineTransformMakeScale(-1.0, 1.0) : CGAffineTransformIdentity;

}
- (bool)_shouldCreateContextAsSecure{
    return YES;
}



- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    if (self.hidden || self.alpha <= 0.01 || !controller) return nil;
    UIView *hitTestResult = [super hitTest:point withEvent:event];

    if ([controller isOpened]) {
        BOOL landscape = controller.view.bounds.size.width > controller.view.bounds.size.height;
        if (landscape && [[POApplicationHelper settings][@"landscapeTouchThrough"] boolValue]) {
            BOOL inPanel = hitTestResult == controller.contentView || [hitTestResult isDescendantOfView:controller.contentView];
            BOOL inHandle = hitTestResult == controller.handle || [hitTestResult isDescendantOfView:controller.handle];
            if (!inPanel && !inHandle) return nil;
        }
        return hitTestResult;
    }else{
        if (hitTestResult == controller.handle || [hitTestResult isDescendantOfView:controller.handle]) {
            return controller.handle;
        }
        return nil;
    }
}


@end
