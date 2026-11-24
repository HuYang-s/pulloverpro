#import "ContextHostManager.h"
#import "POLog.h"
#import "POApplicationHelper.h"

static NSString *const kPresenterID = @"com.johndie.pulloverpro";

@implementation ContextHostManager {
    NSString *_bundleId;
    __weak FBScene *_scene;
    _UIScenePresenter *_presenter;
    BOOL _weForegrounded;   // only send the app back if we brought it forward
}

+ (instancetype)sharedInstance {
    static ContextHostManager *shared;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ shared = [self new]; });
    return shared;
}

// The app's main scene. Its identifier looks like "sceneID:<bundle id>-default";
// prefer that one when an app has several scenes.
- (FBScene *)sceneForBundleId:(NSString *)bundleId {
    Class managerClass = NSClassFromString(@"FBSceneManager");
    if (![bundleId isKindOfClass:[NSString class]] || bundleId.length == 0 ||
        ![managerClass respondsToSelector:@selector(sharedInstance)]) return nil;
    FBSceneManager *manager = [managerClass sharedInstance];
    if (![manager respondsToSelector:@selector(scenesPassingTest:)]) return nil;

    NSSet *scenes = [manager scenesPassingTest:^BOOL(FBScene *scene) {
        id process = [scene respondsToSelector:@selector(clientProcess)] ? scene.clientProcess : nil;
        NSString *identifier = [process respondsToSelector:@selector(bundleIdentifier)] ? [process bundleIdentifier] : nil;
        return [identifier isEqualToString:bundleId];
    }];
    if (![scenes isKindOfClass:[NSSet class]]) return nil;
    FBScene *best = nil;
    for (FBScene *scene in scenes) {
        if ([scene respondsToSelector:@selector(identifier)] && [scene.identifier hasSuffix:@"-default"]) return scene;
        if (!best) best = scene;
    }
    return best;
}

- (void)openApplication:(NSString *)bundleId suspended:(BOOL)suspended {
    Class service = NSClassFromString(@"FBSSystemService");
    if (!bundleId || ![service respondsToSelector:@selector(sharedService)]) return;
    NSDictionary *options = suspended ? @{@"__ActivateSuspended": @YES} : @{};
    id instance = [service sharedService];
    if (![instance respondsToSelector:@selector(openApplication:options:withResult:)]) return;
    [instance openApplication:bundleId options:options withResult:^(NSError *error) {
        POLog(@"open %@ suspended=%d -> %@", bundleId, suspended, error ?: @"ok");
    }];
}

- (void)launchInBackground:(NSString *)bundleId {
    if ([self sceneForBundleId:bundleId]) return;
    [self openApplication:bundleId suspended:YES];
}

- (void)openFullScreen:(NSString *)bundleId {
    [self openApplication:bundleId suspended:NO];
}

- (BOOL)setScene:(FBScene *)scene foreground:(BOOL)foreground {
    if (![scene respondsToSelector:@selector(updateSettingsWithBlock:)]) return NO;
    [scene updateSettingsWithBlock:^(UIMutableApplicationSceneSettings *settings) {
        settings.foreground = foreground;
    }];
    return YES;
}

- (UIView *)hostViewForBundleID:(NSString *)bundleId {
    if (![bundleId isKindOfClass:[NSString class]] || bundleId.length == 0) return nil;

    if (_presenter && [_bundleId isEqualToString:bundleId] && _scene && _scene == [self sceneForBundleId:bundleId] && [_presenter respondsToSelector:@selector(isInvalidated)] && !_presenter.invalidated && [_presenter respondsToSelector:@selector(presentationView)]) {
        UIView *existingView = _presenter.presentationView;
        if (existingView) return existingView;
        [self stopHostingForBundleID:bundleId];
    }
    if (_bundleId) [self stopHostingForBundleID:_bundleId];

    FBScene *scene = [self sceneForBundleId:bundleId];
    POLog(@"host %@: scene=%@", bundleId, scene);
    if (!scene || ![scene respondsToSelector:@selector(uiPresentationManager)]) return nil;

    UIScenePresentationManager *presentationManager = scene.uiPresentationManager;
    if (![presentationManager respondsToSelector:@selector(createPresenterWithIdentifier:)]) return nil;

    if (![scene respondsToSelector:@selector(settings)] || ![scene.settings respondsToSelector:@selector(isForeground)]) return nil;
    BOOL wasForeground = scene.settings.foreground;
    BOOL changedForeground = !wasForeground;
    if (changedForeground && ![self setScene:scene foreground:YES]) return nil;

    _UIScenePresenter *presenter = [presentationManager createPresenterWithIdentifier:kPresenterID];
    if (!presenter) {
        if (changedForeground && ![[POApplicationHelper frontMostBundleId] isEqualToString:bundleId]) [self setScene:scene foreground:NO];
        return nil;
    }

    if ([presenter respondsToSelector:@selector(modifyPresentationContext:)]) {
        [presenter modifyPresentationContext:^(UIMutableScenePresentationContext *context) {
            context.appearanceStyle = 2;
            context.backgroundColorWhileNotHosting = UIColor.clearColor;
        }];
    }
    if ([presenter respondsToSelector:@selector(activate)]) [presenter activate];

    UIView *presentationView = [presenter respondsToSelector:@selector(presentationView)] ? presenter.presentationView : nil;
    BOOL invalidated = [presenter respondsToSelector:@selector(isInvalidated)] && presenter.invalidated;
    if (!presentationView || invalidated) {
        if ([presenter respondsToSelector:@selector(deactivate)]) [presenter deactivate];
        if ([presenter respondsToSelector:@selector(invalidate)]) [presenter invalidate];
        if (changedForeground && ![[POApplicationHelper frontMostBundleId] isEqualToString:bundleId]) [self setScene:scene foreground:NO];
        return nil;
    }

    _weForegrounded = changedForeground;
    POLog(@"host %@: presenter=%@ view=%@ wasForeground=%d", bundleId, presenter, presentationView, wasForeground);

    _bundleId = [bundleId copy];
    _scene = scene;
    _presenter = presenter;
    return presentationView;
}

- (void)stopHostingForBundleID:(NSString *)bundleId {
    if (bundleId.length && _bundleId.length && ![_bundleId isEqualToString:bundleId]) return;

    _UIScenePresenter *presenter = _presenter;
    FBScene *scene = _scene;
    NSString *hostedBundleId = _bundleId;
    BOOL shouldRestoreForeground = _weForegrounded;

    if ([presenter respondsToSelector:@selector(deactivate)]) [presenter deactivate];
    if ([presenter respondsToSelector:@selector(invalidate)]) [presenter invalidate];
    _presenter = nil;

    _scene = nil;
    _bundleId = nil;
    _weForegrounded = NO;

    NSString *frontMostBundleId = [POApplicationHelper frontMostBundleId];
    if (scene && shouldRestoreForeground &&
        ![frontMostBundleId isEqualToString:hostedBundleId] && [scene respondsToSelector:@selector(settings)] && [scene.settings respondsToSelector:@selector(isForeground)] && scene.settings.foreground) {
        [self setScene:scene foreground:NO];
    }
}

- (BOOL)isHostViewHosting:(UIView *)hostView {
    return hostView && _scene && _presenter && [_presenter respondsToSelector:@selector(isInvalidated)] && !_presenter.invalidated && [_presenter respondsToSelector:@selector(presentationView)] && hostView == _presenter.presentationView;
}

@end
