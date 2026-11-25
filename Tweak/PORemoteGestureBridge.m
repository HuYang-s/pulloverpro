#import "PORemoteGestureBridge.h"
#import "../Shared/POGestureChannel.h"
#import <notify.h>

@implementation PORemoteGestureBridge {
    int _stateToken, _eventToken;
    uint16_t _session;
    NSString *_stateName;
    uint64_t _lastGeometry, _lastEvent;
    dispatch_source_t _heartbeat;
    void (^_handler)(PORemoteTransform);
}
- (instancetype)init {
    if ((self=[super init])) _stateToken=_eventToken=NOTIFY_TOKEN_INVALID;
    return self;
}
- (BOOL)startForBundle:(NSString *)bundle handler:(void (^)(PORemoteTransform))handler {
    if ([_bundle isEqualToString:bundle] && _session) return YES;
    [self stop];
    if (!POGestureBundleSupported(bundle)) return NO;
    NSString *stateName=POGestureChannel(bundle,@"state"), *eventName=POGestureChannel(bundle,@"event");
    if (notify_register_check(stateName.UTF8String,&_stateToken)!=NOTIFY_STATUS_OK) return NO;
    __weak typeof(self) weakSelf=self;
    if (notify_register_dispatch(eventName.UTF8String,&_eventToken,dispatch_get_main_queue(),^(int token){
        [weakSelf receive:token];
    })!=NOTIFY_STATUS_OK) {
        [self stop];
        return NO;
    }
    _bundle=[bundle copy]; _stateName=[stateName copy]; _handler=[handler copy];
    _session=(uint16_t)(arc4random_uniform(65535)+1);
    _heartbeat=dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0,0,dispatch_get_main_queue());
    dispatch_source_set_timer(_heartbeat,dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC),NSEC_PER_SEC,NSEC_PER_SEC/5);
    dispatch_source_set_event_handler(_heartbeat,^{ [weakSelf heartbeat]; });
    dispatch_resume(_heartbeat);
    return YES;
}
- (void)receive:(int)token {
    uint64_t raw=0;
    if (!_session || token!=_eventToken || notify_get_state(token,&raw)!=NOTIFY_STATUS_OK) return;
    PORemoteTransform e=POUnpackRemote(raw);
    if (e.session!=_session || raw==_lastEvent) return;
    _lastEvent=raw;
    if (!e.phase) _ready=YES;
    if (_handler) _handler(e);
}
- (void)heartbeat {
    if (_session && _lastGeometry && _stateName) notify_post(_stateName.UTF8String);
}
- (void)publishScale:(double)scale centerX:(double)x centerY:(double)y {
    if (!_session || !notify_is_valid_token(_stateToken)) return;
    uint64_t raw=POPackHost((POHostGeometry){_session,scale,x,y});
    if (!raw || raw==_lastGeometry) return;
    if (notify_set_state(_stateToken,raw)==NOTIFY_STATUS_OK) {
        BOOL first=_lastGeometry==0;
        _lastGeometry=raw;
        if (first) [self heartbeat];
    }
}
- (void)stop {
    _session=0; _ready=NO;
    if (_heartbeat) { dispatch_source_cancel(_heartbeat); _heartbeat=nil; }
    if (notify_is_valid_token(_stateToken)) {
        notify_set_state(_stateToken,0);
        if (_stateName) notify_post(_stateName.UTF8String);
        notify_cancel(_stateToken);
    }
    if (notify_is_valid_token(_eventToken)) notify_cancel(_eventToken);
    _stateToken=_eventToken=NOTIFY_TOKEN_INVALID;
    _lastGeometry=0; _lastEvent=0; _stateName=nil; _bundle=nil; _handler=nil;
}
- (void)dealloc { [self stop]; }
@end
