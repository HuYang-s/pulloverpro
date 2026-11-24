//
//  POApplicationHelper.m
//  PullOverPro
//
//  Created by Will Smillie on 4/8/19.
//  Rootless port (iOS 15-16): Jond-ie.
//

#import "POApplicationHelper.h"
#import "ContextInterfaces.h"
#import "POLog.h"
#import <math.h>

@interface UIImage (POPrivate)
+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier format:(int)format scale:(CGFloat)scale;
@end

@implementation POApplicationHelper

// Recents live on SBMainSwitcherViewController on iOS 15 and moved to
// SBMainSwitcherControllerCoordinator on iOS 16.
+(NSArray *)recentAppLayouts{
    for (NSString *name in @[@"SBMainSwitcherControllerCoordinator", @"SBMainSwitcherViewController"]) {
        Class cls = NSClassFromString(name);
        if (![cls respondsToSelector:@selector(sharedInstance)]) continue;
        id switcher = [cls sharedInstance];
        if ([switcher respondsToSelector:@selector(recentAppLayouts)]) {
            NSArray *layouts = nil;
            @try {
                id value = [switcher valueForKey:@"recentAppLayouts"];
                if ([value isKindOfClass:[NSArray class]]) layouts = [value copy];
            } @catch (NSException *exception) {
                POLog(@"recents from %@ failed: %@", name, exception);
            }
            if (!layouts) continue;
            POLog(@"recents from %@: %lu layouts", name, (unsigned long)layouts.count);
            return layouts;
        }
    }
    POLog(@"recents: no switcher class answered");
    return @[];
}

+(NSArray *)recentAppsWithCount:(int)count{
    NSMutableArray *objects = [NSMutableArray new];
    count = MIN(10, MAX(1, count));
    for (id layout in [self recentAppLayouts]) {
        if ((int)objects.count >= count) break;
        NSString *bundleId = nil;
        @try {
            bundleId = [[[layout valueForKey:@"allItems"] valueForKey:@"bundleIdentifier"] firstObject];
        } @catch (NSException *e) {}
        if ([bundleId isKindOfClass:[NSString class]] && ![objects containsObject:bundleId]) {
            [objects addObject:bundleId];
        }
    }
    POLog(@"recent apps: %@", objects);
    return objects;
}

+(UIImage *)imageForBundleId:(NSString *)bundleId{
    if (![bundleId isKindOfClass:[NSString class]] || bundleId.length == 0) return nil;
    static NSCache<NSString *, UIImage *> *iconCache;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        iconCache = [NSCache new];
        iconCache.countLimit = 96;
    });

    UIImage *cachedImage = [iconCache objectForKey:bundleId];
    if (cachedImage) return cachedImage;

    SEL iconSelector = @selector(_applicationIconImageForBundleIdentifier:format:scale:);
    if (![UIImage respondsToSelector:iconSelector]) return nil;
    // format 2 = home screen icon size (60 pt)
    UIImage *image = nil;
    @try {
        image = [UIImage _applicationIconImageForBundleIdentifier:bundleId format:2 scale:[UIScreen mainScreen].scale];
    } @catch (NSException *exception) {
        POLog(@"icon lookup failed for %@: %@", bundleId, exception);
    }
    if (image) [iconCache setObject:image forKey:bundleId];
    return image;
}

static NSString *POTrackedFrontMost;
static BOOL POHasTrackedFrontMost;

void POSetFrontMostBundleId(NSString *bundleId){
    POTrackedFrontMost = [bundleId copy];
    POHasTrackedFrontMost = YES;
}

+(NSString *)frontMostBundleId{
    if (POHasTrackedFrontMost) return POTrackedFrontMost;
    UIApplication *sb = [UIApplication sharedApplication];
    if (![sb respondsToSelector:@selector(_accessibilityFrontMostApplication)]) return nil;
    id app = [sb _accessibilityFrontMostApplication];
    return [app respondsToSelector:@selector(bundleIdentifier)] ? [app bundleIdentifier] : nil;
}

static NSDictionary *POCachedSettings;

+(NSDictionary *)defaultSettings{
    return @{
        @"enabled": @YES,
        @"hideInLandscape": @NO,
        @"landscapeTouchThrough": @YES,
        @"favorites": @[],
        @"recentAppsCount": @5,
        @"quickswitchScale": @1.75f,
        @"style": @"Recent Apps",
        @"leftHanded": @NO,
        @"darkHandle": @NO,
        @"hideLabels": @NO,
        @"hapticFeedback": @YES,
        @"closeOnHome": @YES,
        @"hideHandle": @NO,
        @"keyboardAvoiding": @NO,
        @"externalKeyboard": @NO,
        @"autoNub": @NO,
        @"autoNub-time": @5,
    };
}

// Defaults merged with whatever the settings page saved (CFPreferences, so
// cfprefsd's cache is always current; reading the plist file can be stale).
+(NSDictionary *)settings{
    @synchronized (self) {
        if (!POCachedSettings) {
            CFStringRef domain = (__bridge CFStringRef)PODomain;
            CFPreferencesAppSynchronize(domain);
            NSMutableDictionary *merged = [[self defaultSettings] mutableCopy];
            CFArrayRef keys = CFPreferencesCopyKeyList(domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
            if (keys) {
                id saved = CFBridgingRelease(CFPreferencesCopyMultiple(keys, domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
                if ([saved isKindOfClass:[NSDictionary class]]) [merged addEntriesFromDictionary:saved];
                CFRelease(keys);
            }

            NSDictionary *defaults = [self defaultSettings];
            NSArray *booleanKeys = @[@"enabled", @"hideInLandscape", @"landscapeTouchThrough", @"leftHanded", @"darkHandle",
                                     @"hideLabels", @"hapticFeedback", @"closeOnHome", @"hideHandle",
                                     @"keyboardAvoiding", @"externalKeyboard", @"autoNub"];
            for (NSString *key in booleanKeys) {
                id value = merged[key];
                merged[key] = [value isKindOfClass:[NSNumber class]] ? @([value boolValue]) : defaults[key];
            }

            id recentCount = merged[@"recentAppsCount"];
            NSInteger normalizedRecentCount = [recentCount isKindOfClass:[NSNumber class]] ? [recentCount integerValue] : [defaults[@"recentAppsCount"] integerValue];
            merged[@"recentAppsCount"] = @(MIN(10, MAX(1, normalizedRecentCount)));

            id quickSwitchScale = merged[@"quickswitchScale"];
            double normalizedScale = [quickSwitchScale isKindOfClass:[NSNumber class]] ? [quickSwitchScale doubleValue] : [defaults[@"quickswitchScale"] doubleValue];
            if (!isfinite(normalizedScale)) normalizedScale = [defaults[@"quickswitchScale"] doubleValue];
            merged[@"quickswitchScale"] = @(MIN(2.5, MAX(1.0, normalizedScale)));

            id autoNubTime = merged[@"autoNub-time"];
            NSInteger normalizedAutoNubTime = [autoNubTime isKindOfClass:[NSNumber class]] ? [autoNubTime integerValue] : [defaults[@"autoNub-time"] integerValue];
            merged[@"autoNub-time"] = @(MIN(30, MAX(1, normalizedAutoNubTime)));

            NSString *style = merged[@"style"];
            if (![style isKindOfClass:[NSString class]] ||
                (![style isEqualToString:@"Recent Apps"] && ![style isEqualToString:@"Favorites"])) {
                merged[@"style"] = defaults[@"style"];
            }

            NSMutableArray *favorites = [NSMutableArray array];
            id savedFavorites = merged[@"favorites"];
            if ([savedFavorites isKindOfClass:[NSArray class]]) {
                for (id candidate in savedFavorites) {
                    if (![candidate isKindOfClass:[NSString class]]) continue;
                    NSString *bundleId = [candidate stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    if (bundleId.length == 0 || bundleId.length > 255 ||
                        [bundleId rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location != NSNotFound ||
                        [favorites containsObject:bundleId]) continue;
                    [favorites addObject:bundleId];
                }
            }
            merged[@"favorites"] = [favorites copy];
            POCachedSettings = [merged copy];
        }
        return POCachedSettings;
    }
}

+(void)reloadSettings{
    @synchronized (self) { POCachedSettings = nil; }
}

+(NSUserDefaults *)state{
    static NSUserDefaults *state;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ state = [[NSUserDefaults alloc] initWithSuiteName:POStateDomain]; });
    return state;
}

@end
