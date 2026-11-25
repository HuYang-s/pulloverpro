#import "POKeyboardComposer.h"

@interface POKeyboardComposerController : UIViewController <UITextViewDelegate>
@property(nonatomic,strong) UITextView *editor;
@property(nonatomic,strong) UIView *panel;
@property(nonatomic,strong) UIButton *transferButton;
@property(nonatomic,copy) void (^finish)(BOOL copy);
@end

@interface POKeyboardComposerWindow : UIWindow
@property(nonatomic,weak) UIView *interactivePanel;
@end
@implementation POKeyboardComposerWindow
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *panel=self.interactivePanel;
    if (!panel || !CGRectContainsPoint(panel.bounds,[panel convertPoint:point fromView:self])) return nil;
    return [super hitTest:point withEvent:event];
}
@end

@implementation POKeyboardComposerController
- (UIButton *)button:(NSString *)title action:(SEL)action {
    UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:title forState:UIControlStateNormal];
    b.titleLabel.font=[UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    [b addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [b.heightAnchor constraintGreaterThanOrEqualToConstant:44].active=YES;
    return b;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=UIColor.clearColor;
    self.view.accessibilityViewIsModal=YES;
    UIView *panel=[UIView new];panel.translatesAutoresizingMaskIntoConstraints=NO;
    panel.backgroundColor=UIColor.systemBackgroundColor;panel.layer.cornerRadius=14;
    [self.view addSubview:panel];self.panel=panel;
    UIButton *cancel=[self button:@"取消" action:@selector(cancel)];
    UIButton *copy=[self button:@"复制并返回" action:@selector(copyText)];
    copy.accessibilityLabel=@"复制文字并返回浮窗";
    copy.enabled=NO;self.transferButton=copy;
    UILabel *title=[UILabel new];title.text=@"大键盘输入";
    title.textAlignment=NSTextAlignmentCenter;title.font=[UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    title.adjustsFontSizeToFitWidth=YES;title.minimumScaleFactor=0.7;
    UIStackView *toolbar=[[UIStackView alloc] initWithArrangedSubviews:@[cancel,title,copy]];
    toolbar.axis=UILayoutConstraintAxisHorizontal;toolbar.alignment=UIStackViewAlignmentCenter;toolbar.spacing=12;
    [title setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    UITextView *editor=[UITextView new];editor.font=[UIFont systemFontOfSize:19];editor.textColor=UIColor.labelColor;
    editor.backgroundColor=UIColor.secondarySystemBackgroundColor;editor.layer.cornerRadius=9;
    editor.textContainerInset=UIEdgeInsetsMake(7,10,7,10);editor.delegate=self;
    editor.accessibilityLabel=@"大键盘编辑框";editor.keyboardType=UIKeyboardTypeDefault;
    editor.returnKeyType=UIReturnKeyDefault;editor.autocorrectionType=UITextAutocorrectionTypeDefault;
    editor.spellCheckingType=UITextSpellCheckingTypeDefault;editor.smartInsertDeleteType=UITextSmartInsertDeleteTypeDefault;
    self.editor=editor;
    UILabel *hint=[UILabel new];hint.text=@"文字仅在点复制后进入本机剪贴板，返回浮窗粘贴，不会自动发送。";
    hint.font=[UIFont systemFontOfSize:11];hint.textColor=UIColor.secondaryLabelColor;hint.numberOfLines=2;
    UIStackView *stack=[[UIStackView alloc] initWithArrangedSubviews:@[toolbar,editor,hint]];
    stack.translatesAutoresizingMaskIntoConstraints=NO;stack.axis=UILayoutConstraintAxisVertical;stack.spacing=3;
    [panel addSubview:stack];
    UILayoutGuide *safe=self.view.safeAreaLayoutGuide;
    UIKeyboardLayoutGuide *keyboard=self.view.keyboardLayoutGuide;keyboard.followsUndockedKeyboard=NO;
    NSLayoutConstraint *bottom=[panel.bottomAnchor constraintLessThanOrEqualToAnchor:keyboard.topAnchor constant:-2];
    bottom.priority=UILayoutPriorityDefaultHigh;
    NSLayoutConstraint *preferred=[editor.heightAnchor constraintEqualToConstant:60];preferred.priority=UILayoutPriorityDefaultHigh-1;
    [NSLayoutConstraint activateConstraints:@[
        [panel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:6],
        [panel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-6],
        [panel.topAnchor constraintEqualToAnchor:safe.topAnchor constant:2],
        bottom,
        [stack.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:10],
        [stack.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-10],
        [stack.topAnchor constraintEqualToAnchor:panel.topAnchor constant:3],
        [stack.bottomAnchor constraintEqualToAnchor:panel.bottomAnchor constant:-4],
        [editor.heightAnchor constraintGreaterThanOrEqualToConstant:28],
        preferred
    ]];
}
- (void)textViewDidChange:(UITextView *)textView { self.transferButton.enabled=textView.text.length>0; }
- (void)cancel { if(self.finish)self.finish(NO); }
- (void)copyText {
    if (!self.editor.text.length) return;
    // This is an explicit clipboard operation. Do not read or persist prior clipboard data.
    [UIPasteboard.generalPasteboard setItems:@[@{@"public.utf8-plain-text":self.editor.text}]
        options:@{UIPasteboardOptionLocalOnly:@YES,UIPasteboardOptionExpirationDate:[NSDate dateWithTimeIntervalSinceNow:120]}];
    if(self.finish)self.finish(YES);
}
- (BOOL)shouldAutorotate { return YES; }
- (UIInterfaceOrientationMask)supportedInterfaceOrientations { return UIInterfaceOrientationMaskAll; }
@end

@implementation POKeyboardComposer {
    POKeyboardComposerWindow *_window;
    __weak UIWindow *_previousKey;
    POKeyboardComposerController *_controller;
    void (^_completion)(BOOL);
    BOOL _dismissing;
}
- (BOOL)isPresented { return _window!=nil; }
- (BOOL)presentFromWindow:(UIWindow *)host completion:(void (^)(BOOL))completion {
    if (_window) return YES;
    UIWindowScene *scene=host.windowScene;
    if(!scene || host.hidden) return NO;
    for(UIWindow *w in scene.windows) if(w.isKeyWindow){_previousKey=w;break;}
    _completion=[completion copy];
    _controller=[POKeyboardComposerController new];
    __weak typeof(self) weakSelf=self;
    _controller.finish=^(BOOL copied){[weakSelf finish:copied];};
    _window=[[POKeyboardComposerWindow alloc] initWithWindowScene:scene];
    _window.frame=scene.coordinateSpace.bounds;
    _window.windowLevel=UIWindowLevelAlert;
    _window.backgroundColor=UIColor.clearColor;
    _window.rootViewController=_controller;
    [_window makeKeyAndVisible];
    [_controller.view layoutIfNeeded];
    _window.interactivePanel=_controller.panel;
    [_controller.editor becomeFirstResponder];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(0.15*NSEC_PER_SEC)),dispatch_get_main_queue(),^{
        [weakSelf retryFocus];
    });
    return YES;
}
- (void)retryFocus {
    if(_window && !_dismissing && !_controller.editor.isFirstResponder) [_controller.editor becomeFirstResponder];
}
- (void)finish:(BOOL)copied {
    if(!_window || _dismissing)return;
    _dismissing=YES;
    [_controller.editor resignFirstResponder];
    _controller.editor.text=@"";
    _controller.finish=nil;
    _window.hidden=YES;
    if(_previousKey && !_previousKey.hidden) [_previousKey makeKeyWindow];
    _window.rootViewController=nil;
    _window=nil;_controller=nil;_previousKey=nil;
    void (^completion)(BOOL)=[_completion copy];_completion=nil;
    _dismissing=NO;
    if(completion)completion(copied);
}
- (void)dismiss { [self finish:NO]; }
@end
