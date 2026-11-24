//
//  MHHandle.m
//  MessageHub
//
//  Created by Will Smillie on 1/18/19.
//

#import "POHandle.h"
#import <QuartzCore/QuartzCore.h>
#import "PullOverViewController.h"

#import "POApplicationHelper.h"

@interface POHandle (){
    UILabel *messageLabel;
    UIVisualEffectView *blurView;
}

@end

@implementation POHandle

-(instancetype)initWithController:(id)hubController{
    if (self = [super initWithFrame:CGRectMake(0, 0, 80, 34)]) {
        self.isAccessibilityElement = YES;
        self.accessibilityLabel = @"PullOver Pro 浮窗手柄";
        self.accessibilityHint = @"轻点打开或关闭浮窗，长按快速切换应用";
        self.accessibilityTraits = UIAccessibilityTraitButton;
        self.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
        self.layer.cornerRadius = self.frame.size.height/2;
        [self.layer setShadowColor:[UIColor blackColor].CGColor];
        [self.layer setShadowOpacity:0.4];
        [self.layer setShadowRadius:4.0];
        [self.layer setShadowOffset:CGSizeMake(0, 0)];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        [self addGestureRecognizer:tap];

        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        longPress.minimumPressDuration = .3f;
        [self addGestureRecognizer:longPress];
        
        
        self.darkMode = [[POApplicationHelper settings][@"darkHandle"] boolValue];
        
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:self.darkMode?UIBlurEffectStyleDark:UIBlurEffectStyleRegular];
        blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
        blurView.frame = self.bounds;
        blurView.userInteractionEnabled = NO;
        blurView.layer.cornerRadius = self.frame.size.height/2;
        blurView.clipsToBounds = YES;
        [self addSubview:blurView];
        

        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(14, 5, 24, 24)];
        [self.imageView setBackgroundColor:[UIColor clearColor]];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.clipsToBounds = YES;
        self.imageView.tintColor = [UIColor lightGrayColor];
        [self addSubview:self.imageView];
        
        [self setIsNubbed:[[POApplicationHelper state] boolForKey:@"isNubbed"]];
    }
    return self;
}

-(void)setIsNubbed:(BOOL)isNubbed{
    if (_isNubbed == isNubbed) return;
    _isNubbed = isNubbed;
    
    [[POApplicationHelper state] setBool:isNubbed forKey:@"isNubbed"];
    
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{
        if (isNubbed) {
            CGRect r = self.frame; r.origin.x = 20; self.frame = r;
            blurView.layer.cornerRadius = 12;
            CGRect f = self.imageView.frame; f.origin.x = 3; self.imageView.frame = f;
        }else{
            CGRect r = self.frame; r.origin.x = 0; self.frame = r;
            blurView.layer.cornerRadius = self.frame.size.height/2;
            CGRect f = self.imageView.frame; f.origin.x = 14; self.imageView.frame = f;
        }
    } completion:nil];
}

// The compact handle occupies 30 pt on screen. Extend its hit area inward
// by 14 pt and vertically by 9 pt, yielding a 44 × 52 pt target.
-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event{
    if (self.hidden || self.alpha <= 0.01 || !self.userInteractionEnabled) return NO;
    if (!self.isNubbed) return [super pointInside:point withEvent:event];
    CGRect hitBounds = CGRectInset(self.bounds, -14, -9);
    return CGRectContainsPoint(hitBounds, point);
}

-(void)layoutSubviews{
    [super layoutSubviews];
    blurView.frame = self.bounds;
}


-(void)tap:(UIGestureRecognizer *)recognizer{
    [self.delegate handle:self didReceiveTap:recognizer];
}

-(void)longPress:(UIGestureRecognizer *)recognizer{
    [self.delegate handle:self didLongPress:recognizer];
}


@end
