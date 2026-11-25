#import "POFloatingKeyboard.h"
@implementation POFloatingKeyboard {
    UILabel *_status;
    UIStackView *_stack;
    BOOL _shift,_numbers,_placed;
    CGRect _available;
    POKeyStatus _keyStatus;
    NSMutableArray<UIButton *> *_keys;
}
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self=[super initWithFrame:frame])) {
        self.backgroundColor=UIColor.secondarySystemBackgroundColor;
        self.layer.cornerRadius=13;self.layer.borderWidth=1;self.layer.borderColor=UIColor.separatorColor.CGColor;
        self.layer.shadowColor=UIColor.blackColor.CGColor;self.layer.shadowOpacity=.25;self.layer.shadowRadius=7;
        self.accessibilityIdentifier=@"PullOverFloatingKeyboard";
        _stack=[UIStackView new];_stack.axis=UILayoutConstraintAxisVertical;_stack.spacing=4;
        _stack.translatesAutoresizingMaskIntoConstraints=NO;[self addSubview:_stack];
        [NSLayoutConstraint activateConstraints:@[[_stack.topAnchor constraintEqualToAnchor:self.topAnchor constant:5],
          [_stack.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-5],
          [_stack.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:5],
          [_stack.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-5]]];
        [self rebuild];
    }
    return self;
}
- (UIButton *)button:(NSString *)title tag:(NSInteger)tag {
    UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];b.tag=tag;
    [b setTitle:title forState:UIControlStateNormal];
    b.titleLabel.font=[UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
    b.titleLabel.adjustsFontSizeToFitWidth=YES;b.titleLabel.minimumScaleFactor=.55;
    b.backgroundColor=UIColor.systemBackgroundColor;b.layer.cornerRadius=5;
    [b setTitleColor:UIColor.labelColor forState:UIControlStateNormal];
    [b addTarget:self action:@selector(pressed:) forControlEvents:UIControlEventTouchUpInside];
    return b;
}
- (void)rebuild {
    for(UIView *v in _stack.arrangedSubviews){[_stack removeArrangedSubview:v];[v removeFromSuperview];}
    _keys=[NSMutableArray new];
    _status=[UILabel new];_status.text=@"连接中…";_status.font=[UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    _status.textAlignment=NSTextAlignmentCenter;_status.userInteractionEnabled=YES;
    _status.adjustsFontSizeToFitWidth=YES;_status.minimumScaleFactor=.6;
    [_status addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(move:)]];
    UIButton *native=[self button:@"系统输入" tag:-4],*close=[self button:@"×" tag:-3];
    close.accessibilityLabel=@"关闭浮动键盘";
    UIStackView *header=[[UIStackView alloc] initWithArrangedSubviews:@[_status,native,close]];header.spacing=5;
    [native.widthAnchor constraintEqualToConstant:70].active=YES;[close.widthAnchor constraintEqualToConstant:38].active=YES;
    [header.heightAnchor constraintEqualToConstant:32].active=YES;[_stack addArrangedSubview:header];
    NSArray *rows=_numbers?@[@"1234567890",@"@#$%&-+()",@"!?.,:;/'"]: @[@"qwertyuiop",@"asdfghjkl",@"zxcvbnm"];
    for(NSString *row in rows){
        UIStackView *r=[UIStackView new];r.distribution=UIStackViewDistributionFillEqually;r.spacing=4;
        for(NSUInteger i=0;i<row.length;i++){unichar c=[row characterAtIndex:i];NSString *v=[NSString stringWithCharacters:&c length:1];if(_shift&&!_numbers)v=v.uppercaseString;
            UIButton *b=[self button:v tag:[v characterAtIndex:0]];[r addArrangedSubview:b];[_keys addObject:b];}
        [_stack addArrangedSubview:r];[r.heightAnchor constraintGreaterThanOrEqualToConstant:28].active=YES;
    }
    UIStackView *bottom=[[UIStackView alloc] initWithArrangedSubviews:@[[self button:_numbers?@"ABC":@"123" tag:-2],[self button:@"⇧" tag:-1],[self button:@"空格" tag:32],[self button:@"⌫" tag:127]]];
    bottom.spacing=4;bottom.distribution=UIStackViewDistributionFillProportionally;
    [_stack addArrangedSubview:bottom];[bottom.heightAnchor constraintGreaterThanOrEqualToConstant:30].active=YES;
    [self reportStatus:_keyStatus];
}
- (void)pressed:(UIButton *)b {
    if(b.tag==-3){if(self.dismissHandler)self.dismissHandler();return;}
    if(b.tag==-4){if(self.nativeHandler)self.nativeHandler();return;}
    if(b.tag==-2){_numbers=!_numbers;[self rebuild];return;}
    if(b.tag==-1){_shift=!_shift;[self rebuild];return;}
    if(self.keyHandler)self.keyHandler(b.tag);
}
- (void)reportStatus:(POKeyStatus)status {
    _keyStatus=status;
    switch(status){
      case POKeyConnecting:_status.text=@"正在连接应用…";break;
      case POKeyReady:_status.text=@"已连接 · 拖动键盘";break;
      case POKeyNoFocus:_status.text=@"已连接 · 请点输入框";break;
      case POKeySecure:_status.text=@"安全输入框不支持";break;
      case POKeyUnsupported:_status.text=@"此输入框不支持 · 系统输入";break;
      case POKeyAccepted:_status.text=@"已输入 · 拖动键盘";break;
      case POKeyTimeout:_status.text=@"连接超时 · 自动重试";break;
      case POKeyBusy:_status.text=@"输入处理中";break;
    }
}
- (void)placeInBounds:(CGRect)bounds safeInsets:(UIEdgeInsets)insets {
    _available=UIEdgeInsetsInsetRect(bounds,insets);
    CGFloat w=MIN(470,MAX(1,_available.size.width-12)),h=MIN(208,MAX(1,_available.size.height-12));
    CGPoint c=_placed?self.center:CGPointMake(CGRectGetMidX(_available),CGRectGetMaxY(_available)-h/2-6);
    self.bounds=CGRectMake(0,0,w,h);_placed=YES;
    self.center=CGPointMake(MAX(CGRectGetMinX(_available)+w/2,MIN(CGRectGetMaxX(_available)-w/2,c.x)),MAX(CGRectGetMinY(_available)+h/2,MIN(CGRectGetMaxY(_available)-h/2,c.y)));
}
- (void)move:(UIPanGestureRecognizer *)pan {
    CGPoint delta=[pan translationInView:self.superview];self.center=CGPointMake(self.center.x+delta.x,self.center.y+delta.y);
    [pan setTranslation:CGPointZero inView:self.superview];
    CGFloat w=self.bounds.size.width,h=self.bounds.size.height;
    self.center=CGPointMake(MAX(CGRectGetMinX(_available)+w/2,MIN(CGRectGetMaxX(_available)-w/2,self.center.x)),MAX(CGRectGetMinY(_available)+h/2,MIN(CGRectGetMaxY(_available)-h/2,self.center.y)));
}
@end
