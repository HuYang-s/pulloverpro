#import "POKeyboardBridge.h"
#import "../Shared/POGestureChannel.h"
#import <notify.h>
#import <QuartzCore/QuartzCore.h>
@implementation POKeyboardBridge {
    int _leaseToken,_commandToken,_replyToken;
    NSString *_leaseName,*_commandName;
    uint32_t _session;
    uint16_t _serial,_pending;
    CFTimeInterval _sentAt,_lastReply;
    dispatch_source_t _timer;
    void (^_status)(POKeyStatus);
    POKeyStatus _current;
}
- (instancetype)init {
    if ((self=[super init])) _leaseToken=_commandToken=_replyToken=NOTIFY_TOKEN_INVALID;
    return self;
}
- (void)report:(POKeyStatus)value {
    if (_current==value) return;
    _current=value;
    if(_status)_status(value);
}
- (BOOL)startForBundle:(NSString *)bundle status:(void (^)(POKeyStatus))status {
    [self stop];
    _status=[status copy];
    _current=POKeyTimeout;[self report:POKeyConnecting];
    if(!POGestureBundleSupported(bundle)){[self report:POKeyUnsupported];return NO;}
    _leaseName=POGestureChannel(bundle,@"keyboard.v3.lease");
    _commandName=POGestureChannel(bundle,@"keyboard.v3.command");
    __weak typeof(self) weakSelf=self;
    if(notify_register_check(_leaseName.UTF8String,&_leaseToken)!=NOTIFY_STATUS_OK ||
       notify_register_check(_commandName.UTF8String,&_commandToken)!=NOTIFY_STATUS_OK ||
       notify_register_dispatch(POGestureChannel(bundle,@"keyboard.v3.reply").UTF8String,&_replyToken,dispatch_get_main_queue(),^(int token){[weakSelf receive:token];})!=NOTIFY_STATUS_OK) {
        void (^f)(POKeyStatus)=[_status copy];[self stop];if(f)f(POKeyTimeout);return NO;
    }
    _session=arc4random();if(!_session)_session=1;
    _lastReply=CACurrentMediaTime();
    if(notify_set_state(_leaseToken,POKeyPacket(_session,0,1))!=NOTIFY_STATUS_OK){
        void (^f)(POKeyStatus)=[_status copy];[self stop];if(f)f(POKeyTimeout);return NO;
    }
    _timer=dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0,0,dispatch_get_main_queue());
    dispatch_source_set_timer(_timer,dispatch_time(DISPATCH_TIME_NOW,0),NSEC_PER_SEC/2,NSEC_PER_SEC/10);
    dispatch_source_set_event_handler(_timer,^{[weakSelf tick];});
    dispatch_resume(_timer);
    return YES;
}
- (void)tick {
    if(!_session)return;
    notify_post(_leaseName.UTF8String);
    CFTimeInterval now=CACurrentMediaTime();
    if(_pending && now-_sentAt>1.25){_pending=0;[self report:POKeyTimeout];}
    else if(!_pending && now-_lastReply>2.5)[self report:POKeyTimeout];
}
- (void)receive:(int)token {
    uint64_t raw=0;
    if(token!=_replyToken || !_session || notify_get_state(token,&raw)!=NOTIFY_STATUS_OK || POKeySession(raw)!=_session)return;
    uint16_t serial=POKeySerial(raw),value=POKeyValue(raw);
    if(value>POKeyAccepted || value==POKeyConnecting)return;
    if(serial) {
        if(!POKeyMatches(raw,_session,_pending)||!_pending)return;
        _pending=0;
    } else if(_pending) return;
    _lastReply=CACurrentMediaTime();
    [self report:(POKeyStatus)value];
}
- (BOOL)sendKey:(NSInteger)key {
    if(!_session||!POKeyPermitted((uint16_t)key)||key<32||key>127)return NO;
    if(_pending){[self report:POKeyBusy];return NO;}
    if(_current!=POKeyReady&&_current!=POKeyAccepted)return NO;
    if(++_serial==0)++_serial;
    _pending=_serial;_sentAt=CACurrentMediaTime();
    if(notify_set_state(_commandToken,POKeyPacket(_session,_pending,(uint16_t)key))!=NOTIFY_STATUS_OK||
       notify_post(_commandName.UTF8String)!=NOTIFY_STATUS_OK){_pending=0;[self report:POKeyTimeout];return NO;}
    return YES;
}
- (void)stop {
    if(_timer){dispatch_source_cancel(_timer);_timer=nil;}
    _session=0;_serial=0;_pending=0;
    if(notify_is_valid_token(_leaseToken)){notify_set_state(_leaseToken,0);if(_leaseName)notify_post(_leaseName.UTF8String);notify_cancel(_leaseToken);}
    if(notify_is_valid_token(_commandToken)){notify_set_state(_commandToken,0);notify_cancel(_commandToken);}
    if(notify_is_valid_token(_replyToken))notify_cancel(_replyToken);
    _leaseToken=_commandToken=_replyToken=NOTIFY_TOKEN_INVALID;_status=nil;_leaseName=nil;_commandName=nil;
}
- (void)dealloc{[self stop];}
@end
