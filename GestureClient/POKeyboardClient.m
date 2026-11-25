#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <notify.h>
#import "../Shared/POGestureChannel.h"
#import "../Shared/POKeyboardWire.h"

// Resolve only the first responder in this app. No text or key capture.
static __weak UIResponder *POKeyboardTargetV3;
@interface UIResponder (POKeyboardTargetV3)
- (void)poFindKeyboardTargetV3:(id)sender;
@end
@implementation UIResponder (POKeyboardTargetV3)
- (void)poFindKeyboardTargetV3:(id)sender{POKeyboardTargetV3=self;}
@end
static UIResponder *POFindFocusedView(UIView *v,NSUInteger depth){
    if(!v||depth>96||v.hidden||v.alpha<.01)return nil;
    if(v.isFirstResponder)return v;
    for(UIView *sub in v.subviews){UIResponder *r=POFindFocusedView(sub,depth+1);if(r)return r;}
    return nil;
}
@interface POKeyboardClient : NSObject
- (void)start;
@end
@implementation POKeyboardClient {
    int _leaseToken,_commandToken,_replyToken;
    NSString *_replyName;
    uint32_t _session;
    uint16_t _lastSerial;
    CFTimeInterval _lastHeartbeat;
    dispatch_source_t _watchdog;
}
- (void)start {
    NSString *bundle=NSBundle.mainBundle.bundleIdentifier;
    if(!POGestureBundleSupported(bundle))return;
    _leaseToken=_commandToken=_replyToken=NOTIFY_TOKEN_INVALID;
    _replyName=POGestureChannel(bundle,@"keyboard.v3.reply");
    __weak typeof(self) weakSelf=self;
    if(notify_register_check(_replyName.UTF8String,&_replyToken)!=NOTIFY_STATUS_OK)return;
    if(notify_register_dispatch(POGestureChannel(bundle,@"keyboard.v3.lease").UTF8String,&_leaseToken,dispatch_get_main_queue(),^(int t){[weakSelf heartbeat:t];})!=NOTIFY_STATUS_OK)return;
    notify_register_dispatch(POGestureChannel(bundle,@"keyboard.v3.command").UTF8String,&_commandToken,dispatch_get_main_queue(),^(int t){[weakSelf command:t];});
}
- (BOOL)valid {
    uint64_t raw=0;
    return _session && CACurrentMediaTime()-_lastHeartbeat<2.0 &&
      notify_get_state(_leaseToken,&raw)==NOTIFY_STATUS_OK && POKeySession(raw)==_session && POKeyValue(raw)==1;
}
- (UIResponder *)target {
    // Hosted app windows may not be key according to UIApplication; search
    // normal scene windows first, then the public responder-chain action.
    for(UIScene *scene in UIApplication.sharedApplication.connectedScenes){
        if(![scene isKindOfClass:UIWindowScene.class])continue;
        for(UIWindow *w in ((UIWindowScene *)scene).windows){
            if(w.hidden||fabs(w.windowLevel-UIWindowLevelNormal)>.1)continue;
            UIResponder *r=POFindFocusedView(w,0);if(r)return r;
        }
    }
    POKeyboardTargetV3=nil;
    [UIApplication.sharedApplication sendAction:@selector(poFindKeyboardTargetV3:) to:nil from:self forEvent:nil];
    UIResponder *r=POKeyboardTargetV3;POKeyboardTargetV3=nil;return r;
}
- (POKeyStatus)statusForTarget:(UIResponder *)r {
    if(!r||!r.isFirstResponder)return POKeyNoFocus;
    if(![r isKindOfClass:UIView.class]||![(UIView *)r window]||((UIView *)r).window.hidden||
       fabs(((UIView *)r).window.windowLevel-UIWindowLevelNormal)>.1)return POKeyUnsupported;
    if(![r respondsToSelector:@selector(isSecureTextEntry)])return POKeyUnsupported;
    id<UITextInputTraits> traits=(id)r;
    if(traits.secureTextEntry)return POKeySecure;
    // A custom editor need not explicitly declare UIKeyInput conformance.
    // Check the actual selectors, and keep secure-field protection.
    if(![r respondsToSelector:@selector(insertText:)]||![r respondsToSelector:@selector(deleteBackward)])return POKeyUnsupported;
    if([r isKindOfClass:UITextField.class]&&!((UITextField *)r).enabled)return POKeyUnsupported;
    if([r isKindOfClass:UITextView.class]&&!((UITextView *)r).editable)return POKeyUnsupported;
    return POKeyReady;
}
- (void)reply:(uint16_t)serial status:(POKeyStatus)status {
    if(!_session||!notify_is_valid_token(_replyToken))return;
    if(notify_set_state(_replyToken,POKeyPacket(_session,serial,status))==NOTIFY_STATUS_OK)notify_post(_replyName.UTF8String);
}
- (void)disable {
    _session=0;_lastSerial=0;
    if(_watchdog){dispatch_source_cancel(_watchdog);_watchdog=nil;}
}
- (void)heartbeat:(int)token {
    uint64_t raw=0;
    if(token!=_leaseToken||notify_get_state(token,&raw)!=NOTIFY_STATUS_OK||!POKeySession(raw)||POKeyValue(raw)!=1){[self disable];return;}
    if(_session!=POKeySession(raw)){[self disable];_session=POKeySession(raw);}
    _lastHeartbeat=CACurrentMediaTime();
    [self reply:0 status:[self statusForTarget:[self target]]];
    if(!_watchdog){
        __weak typeof(self) weakSelf=self;
        _watchdog=dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0,0,dispatch_get_main_queue());
        dispatch_source_set_timer(_watchdog,dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC),NSEC_PER_SEC,NSEC_PER_SEC/5);
        dispatch_source_set_event_handler(_watchdog,^{[weakSelf checkLease];});dispatch_resume(_watchdog);
    }
}
- (void)checkLease{if(![self valid])[self disable];}
- (void)command:(int)token {
    uint64_t raw=0;
    if(token!=_commandToken||![self valid]||notify_get_state(token,&raw)!=NOTIFY_STATUS_OK||POKeySession(raw)!=_session)return;
    uint16_t serial=POKeySerial(raw),key=POKeyValue(raw);
    if(!serial||serial==_lastSerial||!POKeyPermitted(key))return;
    _lastSerial=serial;
    UIResponder *r=[self target];
    POKeyStatus state=[self statusForTarget:r];
    if(state==POKeyReady){
        id<UIKeyInput> input=(id)r;
        if(key==127)[input deleteBackward];
        else{unichar c=key;[input insertText:[NSString stringWithCharacters:&c length:1]];}
        state=POKeyAccepted;
    }
    [self reply:serial status:state];
}
@end
static POKeyboardClient *keyboardClientV3;
__attribute__((constructor)) static void POStartKeyboardClientV3(void){
    if(!POGestureBundleSupported(NSBundle.mainBundle.bundleIdentifier))return;
    dispatch_async(dispatch_get_main_queue(),^{keyboardClientV3=[POKeyboardClient new];[keyboardClientV3 start];});
}
