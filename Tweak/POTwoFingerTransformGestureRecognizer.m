#import "POTwoFingerTransformGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>
#import <math.h>

@implementation POTwoFingerTransformGestureRecognizer {
    NSMutableSet<UITouch *> *_tracked;
    CGPoint _singleOrigin;
    CGFloat _initialDistance;
    CGFloat _scaleFactor;
    CGPoint _translation;
    CGPoint _initialCenter;
    BOOL _hasGeometry;
}
- (BOOL)active {
    return self.state == UIGestureRecognizerStateBegan || self.state == UIGestureRecognizerStateChanged;
}
- (void)capture {
    NSArray<UITouch *> *pair = _tracked.allObjects;
    CGPoint a = [pair[0] locationInView:(self.coordinateView ?: self.view)], b = [pair[1] locationInView:(self.coordinateView ?: self.view)];
    _initialCenter = CGPointMake((a.x+b.x)/2, (a.y+b.y)/2);
    _initialDistance = hypot(b.x-a.x,b.y-a.y);
    if (_initialDistance < 12) return;
    _scaleFactor = 1;
    _translation = CGPointZero;
    _hasGeometry = YES;
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!_tracked) _tracked = [NSMutableSet set];
    [_tracked unionSet:touches];
    if (_tracked.count > 2) {
        self.state = [self active] ? UIGestureRecognizerStateCancelled : UIGestureRecognizerStateFailed;
    } else if (_tracked.count == 1) {
        _singleOrigin = [_tracked.anyObject locationInView:(self.coordinateView ?: self.view)];
    } else if (self.state == UIGestureRecognizerStatePossible && !_hasGeometry) {
        [self capture];
    }
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (_tracked.count == 1 && self.state == UIGestureRecognizerStatePossible) {
        CGPoint p = [_tracked.anyObject locationInView:(self.coordinateView ?: self.view)];
        if (hypot(p.x-_singleOrigin.x,p.y-_singleOrigin.y) >= 12) self.state = UIGestureRecognizerStateFailed;
        return;
    }
    if (_tracked.count != 2) return;
    if (!_hasGeometry && self.state == UIGestureRecognizerStatePossible) { [self capture]; return; }
    if (!_hasGeometry) return;
    NSArray<UITouch *> *pair = _tracked.allObjects;
    CGPoint a = [pair[0] locationInView:(self.coordinateView ?: self.view)], b = [pair[1] locationInView:(self.coordinateView ?: self.view)];
    CGPoint center = CGPointMake((a.x+b.x)/2,(a.y+b.y)/2);
    CGFloat distance = hypot(b.x-a.x,b.y-a.y);
    _scaleFactor = MAX(0.01, distance / _initialDistance);
    _translation = CGPointMake(center.x-_initialCenter.x,center.y-_initialCenter.y);
    if (self.state == UIGestureRecognizerStatePossible) {
        if (fabs(distance-_initialDistance) < 7 && hypot(_translation.x,_translation.y) < 7) return;
        self.state = UIGestureRecognizerStateBegan;
    } else if ([self active]) {
        self.state = UIGestureRecognizerStateChanged;
    }
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [_tracked minusSet:touches];
    self.state = [self active] ? UIGestureRecognizerStateEnded : UIGestureRecognizerStateFailed;
}
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [_tracked minusSet:touches];
    self.state = [self active] ? UIGestureRecognizerStateCancelled : UIGestureRecognizerStateFailed;
}
- (void)reset {
    [super reset];
    [_tracked removeAllObjects];
    _hasGeometry = NO;
    _initialDistance = 0;
    _scaleFactor = 1;
    _translation = CGPointZero;
    _initialCenter = CGPointZero;
}
@end
