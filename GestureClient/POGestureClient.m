#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <notify.h>
#import "../Shared/POGestureWire.h"
#import "../Shared/POGestureChannel.h"
#import "../Shared/POGestureStabilizer.h"
#import "../Tweak/POTwoFingerTransformGestureRecognizer.h"

@interface POGestureClient : NSObject <UIGestureRecognizerDelegate>
- (void)start;
@end
@implementation POGestureClient {
    int _stateToken, _eventToken;
    NSString *_eventName;
    uint16_t _session;
    uint8_t _gesture;
    CFTimeInterval _lastHeartbeat;
    BOOL _watchdogScheduled, _failed;
    NSHashTable<POTwoFingerTransformGestureRecognizer *> *_recognizers;
    __weak POTwoFingerTransformGestureRecognizer *_active;
    POHostGeometry _startGeometry;
    PORemoteTransform _lastSample;
    CFTimeInterval _lastSent;
}
- (void)start {
    NSString *bundle=NSBundle.mainBundle.bundleIdentifier;
    if (!POGestureBundleSupported(bundle)) return;
    _stateToken=_eventToken=NOTIFY_TOKEN_INVALID;
    _recognizers=[NSHashTable weakObjectsHashTable];
    _eventName=POGestureChannel(bundle,@"event");
    if (notify_register_check(_eventName.UTF8String,&_eventToken)!=NOTIFY_STATUS_OK) return;
    __weak typeof(self) weakSelf=self;
    if (notify_register_dispatch(POGestureChannel(bundle,@"state").UTF8String,&_stateToken,dispatch_get_main_queue(),^(int token){
        [weakSelf heartbeat:token];
    })!=NOTIFY_STATUS_OK) {
        notify_cancel(_eventToken); _eventToken=NOTIFY_TOKEN_INVALID; return;
    }
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(windowChanged:) name:UIWindowDidBecomeVisibleNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(windowChanged:) name:UIWindowDidBecomeKeyNotification object:nil];
}
- (POHostGeometry)geometry {
    uint64_t raw=0;
    if (!notify_is_valid_token(_stateToken) || notify_get_state(_stateToken,&raw)!=NOTIFY_STATUS_OK) return (POHostGeometry){0};
    return POUnpackHost(raw);
}
- (BOOL)leaseValid {
    return !_failed && _session && CACurrentMediaTime()-_lastHeartbeat<3.0 && [self geometry].session==_session;
}
- (void)disable {
    _session=0; _active=nil; _lastSample=(PORemoteTransform){0}; _lastSent=0;
    for (POTwoFingerTransformGestureRecognizer *g in _recognizers.allObjects) g.enabled=NO;
}
- (void)scheduleWatchdog {
    if (_watchdogScheduled) return;
    _watchdogScheduled=YES;
    __weak typeof(self) weakSelf=self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC),dispatch_get_main_queue(),^{ [weakSelf watchdog]; });
}
- (void)watchdog {
    _watchdogScheduled=NO;
    if ([self leaseValid]) [self scheduleWatchdog]; else [self disable];
}
- (void)heartbeat:(int)token {
    if (token!=_stateToken) return;
    POHostGeometry geo=[self geometry];
    if (!geo.session || fabs(geo.scale)<0.001) { [self disable]; return; }
    BOOL newSession=_session!=geo.session;
    if (newSession) { [self disable]; _session=geo.session; _failed=NO; }
    _lastHeartbeat=CACurrentMediaTime();
    if (_failed) return;
    [self attachWindows];
    if (newSession && ![self send:(PORemoteTransform){_session,0,0,1,0,0}]) return;
    [self scheduleWatchdog];
}
- (BOOL)send:(PORemoteTransform)e {
    if (notify_set_state(_eventToken,POPackRemote(e))!=NOTIFY_STATUS_OK || notify_post(_eventName.UTF8String)!=NOTIFY_STATUS_OK) {
        _failed=YES;
        _active=nil;
        for (POTwoFingerTransformGestureRecognizer *g in _recognizers.allObjects) g.enabled=NO;
        return NO;
    }
    return YES;
}
- (void)windowChanged:(NSNotification *)n {
    if ([self leaseValid]) [self attachWindows];
}
- (void)attachWindows {
    if (![self leaseValid]) return;
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) continue;
        for (UIWindow *window in ((UIWindowScene *)scene).windows) {
            if (window.hidden || window.alpha<0.01 || !window.rootViewController || fabs(window.windowLevel-UIWindowLevelNormal)>0.1) continue;
            POTwoFingerTransformGestureRecognizer *match=nil;
            for (POTwoFingerTransformGestureRecognizer *g in _recognizers.allObjects) if (g.view==window) { match=g; break; }
            if (!match) {
                match=[[POTwoFingerTransformGestureRecognizer alloc] initWithTarget:self action:@selector(transform:)];
                match.coordinateView=window;
                match.delegate=self;
                match.cancelsTouchesInView=YES;
                match.delaysTouchesBegan=NO;
                match.delaysTouchesEnded=NO;
                [window addGestureRecognizer:match];
                [_recognizers addObject:match];
            }
            if (!match.enabled) match.enabled=YES;
        }
    }
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g shouldReceiveTouch:(UITouch *)touch {
    return [self leaseValid] && (!_active || _active==g);
}
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)g {
    return [self leaseValid] && (!_active || _active==g);
}
- (void)transform:(POTwoFingerTransformGestureRecognizer *)g {
    if (![self leaseValid] || !g.view) return;
    UIGestureRecognizerState s=g.state;
    POHostGeometry geo=[self geometry];
    if (s==UIGestureRecognizerStateBegan) {
        if (_active && _active!=g) return;
        _active=g;
        if (++_gesture==0) ++_gesture;
        _startGeometry=geo;
        _lastSample=(PORemoteTransform){_session,_gesture,1,1,0,0};
        _lastSent=0;
    }
    if (_active!=g) return;
    BOOL ended=s==UIGestureRecognizerStateEnded || s==UIGestureRecognizerStateCancelled;
    // Repeat the final input sample, never recompute from changed host geometry.
    if (ended) {
        _active=nil;
        if (_lastSample.session==_session && _lastSample.gesture==_gesture) {
            _lastSample.phase=3;
            [self send:_lastSample];
        }
        return;
    }
    if (s!=UIGestureRecognizerStateBegan && s!=UIGestureRecognizerStateChanged) return;
    // The remote renderer updates asynchronously. Mixing fresh host geometry
    // with an earlier UIKit sample creates a feedback loop. Freeze mapping
    // for the entire gesture; do not read the changing host scale here.
    POStableSample sample=POFrozenGestureSample(g.scaleFactor,g.translation.x,g.translation.y,_startGeometry.scale);
    _lastSample=(PORemoteTransform){_session,_gesture,s==UIGestureRecognizerStateBegan?1:2,
        sample.ratio,sample.dx,sample.dy};
    CFTimeInterval now=CACurrentMediaTime();
    if (s==UIGestureRecognizerStateBegan || now-_lastSent>=1.0/30.0) {
        _lastSent=now;
        [self send:_lastSample];
    }
}
@end

static POGestureClient *client;
__attribute__((constructor)) static void POInitializeGestureClient(void) {
    if (!POGestureBundleSupported(NSBundle.mainBundle.bundleIdentifier)) return;
    dispatch_async(dispatch_get_main_queue(),^{
        client=[POGestureClient new];
        [client start];
    });
}
