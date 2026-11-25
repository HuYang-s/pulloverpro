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
        self.multipleTouchEnabled = YES;
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
    UIView *keyboard=controller.floatingKeyboard;
    if (keyboard && !keyboard.hidden && (hitTestResult==keyboard || [hitTestResult isDescendantOfView:keyboard])) return hitTestResult;

    if ([controller isOpened]) {
        BOOL landscape = controller.view.bounds.size.width > controller.view.bounds.size.height;
        if (landscape && [[POApplicationHelper settings][@"landscapeTouchThrough"] boolValue]) {
            // The transformed hosted view can leave unused space inside the drawer.
            // Let those points reach the app underneath, just like the area outside the panel.
            if (hitTestResult == controller.contentView) return nil;
            BOOL inPanel = hitTestResult == controller.contentView || [hitTestResult isDescendantOfView:controller.contentView];
            UIView *bar = controller.gestureBar;
            if (bar && !bar.hidden && !controller.expandedSwitchMenu.isPresented &&
                (hitTestResult == bar || [hitTestResult isDescendantOfView:bar])) return hitTestResult;
            UIView *surface = controller.transformSurface;
            if (surface && !surface.hidden && (hitTestResult == surface || [hitTestResult isDescendantOfView:surface])) return hitTestResult;
            BOOL inHandle = hitTestResult == controller.handle || [hitTestResult isDescendantOfView:controller.handle];
            BOOL inControls = hitTestResult == controller.drawerControls || [hitTestResult isDescendantOfView:controller.drawerControls];
            BOOL inMenu = controller.expandedSwitchMenu.isPresented && (hitTestResult == controller.expandedSwitchMenu || [hitTestResult isDescendantOfView:controller.expandedSwitchMenu]);
            if (!inPanel && !inHandle && !inControls && !inMenu) return nil;
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
