//
//  PullOverViewController.m
//  PullOverPro
//
//  Created by Will Smillie on 4/8/19.
//

#import "PullOverViewController.h"
#import "POLog.h"
#import "POTwoFingerTransformGestureRecognizer.h"
#import "POTransformMath.h"
#import "POKeyboardComposer.h"
#import "POFloatingKeyboard.h"
#import "POKeyboardBridge.h"
#import "PORemoteGestureBridge.h"
#import "../Shared/POGestureChannel.h"
#import "../Shared/POGestureStabilizer.h"

#define HANDLE_MARGIN 50
#define HALF_OPEN_HEIGHT 400

@interface PODrawerScrollView : UIScrollView
@property (nonatomic, weak) UIView *hostedContent;
@end

@implementation PODrawerScrollView
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.panGestureRecognizer && self.hostedContent) {
        CGPoint point = [gestureRecognizer locationInView:self.hostedContent];
        if (CGRectContainsPoint(self.hostedContent.bounds, point)) return NO;
    }
    return [super gestureRecognizerShouldBegin:gestureRecognizer];
}
@end

@interface PullOverViewController (){
    NSString *pinnedBundleId;
    UIView *contextView;
    
    UIView *dragAndDropView;
    UIImageView *draggableImageView;
    UILabel *dragAndDropLabel;
    
    UIView *overlayView;
    UIActivityIndicatorView *activityIndicator;

    CGRect handleFrame;
    CGPoint handlePoint;
    CGRect lastLayoutBounds;
    UIEdgeInsets lastSafeAreaInsets;
    NSNumber *originalHandleOffset;
    CGFloat scale;
    BOOL showingCantHost;
    BOOL hostingInProgress;
    BOOL launchRequested;
    BOOL suppressHostingUntilClosed;
    BOOL isInvalidated;
    BOOL presentationAllowed;
    BOOL updatingLayout;
    BOOL inputZoom;
    CGFloat userScale;
    CGFloat contextBaseScale;
    CGFloat gestureStartScale;
    CGPoint userOffset;
    CGPoint contextBaseCenter;
    CGPoint gestureStartOffset;
    CGSize transformViewport;
    NSMutableDictionary<NSString *, NSDictionary *> *appTransforms;
    BOOL transformEnabled;
    BOOL hostInteractionSaved;
    BOOL hostWasInteractive;
    UILabel *transformStatus;
    UIButton *minusButton;
    UIButton *plusButton;
    UIButton *transformButton;
    UIButton *resetButton;
    POTwoFingerTransformGestureRecognizer *transformGestureRecognizer;
    POTwoFingerTransformGestureRecognizer *directGestureRecognizer;
    POTwoFingerTransformGestureRecognizer *barGestureRecognizer;
    __weak UIGestureRecognizer *activeTransformGesture;
    UIPanGestureRecognizer *barPan;
    UILabel *gestureBarLabel;
    BOOL autoDirectGestures;
    PORemoteGestureBridge *remoteBridge;
    uint8_t lastRemoteGesture;
    BOOL remoteGestureActive;
    CGFloat remoteStartScale;
    CGPoint remoteStartOffset;
    CFTimeInterval remoteLastEvent;
    POStableSample remoteFiltered;
    BOOL remoteDeferred;
    BOOL showGestureBar;
    UIButton *zoomButton;
    UIButton *keyboardButton;
    POKeyboardComposer *keyboardComposer;
    POKeyboardBridge *keyboardBridge;
    BOOL toolsVisible;
    UIButton *switchButton;
    CGFloat drawerTravel;
    NSUInteger hostingGeneration;
    NSUInteger pinGeneration;
    NSUInteger hostingAttempts;
}

- (void)updateLayoutForCurrentBounds;
- (void)updateDrawerControls;
- (void)toggleExpandedSwitchMenu;
- (void)toggleInputZoom;
- (void)openLargeKeyboard;
- (void)toggleTools;
- (void)hideFloatingKeyboard;
- (void)openNativeComposer;
- (void)scheduleAutoNub;
- (void)layoutContextView;
- (void)applyContextTransform;
- (void)toggleTransformMode;
- (void)setTransformEditing:(BOOL)enabled;
- (void)updateTransformStatus;
- (void)updateTransformGestureAvailability;
- (void)cancelTransformGestures;
- (BOOL)canTransformHostedScene;
- (void)updateRemoteBridge;
- (void)publishRemoteGeometry;
- (void)stopRemoteBridge;
- (void)handleRemoteTransform:(PORemoteTransform)event;
- (void)zoomInStep;
- (void)zoomOutStep;
- (void)changeZoomBy:(CGFloat)factor;
- (void)handleLocalPan:(UIPanGestureRecognizer *)recognizer;
- (void)resetContextTransform;
- (void)saveAppTransform;
- (void)restoreAppTransform:(NSString *)bundleId;
- (CGPoint)clampedContextOffset:(CGPoint)offset;
- (void)handleTwoFingerTransform:(POTwoFingerTransformGestureRecognizer *)recognizer;
- (void)attemptHostingForGeneration:(NSUInteger)generation;
- (void)showHostingMessage:(NSString *)message symbolName:(NSString *)symbolName generation:(NSUInteger)generation;

@end

@implementation PullOverViewController
@synthesize scrollView, handleScrollView;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    scale = 1.0;
    userScale = 1.0;
    transformEnabled = NO;
    autoDirectGestures = [[POApplicationHelper settings][@"directTwoFinger"] boolValue];
    remoteDeferred = [[POApplicationHelper settings][@"deferredTwoFinger"] boolValue];
    showGestureBar = [[POApplicationHelper settings][@"gestureBar"] boolValue];
    appTransforms = [NSMutableDictionary dictionary];
    remoteBridge = [PORemoteGestureBridge new];
    keyboardComposer = [POKeyboardComposer new];
    keyboardBridge = [POKeyboardBridge new];

    self.backgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    self.backgroundView.alpha = 0;
    [self.view addSubview:self.backgroundView];
    
    
    UIImage *image = [UIImage imageWithContentsOfFile:PO_PATH_NS(@"/Library/Application Support/PullOverPro/rocket.png")];
    
    
    dragAndDropView = [[UIView alloc] initWithFrame:CGRectMake(0,0,100,100)];
    dragAndDropView.contentMode = UIViewContentModeScaleAspectFit;
    dragAndDropView.center = CGPointMake(self.backgroundView.center.x, self.backgroundView.center.y);
    dragAndDropView.alpha = 0;
    [self.backgroundView addSubview:dragAndDropView];
    
    CAShapeLayer *border = [CAShapeLayer layer];
    border.strokeColor = [UIColor whiteColor].CGColor;
    border.fillColor = nil;
    border.lineDashPattern = @[@4, @2];
    [dragAndDropView.layer addSublayer:border];
    
    border.path = [UIBezierPath bezierPathWithRect:dragAndDropView.bounds].CGPath;
    border.frame = dragAndDropView.bounds;


    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    imageView.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    imageView.tintColor = [UIColor whiteColor];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.center = CGPointMake(dragAndDropView.frame.size.width/2, dragAndDropView.frame.size.height/2);
    [dragAndDropView addSubview:imageView];
    
    
    dragAndDropLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,dragAndDropView.frame.size.height+dragAndDropView.frame.origin.y+16,200, 44)];
    dragAndDropLabel.textColor = [UIColor whiteColor];
    dragAndDropLabel.textAlignment = NSTextAlignmentCenter;
    dragAndDropLabel.numberOfLines = 2;
    dragAndDropLabel.text = @"将应用拖到这里\n即可全屏打开";
    [self.backgroundView addSubview:dragAndDropLabel];
    dragAndDropLabel.alpha = 0;
    dragAndDropLabel.center = CGPointMake(dragAndDropView.center.x, dragAndDropLabel.center.y);
    
    
    scrollView = [[PODrawerScrollView alloc] initWithFrame:self.view.bounds];
    [scrollView setContentSize:CGSizeMake((self.view.bounds.size.width*2)-HANDLE_MARGIN, self.view.bounds.size.height)];
    [scrollView setDecelerationRate:UIScrollViewDecelerationRateFast];
    [scrollView setBackgroundColor:[UIColor clearColor]];
    [scrollView setShowsHorizontalScrollIndicator:NO];
    [scrollView setPagingEnabled:NO];
    scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    scrollView.directionalLockEnabled = YES;
    scrollView.delaysContentTouches = NO;
    [scrollView setDelegate:self];
    [self.view addSubview:scrollView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(close)];
    tap.delegate = self;
    tap.cancelsTouchesInView = NO;
    [scrollView addGestureRecognizer:tap];
    
    handleScrollView = [[BaseScrollView alloc] initWithFrame:CGRectMake(self.view.frame.size.width-HANDLE_MARGIN, 0, HANDLE_MARGIN, [UIScreen mainScreen].bounds.size.height*scale)];
    [handleScrollView setContentSize:CGSizeMake(handleScrollView.frame.size.width, (([UIScreen mainScreen].bounds.size.height*scale)*2)-34)];
    [handleScrollView setShowsVerticalScrollIndicator:NO];
    [handleScrollView setBackgroundColor:[UIColor clearColor]];
    [handleScrollView setDecelerationRate:UIScrollViewDecelerationRateFast];
    [handleScrollView setClipsToBounds:NO];
    handleScrollView.delaysContentTouches = NO;
    handleScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [handleScrollView setDelegate:self];
    NSString *savedHandle = [[POApplicationHelper state] stringForKey:@"handlePoint"];
    if (savedHandle.length) [handleScrollView setContentOffset:CGPointFromString(savedHandle)];
    handleScrollView.center = CGPointMake(handleScrollView.center.x, self.view.frame.size.height/2);
    [scrollView addSubview:handleScrollView];

    
    self.handle = [[POHandle alloc] initWithController:self];
    [self.handle setDelegate:self];
    CGRect r = self.handle.frame; r.origin.y = ([UIScreen mainScreen].bounds.size.height*scale)-self.handle.frame.size.height; self.handle.frame = r;
    handleFrame = self.handle.frame;
    handlePoint = handleScrollView.contentOffset;
    [handleScrollView addSubview:self.handle];
    
    self.quickSwitchTableView = [[QuickSwitchTableView alloc] initWithDarkMode:self.handle.darkMode];
    self.quickSwitchTableView.selectionDelegate = self;
    [handleScrollView addSubview:self.quickSwitchTableView];
    
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width, 20, [UIScreen mainScreen].bounds.size.width*scale, [UIScreen mainScreen].bounds.size.height*scale)];
    self.contentView.center = CGPointMake(self.contentView.center.x, self.view.frame.size.height/2);
    if (@available(iOS 13, *)){
        NSLog(@"iOS 13 bg color");
        self.contentView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    }else{
        NSLog(@"pre 13 bg color");

        self.contentView.backgroundColor = [[POApplicationHelper settings][@"darkHandle"] boolValue] ? [UIColor darkGrayColor] : [UIColor whiteColor];
    }
    self.contentView.layer.cornerRadius = 12;
    self.contentView.clipsToBounds = YES;
    self.contentView.multipleTouchEnabled = YES;
    
    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    activityIndicator.color = [UIColor whiteColor];
    activityIndicator.frame = CGRectMake(42, 54, 37, 37);
    activityIndicator.layer.shadowOpacity = 0.5;
    activityIndicator.layer.shadowRadius = 6;
    activityIndicator.layer.shadowOffset = CGSizeMake(0, 0);
    [activityIndicator stopAnimating];

    [self.contentView addSubview:activityIndicator];

    
    [scrollView addSubview:self.contentView];
    ((PODrawerScrollView *)scrollView).hostedContent = self.contentView;

    transformGestureRecognizer = [[POTwoFingerTransformGestureRecognizer alloc] initWithTarget:self action:@selector(handleTwoFingerTransform:)];
    transformGestureRecognizer.delegate = self;
    transformGestureRecognizer.cancelsTouchesInView = YES;
    transformGestureRecognizer.delaysTouchesBegan = NO;
    transformGestureRecognizer.delaysTouchesEnded = NO;
    // A SpringBoard-owned surface, separate from the remote presentation view.
    // While editing, it captures input rather than asking the hosted app to forward touches.
    _transformSurface = [[UIView alloc] initWithFrame:CGRectZero];
    _transformSurface.hidden = YES;
    _transformSurface.multipleTouchEnabled = YES;
    _transformSurface.backgroundColor = [UIColor colorWithWhite:0 alpha:0.06];
    _transformSurface.layer.borderWidth = 2;
    _transformSurface.layer.borderColor = [UIColor systemBlueColor].CGColor;
    _transformSurface.layer.cornerRadius = 12;
    _transformSurface.clipsToBounds = YES;
    [self.view addSubview:_transformSurface];
    [_transformSurface addGestureRecognizer:transformGestureRecognizer];
    transformGestureRecognizer.coordinateView = self.contentView;
    transformGestureRecognizer.enabled = NO;
    UIPanGestureRecognizer *localPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleLocalPan:)];
    localPan.minimumNumberOfTouches = 1;
    localPan.maximumNumberOfTouches = 1;
    localPan.delegate = self;
    [localPan requireGestureRecognizerToFail:transformGestureRecognizer];
    [_transformSurface addGestureRecognizer:localPan];
    transformStatus = [[UILabel alloc] initWithFrame:CGRectZero];
    transformStatus.textAlignment = NSTextAlignmentCenter;
    transformStatus.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightSemibold];
    transformStatus.textColor = UIColor.whiteColor;
    transformStatus.backgroundColor = [UIColor colorWithWhite:0 alpha:0.72];
    transformStatus.layer.cornerRadius = 8;
    transformStatus.clipsToBounds = YES;
    transformStatus.adjustsFontSizeToFitWidth = YES;
    transformStatus.minimumScaleFactor = 0.7;
    transformStatus.userInteractionEnabled = NO;
    [_transformSurface addSubview:transformStatus];

    // Dedicated local hit region. It remains active without an explicit edit mode.
    _gestureBar = [[UIView alloc] initWithFrame:CGRectZero];
    _gestureBar.hidden = YES;
    _gestureBar.multipleTouchEnabled = YES;
    _gestureBar.backgroundColor = UIColor.secondarySystemBackgroundColor;
    _gestureBar.layer.cornerRadius = 9;
    _gestureBar.clipsToBounds = YES;
    _gestureBar.isAccessibilityElement = NO;
    [self.view addSubview:_gestureBar];
    gestureBarLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    gestureBarLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    gestureBarLabel.textAlignment = NSTextAlignmentCenter;
    gestureBarLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    gestureBarLabel.textColor = UIColor.secondaryLabelColor;
    gestureBarLabel.adjustsFontSizeToFitWidth = YES;
    gestureBarLabel.minimumScaleFactor = 0.65;
    gestureBarLabel.userInteractionEnabled = NO;
    gestureBarLabel.accessibilityLabel = @"双指缩放与拖动手势条";
    [_gestureBar addSubview:gestureBarLabel];

    barGestureRecognizer = [[POTwoFingerTransformGestureRecognizer alloc] initWithTarget:self action:@selector(handleTwoFingerTransform:)];
    barGestureRecognizer.coordinateView = self.contentView;
    barGestureRecognizer.delegate = self;
    barGestureRecognizer.cancelsTouchesInView = YES;
    barGestureRecognizer.enabled = NO;
    [_gestureBar addGestureRecognizer:barGestureRecognizer];
    barPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleLocalPan:)];
    barPan.minimumNumberOfTouches = 1;
    barPan.maximumNumberOfTouches = 1;
    barPan.delegate = self;
    barPan.enabled = NO;
    [barPan requireGestureRecognizerToFail:barGestureRecognizer];
    [_gestureBar addGestureRecognizer:barPan];

    // Best-effort direct path: attach to the actual presentation view rather
    // than its ancestor; this is limited to UIKit events delivered locally.
    directGestureRecognizer = [[POTwoFingerTransformGestureRecognizer alloc] initWithTarget:self action:@selector(handleTwoFingerTransform:)];
    directGestureRecognizer.coordinateView = self.contentView;
    directGestureRecognizer.delegate = self;
    directGestureRecognizer.cancelsTouchesInView = YES;
    directGestureRecognizer.delaysTouchesBegan = NO;
    directGestureRecognizer.delaysTouchesEnded = NO;
    directGestureRecognizer.enabled = NO;

    _drawerControls = [[UIView alloc] initWithFrame:CGRectZero];
    _drawerControls.backgroundColor = [UIColor secondarySystemBackgroundColor];
    _drawerControls.layer.cornerRadius = 10;
    _drawerControls.hidden = YES;
    switchButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [switchButton setTitle:@"切换应用" forState:UIControlStateNormal];
    switchButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    [switchButton addTarget:self action:@selector(toggleExpandedSwitchMenu) forControlEvents:UIControlEventTouchUpInside];
    [_drawerControls addSubview:switchButton];
    zoomButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [zoomButton setTitle:@"输入放大" forState:UIControlStateNormal];
    zoomButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    [zoomButton addTarget:self action:@selector(toggleInputZoom) forControlEvents:UIControlEventTouchUpInside];
    [_drawerControls addSubview:zoomButton];
    keyboardButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [keyboardButton setTitle:@"键盘" forState:UIControlStateNormal];
    keyboardButton.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    keyboardButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    keyboardButton.titleLabel.minimumScaleFactor = 0.65;
    keyboardButton.accessibilityLabel = @"浮动键盘";
    [keyboardButton addTarget:self action:@selector(openLargeKeyboard) forControlEvents:UIControlEventTouchUpInside];
    [_drawerControls addSubview:keyboardButton];
    transformButton = [UIButton buttonWithType:UIButtonTypeSystem];
    transformButton.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    transformButton.accessibilityLabel = @"双指浮窗变换";
    [transformButton addTarget:self action:@selector(toggleTransformMode) forControlEvents:UIControlEventTouchUpInside];
    [_drawerControls addSubview:transformButton];
    resetButton = [UIButton buttonWithType:UIButtonTypeSystem];
    resetButton.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    [resetButton setTitle:@"复位" forState:UIControlStateNormal];
    resetButton.accessibilityLabel = @"恢复浮窗默认缩放和位置";
    [resetButton addTarget:self action:@selector(resetContextTransform) forControlEvents:UIControlEventTouchUpInside];
    [_drawerControls addSubview:resetButton];
    minusButton = [UIButton buttonWithType:UIButtonTypeSystem];
    plusButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [minusButton setTitle:@"−" forState:UIControlStateNormal];
    [plusButton setTitle:@"＋" forState:UIControlStateNormal];
    minusButton.accessibilityLabel = @"缩小画面";
    plusButton.accessibilityLabel = @"放大画面";
    for (UIButton *button in @[minusButton, plusButton]) {
        button.titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
        button.hidden = YES;
        [_drawerControls addSubview:button];
    }
    [minusButton addTarget:self action:@selector(zoomOutStep) forControlEvents:UIControlEventTouchUpInside];
    [plusButton addTarget:self action:@selector(zoomInStep) forControlEvents:UIControlEventTouchUpInside];
    switchButton.accessibilityLabel = @"切换浮窗应用";
    zoomButton.accessibilityLabel = @"横屏输入放大";
    for (UIButton *button in @[switchButton, zoomButton, transformButton, resetButton]) {
        button.titleLabel.adjustsFontSizeToFitWidth = YES;
        button.titleLabel.minimumScaleFactor = 0.65;
    }
    [self.view addSubview:_drawerControls];
    _expandedSwitchMenu = [[QuickSwitchTableView alloc] initWithDarkMode:self.handle.darkMode];
    _expandedSwitchMenu.selectionDelegate = self;
    [self.view addSubview:_expandedSwitchMenu];
    if ([[POApplicationHelper settings][@"leftHanded"] boolValue]) {
        switchButton.titleLabel.transform = CGAffineTransformMakeScale(-1, 1);
        zoomButton.titleLabel.transform = CGAffineTransformMakeScale(-1, 1);
        keyboardButton.titleLabel.transform = CGAffineTransformMakeScale(-1, 1);
        transformButton.titleLabel.transform = CGAffineTransformMakeScale(-1, 1);
        resetButton.titleLabel.transform = CGAffineTransformMakeScale(-1, 1);
        minusButton.titleLabel.transform = CGAffineTransformMakeScale(-1, 1);
        plusButton.titleLabel.transform = CGAffineTransformMakeScale(-1, 1);
        transformStatus.transform = CGAffineTransformMakeScale(-1, 1);
        gestureBarLabel.transform = CGAffineTransformMakeScale(-1, 1);
    }
    
    if ([[POApplicationHelper state] stringForKey:@"lastPinnedBundleId"]) {
        pinnedBundleId = [[POApplicationHelper state] stringForKey:@"lastPinnedBundleId"];
        UIImage *image = [POApplicationHelper imageForBundleId:pinnedBundleId];
        self.handle.imageView.image = image;
    }else{
        pinnedBundleId = @"com.apple.MobileSMS";
        UIImage *image = [POApplicationHelper imageForBundleId:pinnedBundleId];
        self.handle.imageView.image = image;
    }
    
    if ([[POApplicationHelper settings][@"leftHanded"] boolValue]){
        imageView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
        dragAndDropLabel.transform = CGAffineTransformMakeScale(-1.0, 1.0);
        self.handle.imageView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    }
    
    overlayView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    overlayView.backgroundColor = [UIColor clearColor];
    overlayView.userInteractionEnabled = NO;
    [self.view addSubview:overlayView];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [self updateHandleVisibility:0];
    [self updateLayoutForCurrentBounds];
}

// Keep a visible, interactive handle even when the user chooses to dim it.
-(void)updateHandleVisibility:(float)progress{
    BOOL dim = [[POApplicationHelper settings][@"hideHandle"] boolValue];
    self.handle.alpha = dim ? 0.55 + 0.45 * MIN(1, MAX(0, progress * 4)) : 1;
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    if (!CGRectEqualToRect(lastLayoutBounds, self.view.bounds) ||
        !UIEdgeInsetsEqualToEdgeInsets(lastSafeAreaInsets, self.view.safeAreaInsets)) {
        [self updateLayoutForCurrentBounds];
    }
}

-(BOOL)shouldAutorotate
{
    return YES;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskAll;
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self updateLayoutForCurrentBounds];
    }];
}

-(void)updateLayoutForCurrentBounds{
    CGRect bounds = self.view.bounds;
    if (CGRectIsEmpty(bounds) || !scrollView || !handleScrollView || !self.contentView) return;

    UIEdgeInsets safeInsets = self.view.safeAreaInsets;
    CGFloat width = CGRectGetWidth(bounds);
    CGFloat height = CGRectGetHeight(bounds);
    CGFloat panelHeight = MAX(1, height - safeInsets.top - safeInsets.bottom);
    CGFloat panelWidth = MAX(1, width - HANDLE_MARGIN - MAX(safeInsets.left, safeInsets.right));
    BOOL landscape = width > height;
    if (!landscape) inputZoom = NO;
    if (landscape) {
        CGFloat desiredWidth = inputZoom ? width * 0.65 : MAX(220, panelHeight * 0.85);
        panelWidth = MIN(panelWidth, desiredWidth);
    }
    // No reserved menu or gesture-status rows; temporary controls overlay content.
    CGFloat controlsHeight = 0;
    CGFloat gestureBarHeight = 0;
    [self cancelTransformGestures];
    CGFloat progress = drawerTravel > 0 ? MIN(1, MAX(0, scrollView.contentOffset.x / drawerTravel)) : 0;
    CGFloat oldMaximum = MAX(0, handleScrollView.contentSize.height - handleScrollView.bounds.size.height);
    CGFloat relativeY = oldMaximum > 0 ? MIN(1, MAX(0, handleScrollView.contentOffset.y / oldMaximum)) : 0;
    [self.quickSwitchTableView cancelPresentation];
    [self.expandedSwitchMenu cancelPresentation];
    updatingLayout = YES;
    CGFloat trailingInset = width > height ? MAX(safeInsets.left, safeInsets.right) : 0;
    drawerTravel = panelWidth + trailingInset;
    scale = MIN(1.0, panelWidth / MAX(1, width));

    scrollView.frame = bounds;
    scrollView.contentSize = CGSizeMake(width + drawerTravel, height);
    self.backgroundView.frame = bounds;
    dragAndDropView.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    dragAndDropLabel.center = CGPointMake(dragAndDropView.center.x, dragAndDropView.center.y + 80);
    overlayView.frame = bounds;

    handleScrollView.frame = CGRectMake(width - HANDLE_MARGIN, safeInsets.top, HANDLE_MARGIN, panelHeight);
    handleScrollView.contentSize = CGSizeMake(HANDLE_MARGIN, MAX(panelHeight, panelHeight * 2 - 34));
    CGFloat maximumOffset = MAX(0, handleScrollView.contentSize.height - handleScrollView.bounds.size.height);
    CGFloat offsetY = maximumOffset * relativeY;
    handleScrollView.contentOffset = CGPointMake(0, offsetY);

    CGRect handleBounds = self.handle.frame;
    handleBounds.origin.y = MAX(0, panelHeight - CGRectGetHeight(handleBounds));
    self.handle.frame = handleBounds;
    handleFrame = self.handle.frame;
    handlePoint = handleScrollView.contentOffset;

    self.contentView.frame = CGRectMake(width, safeInsets.top + controlsHeight, panelWidth, MAX(1, panelHeight - controlsHeight - gestureBarHeight));
    activityIndicator.center = CGPointMake(CGRectGetMidX(self.contentView.bounds), CGRectGetMidY(self.contentView.bounds));

    lastLayoutBounds = bounds;
    lastSafeAreaInsets = safeInsets;

    [scrollView setContentOffset:CGPointMake(progress * drawerTravel, 0) animated:NO];
    updatingLayout = NO;
    self.backgroundView.alpha = landscape && [[POApplicationHelper settings][@"landscapeTouchThrough"] boolValue] ? 0 : progress * (landscape ? 0.35 : 1);
    [self updateDrawerControls];
    if (contextView) [self layoutContextView];
}

-(void)updateDrawerControls{
    if (!self.drawerControls || !self.contentView) return;
    BOOL landscape = CGRectGetWidth(self.view.bounds) > CGRectGetHeight(self.view.bounds);
    CGRect panel = [self.contentView convertRect:self.contentView.bounds toView:self.view];
    self.drawerControls.hidden = !self.isOpened || !(toolsVisible || transformEnabled);
    self.drawerControls.frame = CGRectMake(CGRectGetMinX(panel), CGRectGetMinY(panel), CGRectGetWidth(panel), 44);
    CGFloat width = CGRectGetWidth(panel);
    NSArray<UIButton *> *buttons = transformEnabled ? @[minusButton, plusButton, transformButton, resetButton] :
        (landscape ? @[switchButton, keyboardButton, zoomButton, transformButton, resetButton] : @[switchButton, keyboardButton, transformButton, resetButton]);
    switchButton.hidden = transformEnabled;
    zoomButton.hidden = transformEnabled || !landscape;
    keyboardButton.hidden = transformEnabled;
    keyboardButton.enabled = contextView != nil && presentationAllowed;
    minusButton.hidden = !transformEnabled;
    plusButton.hidden = !transformEnabled;
    self.transformSurface.frame = panel;
    self.transformSurface.hidden = !transformEnabled || !self.isOpened || !contextView;
    CGFloat barHeight = showGestureBar ? MIN(44, MAX(0, CGRectGetHeight(self.view.bounds) - lastSafeAreaInsets.bottom - CGRectGetMaxY(panel))) : 0;
    self.gestureBar.frame = CGRectMake(CGRectGetMinX(panel), CGRectGetMaxY(panel), width, barHeight);
    gestureBarLabel.bounds = self.gestureBar.bounds;
    gestureBarLabel.center = CGPointMake(width / 2, barHeight / 2);
    self.gestureBar.hidden = YES;
    if (self.floatingKeyboard && !self.floatingKeyboard.hidden) [(POFloatingKeyboard *)self.floatingKeyboard placeInBounds:self.view.bounds safeInsets:lastSafeAreaInsets];
    [self updateTransformGestureAvailability];
    CGFloat statusWidth = MIN(220, MAX(1, width - 16));
    transformStatus.bounds = CGRectMake(0, 0, statusWidth, 28);
    transformStatus.center = CGPointMake(width / 2, 20);
    [self updateTransformStatus];
    [self.view bringSubviewToFront:self.drawerControls];
    if (_floatingKeyboard) [self.view bringSubviewToFront:_floatingKeyboard];
    if (self.expandedSwitchMenu.isPresented) [self.view bringSubviewToFront:self.expandedSwitchMenu];
    CGFloat cellWidth = width / buttons.count;
    for (NSUInteger i = 0; i < buttons.count; i++) {
        buttons[i].frame = CGRectMake(i * cellWidth, 0, cellWidth, 44);
    }
    [zoomButton setTitle:inputZoom ? @"恢复" : @"放大" forState:UIControlStateNormal];
    [transformButton setTitle:transformEnabled ? @"完成" : @"调整" forState:UIControlStateNormal];
    transformButton.accessibilityValue = transformEnabled ? @"画面调整中" : @"普通应用操作";
    transformButton.enabled = contextView != nil || transformEnabled;
    transformButton.tintColor = transformEnabled ? [UIColor systemBlueColor] : [UIColor secondaryLabelColor];
}

-(void)toggleExpandedSwitchMenu{
    if (!self.isOpened || !presentationAllowed || isInvalidated) return;
    [self hideFloatingKeyboard];
    if (transformEnabled) [self setTransformEditing:NO];
    if (self.expandedSwitchMenu.isPresented) {
        [self.expandedSwitchMenu cancelPresentation];
        [self updateDrawerControls];
        return;
    }
    [self.quickSwitchTableView cancelPresentation];
    CGRect panel = [self.contentView convertRect:self.contentView.bounds toView:self.view];
    if (![self.expandedSwitchMenu presentForTapSelectionInFrame:panel]) {
        [switchButton setTitle:@"暂无应用" forState:UIControlStateNormal];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self->switchButton setTitle:@"切换应用" forState:UIControlStateNormal];
        });
    }
    [self updateDrawerControls];
}

-(void)toggleTools {
    if (!self.isOpened) return;
    if (transformEnabled) {[self setTransformEditing:NO];toolsVisible=NO;}
    else toolsVisible=!toolsVisible;
    [self updateDrawerControls];
}
-(void)hideFloatingKeyboard {
    [keyboardBridge stop];
    [_floatingKeyboard removeFromSuperview];
    _floatingKeyboard=nil;
}
-(void)openLargeKeyboard {
    if (![self canTransformHostedScene] || transformEnabled || keyboardComposer.isPresented) return;
    if (_floatingKeyboard) {[self hideFloatingKeyboard];return;}
    toolsVisible=NO;
    [self updateDrawerControls];
    POFloatingKeyboard *floating=[[POFloatingKeyboard alloc] initWithFrame:CGRectZero];
    _floatingKeyboard=floating;
    // Counter the left-hand mirror so key labels and drag direction remain natural.
    if ([[POApplicationHelper settings][@"leftHanded"] boolValue]) floating.transform=CGAffineTransformMakeScale(-1,1);
    [self.view addSubview:floating];
    [floating placeInBounds:self.view.bounds safeInsets:lastSafeAreaInsets];
    __weak typeof(self) weakSelf=self;
    __weak POFloatingKeyboard *weakFloating=floating;
    floating.dismissHandler=^{[weakSelf hideFloatingKeyboard];};
    [keyboardBridge startForBundle:pinnedBundleId status:^(POKeyStatus status){[weakFloating reportStatus:status];}];
    floating.keyHandler=^BOOL(NSInteger key){
        PullOverViewController *s=weakSelf;
        if(!s || ![s canTransformHostedScene] || s->transformEnabled || s.floatingKeyboard!=weakFloating)return NO;
        return [s->keyboardBridge sendKey:key];
    };
    floating.nativeHandler=^{[weakSelf hideFloatingKeyboard];[weakSelf openNativeComposer];};
}
-(void)openNativeComposer {
    if (![self canTransformHostedScene] || transformEnabled || keyboardComposer.isPresented) return;
    [self.expandedSwitchMenu cancelPresentation];
    [self cancelTransformGestures];
    __weak typeof(self) weakSelf = self;
    if (![keyboardComposer presentFromWindow:self.view.window completion:^(BOOL copied){
        PullOverViewController *strongSelf=weakSelf;
        if (!strongSelf || strongSelf->isInvalidated) return;
        [strongSelf updateDrawerControls];
        if (copied && strongSelf.isOpened) {
            [strongSelf->keyboardButton setTitle:@"已复制" forState:UIControlStateNormal];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(1.8*NSEC_PER_SEC)),dispatch_get_main_queue(),^{
                [strongSelf->keyboardButton setTitle:@"大键盘" forState:UIControlStateNormal];
            });
        }
    }]) [self updateDrawerControls];
}

-(void)toggleInputZoom{
    if (!self.isOpened || !presentationAllowed || CGRectGetWidth(self.view.bounds) <= CGRectGetHeight(self.view.bounds)) return;
    [self.expandedSwitchMenu cancelPresentation];
    inputZoom = !inputZoom;
    [self updateLayoutForCurrentBounds];
}

-(BOOL)canTransformHostedScene {
    return self.isOpened && presentationAllowed && !isInvalidated && !keyboardComposer.isPresented && !self.expandedSwitchMenu.isPresented && contextView != nil &&
        [[ContextHostManager sharedInstance] isHostViewHosting:contextView];
}

-(void)updateTransformGestureAvailability {
    BOOL available = [self canTransformHostedScene];
    BOOL supported = POGestureBundleSupported(pinnedBundleId);
    BOOL direct = available && autoDirectGestures && !transformEnabled && !supported;
    [self updateRemoteBridge];
    BOOL bar = available && !self.gestureBar.hidden && showGestureBar;
    BOOL edit = available && transformEnabled;
    if (directGestureRecognizer.enabled != direct) directGestureRecognizer.enabled = direct;
    if (barGestureRecognizer.enabled != bar) barGestureRecognizer.enabled = bar;
    if (barPan.enabled != bar) barPan.enabled = bar;
    if (transformGestureRecognizer.enabled != edit) transformGestureRecognizer.enabled = edit;
}

-(void)stopRemoteBridge {
    [remoteBridge stop];
    remoteGestureActive = NO;
    lastRemoteGesture = 0;
    remoteLastEvent = 0;
    remoteFiltered = (POStableSample){1,0,0};
}

-(void)publishRemoteGeometry {
    if (!remoteBridge.bundle || !contextView || remoteGestureActive) return;
    CGFloat effectiveScale = MAX(0.01, contextBaseScale * userScale);
    if ([[POApplicationHelper settings][@"leftHanded"] boolValue]) effectiveScale = -effectiveScale;
    [remoteBridge publishScale:effectiveScale centerX:contextBaseCenter.x+userOffset.x centerY:contextBaseCenter.y+userOffset.y];
}

-(void)updateRemoteBridge {
    BOOL allowed = autoDirectGestures && !transformEnabled && [self canTransformHostedScene] &&
        POGestureBundleSupported(pinnedBundleId) && ![[POApplicationHelper frontMostBundleId] isEqualToString:pinnedBundleId];
    if (!allowed) { if (remoteBridge.bundle) [self stopRemoteBridge]; return; }
    if (![remoteBridge.bundle isEqualToString:pinnedBundleId]) {
        [self stopRemoteBridge];
        __weak typeof(self) weakSelf = self;
        if (![remoteBridge startForBundle:pinnedBundleId handler:^(PORemoteTransform event) {
            [weakSelf handleRemoteTransform:event];
        }]) return;
    }
    [self publishRemoteGeometry];
}

-(void)handleRemoteTransform:(PORemoteTransform)event {
    if (!autoDirectGestures || transformEnabled || ![self canTransformHostedScene] ||
        ![remoteBridge.bundle isEqualToString:pinnedBundleId] ||
        [[POApplicationHelper frontMostBundleId] isEqualToString:pinnedBundleId]) return;
    if (!event.phase) { [self updateTransformStatus]; return; }
    if (!event.gesture || activeTransformGesture || !isfinite(event.ratio)) return;
    if (lastRemoteGesture != event.gesture) {
        lastRemoteGesture = event.gesture;
        remoteGestureActive = YES;
        remoteStartScale = userScale;
        remoteStartOffset = userOffset;
        remoteFiltered = (POStableSample){1,0,0};
        remoteLastEvent = 0;
    }
    if (!remoteGestureActive) return;
    CFTimeInterval now = CACurrentMediaTime();
    double dt = remoteLastEvent > 0 ? now-remoteLastEvent : 1.0/30.0;
    remoteLastEvent = now;
    POStableSample target = {event.ratio,event.dx,event.dy};
    if (remoteDeferred && event.phase != 3) return;
    // A release-only fallback eliminates visual-transform feedback completely.
    // Live mode damps the input and does not jump to a noisy final sample.
    if (remoteDeferred) remoteFiltered = target;
    else if (event.phase != 3) remoteFiltered = POFilterGesture(remoteFiltered,target,dt);
    userScale = POTransformScale(remoteStartScale * remoteFiltered.ratio);
    CGFloat ratio = userScale/MAX(0.001,remoteStartScale);
    CGPoint pivot = CGPointMake(CGRectGetMidX(self.contentView.bounds),CGRectGetMidY(self.contentView.bounds));
    POPoint center = POTransformCenter((POPoint){contextBaseCenter.x+remoteStartOffset.x,contextBaseCenter.y+remoteStartOffset.y},
        (POPoint){pivot.x,pivot.y},(POPoint){remoteFiltered.dx,remoteFiltered.dy},ratio);
    userOffset = CGPointMake(center.x-contextBaseCenter.x,center.y-contextBaseCenter.y);
    [self applyContextTransform];
    if (event.phase==3) {
        remoteGestureActive=NO;
        [self saveAppTransform];
        [self publishRemoteGeometry];
    }
}

-(void)cancelTransformGestures {
    [self stopRemoteBridge];
    transformGestureRecognizer.enabled = NO;
    directGestureRecognizer.enabled = NO;
    barGestureRecognizer.enabled = NO;
    barPan.enabled = NO;
    activeTransformGesture = nil;
}

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    if (gestureRecognizer == transformGestureRecognizer || gestureRecognizer == directGestureRecognizer ||
        gestureRecognizer == barGestureRecognizer || gestureRecognizer == barPan) {
        if (remoteGestureActive && CACurrentMediaTime()-remoteLastEvent>1.0) remoteGestureActive=NO;
        if (![self canTransformHostedScene] || remoteGestureActive || (activeTransformGesture && activeTransformGesture != gestureRecognizer)) return NO;
        if (gestureRecognizer == directGestureRecognizer) return autoDirectGestures && !transformEnabled;
        if (gestureRecognizer == transformGestureRecognizer) return transformEnabled;
        return showGestureBar && !self.gestureBar.hidden;
    }
    return YES;
}

-(void)toggleTransformMode {
    [self setTransformEditing:!transformEnabled];
}

-(void)setTransformEditing:(BOOL)enabled {
    if (enabled) [self hideFloatingKeyboard];
    if (enabled && (!self.isOpened || !presentationAllowed || isInvalidated || !contextView ||
        ![[ContextHostManager sharedInstance] isHostViewHosting:contextView])) return;
    [self cancelTransformGestures];
    if (enabled && !transformEnabled) {
        [self.expandedSwitchMenu cancelPresentation];
        hostWasInteractive = contextView.userInteractionEnabled;
        hostInteractionSaved = YES;
        contextView.userInteractionEnabled = NO;
    } else if (!enabled && hostInteractionSaved) {
        contextView.userInteractionEnabled = hostWasInteractive;
        hostInteractionSaved = NO;
    }
    transformEnabled = enabled;
    toolsVisible = enabled;
    if (!enabled && contextView) [self saveAppTransform];
    [self updateDrawerControls];
    POLog(@"local transform edit=%d", enabled);
}

-(void)updateTransformStatus {
    transformStatus.text = [NSString stringWithFormat:@"%.0f%%  ·  双指缩放／拖动", userScale * 100];
    gestureBarLabel.text = [NSString stringWithFormat:@"%@  %.0f%%", remoteBridge.ready ? (remoteDeferred ? @"松手应用 · 已连接" : @"手势通道已连接") : @"↔  双指缩放／拖动", userScale * 100];
    minusButton.enabled = userScale > 0.5001;
    plusButton.enabled = userScale < 2.9999;
}

-(void)changeZoomBy:(CGFloat)factor {
    if (!transformEnabled || !contextView) return;
    [self cancelTransformGestures];
    CGFloat oldScale = MAX(0.001, userScale);
    userScale = POTransformScale(oldScale * factor);
    CGFloat ratio = userScale / oldScale;
    CGPoint pivot = CGPointMake(CGRectGetMidX(self.contentView.bounds), CGRectGetMidY(self.contentView.bounds));
    POPoint center = POTransformCenter((POPoint){contextBaseCenter.x+userOffset.x,contextBaseCenter.y+userOffset.y},
        (POPoint){pivot.x,pivot.y}, (POPoint){0,0}, ratio);
    userOffset = CGPointMake(center.x-contextBaseCenter.x,center.y-contextBaseCenter.y);
    [self applyContextTransform];
    [self saveAppTransform];
    [self updateTransformGestureAvailability];
}
-(void)zoomInStep { [self changeZoomBy:1.25]; }
-(void)zoomOutStep { [self changeZoomBy:0.8]; }

-(void)handleLocalPan:(UIPanGestureRecognizer *)recognizer {
    BOOL isBar = recognizer == barPan;
    if (![self canTransformHostedScene] || (!isBar && !transformEnabled)) return;
    UIGestureRecognizerState state = recognizer.state;
    if (state == UIGestureRecognizerStateBegan) {
        if (activeTransformGesture && activeTransformGesture != recognizer) return;
        activeTransformGesture = recognizer;
    }
    if (activeTransformGesture != recognizer) return;
    if (state == UIGestureRecognizerStateBegan || state == UIGestureRecognizerStateChanged) {
        CGPoint delta = [recognizer translationInView:self.contentView];
        userOffset = CGPointMake(userOffset.x+delta.x,userOffset.y+delta.y);
        [recognizer setTranslation:CGPointZero inView:self.contentView];
        [self applyContextTransform];
    } else if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled || state == UIGestureRecognizerStateFailed) {
        activeTransformGesture = nil;
        [self saveAppTransform];
    }
}

-(void)resetContextTransform {
    [self cancelTransformGestures];
    userScale = 1;
    userOffset = CGPointZero;
    if (contextView) [self applyContextTransform];
    [self updateTransformGestureAvailability];
    [self saveAppTransform];
}

-(void)saveAppTransform {
    if (!pinnedBundleId.length) return;
    if (appTransforms.count >= 32 && !appTransforms[pinnedBundleId]) {
        NSString *key = appTransforms.allKeys.firstObject;
        if (key) [appTransforms removeObjectForKey:key];
    }
    appTransforms[pinnedBundleId] = @{@"scale": @(userScale),
        @"x": @(userOffset.x / MAX(1, transformViewport.width)),
        @"y": @(userOffset.y / MAX(1, transformViewport.height))};
}

-(void)restoreAppTransform:(NSString *)bundleId {
    NSDictionary *saved = appTransforms[bundleId];
    userScale = saved ? POTransformScale([saved[@"scale"] doubleValue]) : 1;
    userOffset = CGPointMake([saved[@"x"] doubleValue] * MAX(1, transformViewport.width),
                             [saved[@"y"] doubleValue] * MAX(1, transformViewport.height));
}

-(void)handleTwoFingerTransform:(POTwoFingerTransformGestureRecognizer *)recognizer {
    UIGestureRecognizerState state = recognizer.state;
    if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled || state == UIGestureRecognizerStateFailed) {
        if (activeTransformGesture == recognizer) {
            activeTransformGesture = nil;
            if (contextView) [self saveAppTransform];
        }
        return;
    }
    if (![self canTransformHostedScene]) return;
    if (state == UIGestureRecognizerStateBegan) {
        if (activeTransformGesture && activeTransformGesture != recognizer) return;
        activeTransformGesture = recognizer;
        gestureStartScale = userScale;
        gestureStartOffset = userOffset;
        POLog(@"two-finger began source=%@", recognizer == directGestureRecognizer ? @"host" : recognizer == barGestureRecognizer ? @"bar" : @"edit");
    } else if (state != UIGestureRecognizerStateChanged || activeTransformGesture != recognizer) {
        return;
    }
    userScale = POTransformScale(gestureStartScale * recognizer.scaleFactor);
    CGFloat ratio = userScale / MAX(0.001, gestureStartScale);
    CGPoint pivot = recognizer.initialCenter, delta = recognizer.translation;
    // The grip is outside the content; zoom around the viewport center instead.
    if (recognizer == barGestureRecognizer) pivot = CGPointMake(CGRectGetMidX(self.contentView.bounds), CGRectGetMidY(self.contentView.bounds));
    POPoint center = POTransformCenter((POPoint){contextBaseCenter.x + gestureStartOffset.x, contextBaseCenter.y + gestureStartOffset.y},
                                      (POPoint){pivot.x,pivot.y}, (POPoint){delta.x,delta.y}, ratio);
    userOffset = CGPointMake(center.x-contextBaseCenter.x,center.y-contextBaseCenter.y);
    [self applyContextTransform];
}

-(CGPoint)clampedContextOffset:(CGPoint)offset {
    if (!contextView || !self.contentView) return offset;
    CGFloat effectiveScale = contextBaseScale * userScale;
    CGFloat w = CGRectGetWidth(contextView.bounds) * effectiveScale;
    CGFloat h = CGRectGetHeight(contextView.bounds) * effectiveScale;
    CGSize panel = self.contentView.bounds.size;
    return CGPointMake(POClampCenter(contextBaseCenter.x + offset.x, panel.width, w)-contextBaseCenter.x,
                       POClampCenter(contextBaseCenter.y + offset.y, panel.height, h)-contextBaseCenter.y);
}

-(void)applyContextTransform{
    if (!contextView || !self.contentView) return;
    userOffset = [self clampedContextOffset:userOffset];
    CGPoint targetCenter = CGPointMake(contextBaseCenter.x + userOffset.x, contextBaseCenter.y + userOffset.y);
    CGFloat effectiveScale = MAX(0.01, contextBaseScale * userScale);
    CGAffineTransform transform = CGAffineTransformMakeScale(effectiveScale, effectiveScale);
    if ([[POApplicationHelper settings][@"leftHanded"] boolValue]) {
        transform = CGAffineTransformConcat(transform, CGAffineTransformMakeScale(-1.0, 1.0));
    }
    // Commit center and scale together, with no inherited UIView or CA animations.
    [UIView performWithoutAnimation:^{
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        if (!CGPointEqualToPoint(contextView.center,targetCenter)) contextView.center=targetCenter;
        if (!CGAffineTransformEqualToTransform(contextView.transform,transform)) contextView.transform=transform;
        [CATransaction commit];
    }];
    [self publishRemoteGeometry];
    [self updateTransformStatus];
}

-(void)keyboardWillShow:(NSNotification *)notification{
    if (![[POApplicationHelper settings][@"keyboardAvoiding"] boolValue]) return;
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    if (CGRectIsEmpty(keyboardFrame)) return;
    keyboardFrame = [self.view convertRect:keyboardFrame fromView:nil];
    CGRect handleInView = [self.handle convertRect:self.handle.bounds toView:self.view];
    CGFloat overlap = CGRectGetMaxY(handleInView) - CGRectGetMinY(keyboardFrame);
    if (overlap <= 0) return;

    if (!originalHandleOffset) originalHandleOffset = @(handleScrollView.contentOffset.y);
    CGFloat maximumOffset = MAX(0, handleScrollView.contentSize.height - handleScrollView.bounds.size.height);
    CGFloat targetOffset = MIN(maximumOffset, handleScrollView.contentOffset.y + overlap + 12);
    [handleScrollView setContentOffset:CGPointMake(0, targetOffset) animated:YES];
}

-(void)keyboardWillHide:(NSNotification *)notification{
    if (![[POApplicationHelper settings][@"keyboardAvoiding"] boolValue] || !originalHandleOffset) return;
    [handleScrollView setContentOffset:CGPointMake(0, originalHandleOffset.doubleValue) animated:YES];
    originalHandleOffset = nil;
}


-(void)pinAppWithBundleId:(NSString *)bundleId{
    if (![bundleId isKindOfClass:[NSString class]] || bundleId.length == 0 || isInvalidated || !presentationAllowed) return;
    POLog(@"pin %@ (front=%@)", bundleId, [POApplicationHelper frontMostBundleId]);
    if (self.isOpened && [[POApplicationHelper frontMostBundleId] isEqualToString:bundleId]) {
        [self close];
        return;
    }
    if (self.isOpened && [pinnedBundleId isEqualToString:bundleId]) {
        [self retryHostingIfNeeded];
        return;
    }
    BOOL changedApp = ![pinnedBundleId isEqualToString:bundleId];
    if (changedApp) {[self hideFloatingKeyboard];toolsVisible=NO;}
    if (changedApp) [self saveAppTransform];
    if (self.isOpened) [self endHosting];
    if (changedApp) [self restoreAppTransform:bundleId];
    pinnedBundleId = bundleId;
    NSUInteger generation = ++pinGeneration;
    
    [[POApplicationHelper state] setObject:bundleId forKey:@"lastPinnedBundleId"];
    UIImage *image = [POApplicationHelper imageForBundleId:bundleId];
    self.handle.imageView.image = image;
    
    if ([[POApplicationHelper frontMostBundleId] isEqualToString:bundleId]) {
        // _returnToHomescreenWithCompletion: is gone on iOS 15+; a simulated Home press does the same (iOS 15-27).
        id sb = [UIApplication sharedApplication];
        if ([sb respondsToSelector:@selector(_simulateHomeButtonPressWithCompletion:)]) [sb _simulateHomeButtonPressWithCompletion:nil];
        else if ([sb respondsToSelector:@selector(_simulateHomeButtonPress)]) [sb _simulateHomeButtonPress];
    }else{
        if (self.isOpened) {
            [self beginHosting];
            return;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self->isInvalidated || !self->presentationAllowed || generation != self->pinGeneration ||
                ![self->pinnedBundleId isEqualToString:bundleId] ||
                ![[POApplicationHelper settings][@"enabled"] boolValue]) return;
            [self open];
        });
    }
}

-(void)open{
    if (!presentationAllowed || isInvalidated || drawerTravel <= 0) return;
    self.handle.isNubbed = NO;
    [scrollView setContentOffset:CGPointMake(drawerTravel, 0) animated:YES];
}

-(void)close{
    toolsVisible=NO;
    [self hideFloatingKeyboard];
    [keyboardComposer dismiss];
    pinGeneration++;
    [self.quickSwitchTableView cancelPresentation];
    [self.expandedSwitchMenu cancelPresentation];
    if (transformEnabled) [self setTransformEditing:NO];
    [scrollView setContentOffset:CGPointZero animated:YES];
}

-(void)setPresentationAllowed:(BOOL)allowed{
    if (presentationAllowed == allowed) return;
    presentationAllowed = allowed;
    if (!allowed) [self closeAndStopHosting];
    self.view.userInteractionEnabled = allowed;
    if (allowed) [self scheduleAutoNub];
}

#pragma mark - MHHandleDelegate

-(void)handle:(POHandle *)handle didReceiveTap:(UIGestureRecognizer *)recognizer{
    if (!self.isOpened) {
        [self open];
    }else{
        [self close];
    }
}

-(void)handle:(POHandle *)handle didLongPress:(UILongPressGestureRecognizer *)recognizer{
    if (presentationAllowed && self.isOpened) {
        if (recognizer.state == UIGestureRecognizerStateBegan) [self toggleTools];
        return;
    }
    if (presentationAllowed && !self.isOpened) {
        if (recognizer.state == UIGestureRecognizerStateBegan) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(autoNubAfterDelay) object:nil];
        }
        if (self.handle.isNubbed) {
            self.handle.isNubbed = NO;
        }

        [self.quickSwitchTableView presentFromHandle:handle withRecognizer:recognizer];
        
        [UIView animateWithDuration:0.3 animations:^{
            if (recognizer.state == UIGestureRecognizerStateBegan) {
                self.backgroundView.alpha = self.quickSwitchTableView.isPresented ? 1 : 0;
            }else if (recognizer.state != UIGestureRecognizerStateChanged){
                self.backgroundView.alpha = 0;
            }
        }];
        if (recognizer.state != UIGestureRecognizerStateBegan && recognizer.state != UIGestureRecognizerStateChanged) {
            [self scheduleAutoNub];
        }
    }
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] &&
        (touch.view == self.contentView || [touch.view isDescendantOfView:self.contentView] || touch.view == self.handle || [touch.view isDescendantOfView:self.handle])) {
        return NO;
    }
    return YES;
}


#pragma mark - QuickSwitch

-(void)quickSwitchTableView:(QuickSwitchTableView *)quickSwitchTableView didSelectBundleId:(NSString *)bundleId{
    [self pinAppWithBundleId:bundleId];
}

-(void)quickSwitchTableViewWillAppear:(QuickSwitchTableView *)quickSwitchTableView{
    dragAndDropView.alpha = 1;
    if (![[POApplicationHelper settings][@"hideLabels"] boolValue]){
        dragAndDropLabel.alpha = 1;
    }
}

-(void)quickSwitchTableView:(QuickSwitchTableView *)quickSwitchTableView draggingDidChangeForQuickSwitchItem:(SBApplication *)app withPoint:(CGPoint)point{
    if (!app) return;
    if (!draggableImageView) {
        draggableImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
        draggableImageView.image = [POApplicationHelper imageForBundleId:app.bundleIdentifier];
        draggableImageView.contentMode = UIViewContentModeScaleAspectFill;
        draggableImageView.center = [self.backgroundView convertPoint:point fromView:quickSwitchTableView];
        [self.backgroundView addSubview:draggableImageView];
        
        if ([[POApplicationHelper settings][@"leftHanded"] boolValue]){
            draggableImageView.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(-1.0, 1.0), CGAffineTransformMakeScale(0.01, 0.01));
            [UIView animateWithDuration:0.2 animations:^{
                draggableImageView.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(-1.0, 1.0), CGAffineTransformMakeScale(1, 1));
            }];
        }else{
            draggableImageView.transform = CGAffineTransformMakeScale(0.01, 0.01);
            [UIView animateWithDuration:0.2 animations:^{
                draggableImageView.transform = CGAffineTransformMakeScale(1, 1);
            }];
        }
    }
    
    draggableImageView.center = [self.backgroundView convertPoint:point fromView:quickSwitchTableView];

    CGPoint locationInView = [dragAndDropView convertPoint:point fromView:quickSwitchTableView];
    if (CGRectContainsPoint(dragAndDropView.bounds, locationInView) ) {
        [UIView animateWithDuration:0.3f animations:^{
            dragAndDropLabel.text = [NSString stringWithFormat:@"打开 %@", app.displayName];
            dragAndDropView.transform = CGAffineTransformMakeScale(1.3, 1.3);
        }];
    }else{
        [UIView animateWithDuration:0.3f animations:^{
            dragAndDropLabel.text = @"将应用拖到这里\n即可全屏打开";
            dragAndDropView.transform = CGAffineTransformMakeScale(1, 1);
        }];
    }
}

-(void)quickSwitchTableView:(QuickSwitchTableView *)quickSwitchTableView didDropApp:(SBApplication *)app atPoint:(CGPoint)point{
    [self removeDraggableImageViewAnimated];
    if (!presentationAllowed || !app.bundleIdentifier.length) return;
    if (CGRectContainsPoint(dragAndDropView.bounds, [dragAndDropView convertPoint:point fromView:quickSwitchTableView]) ) {
        [[ContextHostManager sharedInstance] openFullScreen:app.bundleIdentifier];
    }
}

-(void)draggingDidEnterBoundsOfQuickSwitchTableView:(QuickSwitchTableView *)quickSwitchTableView{
    [self removeDraggableImageViewAnimated];
}

-(void)removeDraggableImageViewAnimated{
    UIImageView *imageView = draggableImageView;
    if (!imageView) return;
    draggableImageView = nil;
    [imageView.layer removeAllAnimations];

    
    if ([[POApplicationHelper settings][@"leftHanded"] boolValue]){
        imageView.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(-1.0, 1.0), CGAffineTransformMakeScale(1, 1));
        [UIView animateWithDuration:0.2 animations:^{
            imageView.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(-1.0, 1.0), CGAffineTransformMakeScale(0.01, 0.01));
        }completion:^(BOOL finished) {
            [imageView removeFromSuperview];
        }];

    }else{
        imageView.transform = CGAffineTransformMakeScale(1, 1);
        [UIView animateWithDuration:0.2 animations:^{
            imageView.transform = CGAffineTransformMakeScale(0.01, 0.01);
        }completion:^(BOOL finished) {
            [imageView removeFromSuperview];
        }];
    }

    
    [UIView animateWithDuration:0.3f animations:^{
        dragAndDropLabel.text = @"将应用拖到这里\n即可全屏打开";
        dragAndDropView.transform = CGAffineTransformMakeScale(1, 1);
    }];
}

-(void)quickSwitchTableViewDidDisappear:(QuickSwitchTableView *)quickSwitchTableView{
    [self updateDrawerControls];
    [self removeDraggableImageViewAnimated];
    dragAndDropView.alpha = 0;
    dragAndDropLabel.alpha = 0;
    if (!self.isOpened) {
        self.backgroundView.alpha = 0;
        [self scheduleAutoNub];
    }
}



#pragma mark - UIScrollViewDelegate

-(void)scrollViewDidEndDragging:(UIScrollView *)sv willDecelerate:(BOOL)decelerate{
    if (sv == handleScrollView && scrollView.contentOffset.x <= 1.0 && !originalHandleOffset) {
        handleFrame = self.handle.frame;
        handlePoint = handleScrollView.contentOffset;
        [[POApplicationHelper state] setValue:NSStringFromCGPoint(handlePoint) forKey:@"handlePoint"];
    }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)sv{
    if (sv == handleScrollView && scrollView.contentOffset.x <= 1.0 && !originalHandleOffset) {
        handleFrame = self.handle.frame;
        handlePoint = handleScrollView.contentOffset;
        [[POApplicationHelper state] setValue:NSStringFromCGPoint(handlePoint) forKey:@"handlePoint"];
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)sv{
    if (sv == scrollView && !updatingLayout) {
        CGFloat denominator = MAX(1, drawerTravel);
        CGFloat progress = scrollView.contentOffset.x / denominator;
        CGFloat visibleProgress = MIN(1, MAX(0, progress));
        BOOL landscape = self.view.bounds.size.width > self.view.bounds.size.height;
        BOOL touchThrough = landscape && [[POApplicationHelper settings][@"landscapeTouchThrough"] boolValue];
        self.backgroundView.alpha = touchThrough ? 0 : visibleProgress * (landscape ? 0.35 : 1);
        [self updateHandleVisibility:visibleProgress];

        if (suppressHostingUntilClosed) {
            if (progress <= 0.01) {
                suppressHostingUntilClosed = NO;
                self.isOpened = NO;
            }
        } else {
            self.isOpened = presentationAllowed && progress > 0.01;
        }

        if (self.expandedSwitchMenu.isPresented) [self.expandedSwitchMenu cancelPresentation];
        [self updateDrawerControls];
        if (progress < -0.01) {
            if (!self.handle.isNubbed) {
                self.handle.isNubbed = YES;
            }
        }else if (progress > 0.01){
            if (self.handle.isNubbed) {
                self.handle.isNubbed = NO;
            }
        }
    }
}

-(void)scrollViewWillEndDragging:(UIScrollView *)sv withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset{
    if (sv != scrollView) return;
    BOOL shouldOpen = presentationAllowed && (velocity.x > 0.2 || (velocity.x >= -0.2 && targetContentOffset->x > drawerTravel / 2));
    targetContentOffset->x = shouldOpen ? drawerTravel : 0;
    targetContentOffset->y = 0;
}

-(void)setIsOpened:(BOOL)isOpened{
    if (_isOpened == isOpened) return;
    _isOpened = isOpened;
    overlayView.userInteractionEnabled = NO;
    if (isOpened) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(autoNubAfterDelay) object:nil];
        [self beginHosting];
    }else{
        [self.expandedSwitchMenu cancelPresentation];
        [self endHosting];
        if (inputZoom) {
            inputZoom = NO;
            [self updateLayoutForCurrentBounds];
        }
        [self scheduleAutoNub];
    }
    [self updateDrawerControls];
}

-(void)scheduleAutoNub{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(autoNubAfterDelay) object:nil];
    if (isInvalidated || !presentationAllowed || self.isOpened || self.handle.isNubbed ||
        self.quickSwitchTableView.isPresented || ![[POApplicationHelper settings][@"autoNub"] boolValue]) return;
    [self performSelector:@selector(autoNubAfterDelay) withObject:nil
               afterDelay:[[POApplicationHelper settings][@"autoNub-time"] intValue]];
}

-(void)autoNubAfterDelay{
    if (isInvalidated || !presentationAllowed || self.isOpened || self.quickSwitchTableView.isPresented) return;
    if (handleScrollView.isTracking || handleScrollView.isDragging || scrollView.isTracking) {
        [self scheduleAutoNub];
        return;
    }
    [self.handle setIsNubbed:YES];
}

-(void)beginHosting{
    if (isInvalidated || !presentationAllowed || !self.isOpened || suppressHostingUntilClosed || pinnedBundleId.length == 0) return;
    if ([[ContextHostManager sharedInstance] isHostViewHosting:contextView]) return;
    if (hostingInProgress) return;

    hostingInProgress = YES;
    launchRequested = NO;
    hostingAttempts = 0;
    NSUInteger generation = ++hostingGeneration;
    [activityIndicator startAnimating];
    [self attemptHostingForGeneration:generation];
}

-(void)layoutContextView{
    if (!contextView || !self.contentView) return;
    BOOL newlyAttached = contextView.superview != self.contentView;
    CGSize sourceSize = contextView.bounds.size;
    if (sourceSize.width <= 0 || sourceSize.height <= 0) sourceSize = [UIScreen mainScreen].bounds.size;
    CGFloat fitScale = MIN(CGRectGetWidth(self.contentView.bounds) / MAX(1, sourceSize.width),
                           CGRectGetHeight(self.contentView.bounds) / MAX(1, sourceSize.height));
    // Input mode enlarges the hosted scene to its available width and keeps
    // the bottom (composer and embedded keyboard) in view. Normal mode fits all content.
    if (inputZoom) fitScale = MIN(1.0, CGRectGetWidth(self.contentView.bounds) / MAX(1, sourceSize.width));
    fitScale = MAX(0.01, fitScale);

    if (newlyAttached) [self.contentView addSubview:contextView];
    if (directGestureRecognizer.view != contextView) {
        [directGestureRecognizer.view removeGestureRecognizer:directGestureRecognizer];
        [contextView addGestureRecognizer:directGestureRecognizer];
    }
    contextView.transform = CGAffineTransformIdentity;
    contextView.bounds = CGRectMake(0, 0, sourceSize.width, sourceSize.height);
    CGFloat centerY = CGRectGetMidY(self.contentView.bounds);
    if (inputZoom && sourceSize.height * fitScale > CGRectGetHeight(self.contentView.bounds)) {
        centerY = CGRectGetHeight(self.contentView.bounds) - sourceSize.height * fitScale / 2;
    }
    CGSize viewport = self.contentView.bounds.size;
    if (transformViewport.width > 0 && transformViewport.height > 0 &&
        !CGSizeEqualToSize(transformViewport, viewport)) {
        [self cancelTransformGestures];
        userOffset = CGPointMake(userOffset.x * viewport.width / transformViewport.width,
                                 userOffset.y * viewport.height / transformViewport.height);
    }
    transformViewport = viewport;
    contextBaseScale = fitScale;
    contextBaseCenter = CGPointMake(CGRectGetMidX(self.contentView.bounds), centerY);
    [self applyContextTransform];
    contextView.multipleTouchEnabled = YES;
    contextView.exclusiveTouch = NO;
    if (newlyAttached) {
        contextView.alpha = 0;
        [UIView animateWithDuration:0.25 animations:^{ contextView.alpha = 1; }];
    } else {
        contextView.alpha = 1;
    }
    [self updateDrawerControls];
}

-(void)attemptHostingForGeneration:(NSUInteger)generation{
    if (generation != hostingGeneration || isInvalidated || !presentationAllowed || !self.isOpened || !pinnedBundleId.length) return;

    NSString *frontMostBundleId = [POApplicationHelper frontMostBundleId];
    if ([frontMostBundleId isEqualToString:pinnedBundleId]) {
        hostingInProgress = NO;
        [activityIndicator stopAnimating];
        [self showHostingMessage:@"此应用已在屏幕上打开，暂时无法以浮窗显示。"
                       symbolName:@"rectangle.on.rectangle.slash" generation:generation];
        return;
    }

    ContextHostManager *manager = [ContextHostManager sharedInstance];
    if (!launchRequested) {
        launchRequested = YES;
        [manager launchInBackground:pinnedBundleId];
    }

    UIView *hostView = [manager hostViewForBundleID:pinnedBundleId];
    if (hostView) {
        contextView = hostView;
        [self layoutContextView];
        [activityIndicator stopAnimating];
        hostingInProgress = NO;
        POLog(@"hosting ready %@", pinnedBundleId);
        return;
    }

    hostingAttempts++;
    if (hostingAttempts >= 8) {
        hostingInProgress = NO;
        [activityIndicator stopAnimating];
        [self showHostingMessage:@"应用启动失败，请关闭浮窗后重试。"
                       symbolName:@"exclamationmark.app" generation:generation];
        POLog(@"hosting timed out %@ after %lu attempts", pinnedBundleId, (unsigned long)hostingAttempts);
        return;
    }

    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.75 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf attemptHostingForGeneration:generation];
    });
}

-(void)cleanUpSubviews{
    for (UIView *v in self.contentView.subviews) {
        if (![v isKindOfClass:[UIActivityIndicatorView class]]) {
            [v removeFromSuperview];
        }
    }
}

-(void)endHosting{
    toolsVisible=NO;
    [self hideFloatingKeyboard];
    [keyboardComposer dismiss];
    if (transformEnabled || hostInteractionSaved) [self setTransformEditing:NO];
    [self cancelTransformGestures];
    [directGestureRecognizer.view removeGestureRecognizer:directGestureRecognizer];
    if (contextView) [self saveAppTransform];
    hostingGeneration++;
    hostingInProgress = NO;
    launchRequested = NO;
    hostingAttempts = 0;
    [activityIndicator stopAnimating];
    [contextView.layer removeAllAnimations];
    [contextView removeFromSuperview];
    [[ContextHostManager sharedInstance] stopHostingForBundleID:pinnedBundleId];
    [self cleanUpSubviews];
    for (UIView *v in overlayView.subviews) {
        [v removeFromSuperview];
    }
    contextView = nil;
    [self updateDrawerControls];
    showingCantHost = NO;
}

-(void)showCantHostView{
    [self showHostingMessage:@"此应用已在屏幕上打开，暂时无法以浮窗显示。"
                   symbolName:@"rectangle.on.rectangle.slash" generation:hostingGeneration];
}

-(void)retryHostingIfNeeded{
    if (self.isOpened && pinnedBundleId.length && ![[ContextHostManager sharedInstance] isHostViewHosting:contextView]) [self refreshHosting];
}

-(void)refreshHosting{
    if (isInvalidated || !self.isOpened) return;
    [self endHosting];
    [self beginHosting];
}

-(void)closeAndStopHosting{
    pinGeneration++;
    [self.quickSwitchTableView cancelPresentation];
    [self.expandedSwitchMenu cancelPresentation];
    BOOL wasOpened = self.isOpened;
    suppressHostingUntilClosed = YES;
    self.isOpened = NO;
    if (!wasOpened) [self endHosting];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(autoNubAfterDelay) object:nil];
    [scrollView.layer removeAllAnimations];
    [scrollView setContentOffset:CGPointZero animated:NO];
    suppressHostingUntilClosed = NO;
    self.backgroundView.alpha = 0;
    [self updateHandleVisibility:0];
}

-(void)invalidate{
    if (isInvalidated) return;
    isInvalidated = YES;
    presentationAllowed = NO;
    [self.quickSwitchTableView cancelPresentation];
    [self.expandedSwitchMenu cancelPresentation];
    pinGeneration++;
    suppressHostingUntilClosed = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(autoNubAfterDelay) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(beginHosting) object:nil];
    [self endHosting];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.viewIfLoaded.layer removeAllAnimations];
    [self.scrollView.layer removeAllAnimations];
    [self.handleScrollView.layer removeAllAnimations];
}

-(void)showHostingMessage:(NSString *)message symbolName:(NSString *)symbolName generation:(NSUInteger)generation{
    if (showingCantHost) return;
    showingCantHost = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->isInvalidated || !self.isOpened || generation != self->hostingGeneration || !self.contentView) return;
        CGPoint center = CGPointMake(CGRectGetMidX(self.contentView.bounds), CGRectGetMidY(self.contentView.bounds));
        UIImageView *symbol = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:symbolName]];
        symbol.tintColor = [UIColor secondaryLabelColor];
        symbol.contentMode = UIViewContentModeScaleAspectFit;
        symbol.frame = CGRectMake(0, 0, 96, 96);
        symbol.center = CGPointMake(center.x, center.y - 58);
        [self.contentView addSubview:symbol];

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, MAX(1, CGRectGetWidth(self.contentView.bounds) - 32), 96)];
        label.numberOfLines = 4;
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor secondaryLabelColor];
        label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        label.text = message;
        label.center = CGPointMake(center.x, center.y + 48);
        [self.contentView addSubview:label];

        if ([[POApplicationHelper settings][@"leftHanded"] boolValue]) {
            symbol.transform = CGAffineTransformMakeScale(-1, 1);
            label.transform = CGAffineTransformMakeScale(-1, 1);
        }
    });
}


@end
