//
//  QuickSwitchTableView.m
//  PullOverPro
//
//  Created by Will Smillie on 4/8/19.
//

#import "QuickSwitchTableView.h"
#import "POLog.h"
#import <AudioToolbox/AudioToolbox.h>
#import <CoreGraphics/CoreGraphics.h>

#import "PullOverWindow.h"

@interface QuickSwitchTableView (){
    NSDictionary *settings;
    NSMutableArray *items;
    
    NSIndexPath *lastHoveredIndexPath;
    UITableViewCell *lastCellToAnimate;
    UITableViewCell *thisCellToAnimate;
    SBApplication *draggingApp;
    
    CGFloat scale;
    BOOL isPresented;
    NSUInteger presentationGeneration;
}

- (BOOL)isValidIndexPath:(NSIndexPath *)indexPath;
- (SBApplication *)applicationForBundleId:(NSString *)bundleId;

@end

@implementation QuickSwitchTableView

-(instancetype)initWithDarkMode:(BOOL)darkMode{
    if (self = [super init]) {
        [self registerClass:[QuickSwitchTableViewCell class] forCellReuseIdentifier:@"QuickSwitchCell"];
        self.alpha = 0;
        self.clipsToBounds = NO;
        [self.layer setShadowColor:[UIColor blackColor].CGColor];
        [self.layer setShadowOpacity:0.4];
        [self.layer setShadowRadius:4.0];
        [self.layer setShadowOffset:CGSizeMake(0, 0)];
        self.separatorColor = [UIColor clearColor];
        self.darkMode = darkMode;
        self.rowHeight = 34;
        self.scrollEnabled = YES;
        self.alwaysBounceVertical = NO;

        self.delegate = self;
        self.dataSource = self;
        
        self.backgroundColor = self.darkMode?[UIColor darkGrayColor]:[UIColor whiteColor];
        self.layer.cornerRadius = 34/2;
        
        
        if (@available(iOS 13, *)){
            self.backgroundColor = [UIColor performSelector:@selector(secondarySystemBackgroundColor)];
        }else{
            self.backgroundColor = [[POApplicationHelper settings][@"darkHandle"] boolValue] ? [UIColor darkGrayColor] : [UIColor whiteColor];
        }

        
        [self refresh];
    }
    return self;
}

-(void)refresh{
    settings = [POApplicationHelper settings] ?: @{};
    items = [NSMutableArray array];

    CGFloat requestedScale = [settings[@"quickswitchScale"] respondsToSelector:@selector(floatValue)]
        ? [settings[@"quickswitchScale"] floatValue] : 1.75;
    scale = MIN(2.5, MAX(1.0, requestedScale));

    NSArray *sourceItems = nil;
    if ([settings[@"style"] isEqualToString:@"Recent Apps"]) {
        NSInteger count = [settings[@"recentAppsCount"] respondsToSelector:@selector(integerValue)]
            ? [settings[@"recentAppsCount"] integerValue] : 5;
        sourceItems = [POApplicationHelper recentAppsWithCount:(int)MIN(10, MAX(1, count))];
    } else if ([settings[@"style"] isEqualToString:@"Favorites"]) {
        sourceItems = [settings[@"favorites"] isKindOfClass:[NSArray class]] ? settings[@"favorites"] : @[];
    }

    for (id candidate in sourceItems) {
        if (![candidate isKindOfClass:[NSString class]] || [candidate length] == 0) continue;
        if (![items containsObject:candidate]) [items addObject:candidate];
    }

    POLog(@"quickswitch style=%@ items=%@", settings[@"style"], items);
    [self reloadData];
}

- (BOOL)isValidIndexPath:(NSIndexPath *)indexPath {
    return indexPath && indexPath.section == 0 && indexPath.row >= 0 && indexPath.row < (NSInteger)items.count;
}

- (SBApplication *)applicationForBundleId:(NSString *)bundleId {
    if (![bundleId isKindOfClass:[NSString class]] || bundleId.length == 0) return nil;
    Class controllerClass = objc_getClass("SBApplicationController");
    if (![controllerClass respondsToSelector:@selector(sharedInstance)]) return nil;
    id controller = [controllerClass sharedInstance];
    if (![controller respondsToSelector:@selector(applicationWithBundleIdentifier:)]) return nil;
    return [controller applicationWithBundleIdentifier:bundleId];
}


-(void)presentFromHandle:(UIView *)handle withRecognizer:(UILongPressGestureRecognizer *)recognizer{
    CGPoint p = [recognizer locationInView:self];
    NSIndexPath *indexPath = [self indexPathForRowAtPoint:p];

    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self refresh];
        if (items.count == 0) return;

        if ([settings[@"hapticFeedback"] boolValue]) AudioServicesPlaySystemSound(1519);

        CGFloat rowHeight = 34;
        UIWindow *window = self.window ?: handle.window;
        CGFloat screenHeight = window ? CGRectGetHeight(window.bounds) : CGRectGetHeight([UIScreen mainScreen].bounds);
        CGFloat safeHeight = screenHeight - (window ? window.safeAreaInsets.top + window.safeAreaInsets.bottom : 0);
        CGFloat height = MIN(rowHeight * items.count, MAX(rowHeight, safeHeight - 24));

        self.frame = CGRectMake(handle.frame.origin.x, handle.frame.origin.y, handle.frame.size.width, height);

        CGRect tableFrameInWindow = self.window ? [self.superview convertRect:self.frame toView:self.window] : self.frame;
        if (CGRectGetMaxY(tableFrameInWindow) > screenHeight - (window ? window.safeAreaInsets.bottom : 0)) {
            self.frame = CGRectMake(handle.frame.origin.x, (handle.frame.origin.y-height)+handle.frame.size.height, handle.frame.size.width, height);
            items = [[[items reverseObjectEnumerator] allObjects] mutableCopy];
            [self reloadData];
        }

        lastHoveredIndexPath = nil;
        lastCellToAnimate = nil;
        thisCellToAnimate = nil;
        draggingApp = nil;
        isPresented = YES;
        presentationGeneration++;

        CGRect placed = [self.superview convertRect:self.frame toView:window];
        CGFloat minimumY = window ? window.safeAreaInsets.top : 0;
        CGFloat maximumY = screenHeight - (window ? window.safeAreaInsets.bottom : 0);
        CGFloat shift = MAX(minimumY - CGRectGetMinY(placed), MIN(0, maximumY - CGRectGetMaxY(placed)));
        CGRect frame = self.frame;
        frame.origin.y += shift;
        self.frame = frame;
        [self setContentOffset:CGPointZero animated:NO];
        [self layoutIfNeeded];
        NSIndexPath *initial = [self indexPathForRowAtPoint:[recognizer locationInView:self]];
        if ([self isValidIndexPath:initial]) {
            lastHoveredIndexPath = initial;
            thisCellToAnimate = [self cellForRowAtIndexPath:initial];
            [self animateZoomforCell:thisCellToAnimate];
        }
        [self present];
        [self.selectionDelegate quickSwitchTableViewWillAppear:self];
        
    }else if (recognizer.state == UIGestureRecognizerStateChanged){
        if (!isPresented) return;
        BOOL draggedOutward = p.x < CGRectGetMinX(self.bounds);
        if (!draggedOutward && CGRectGetHeight(self.bounds) < self.contentSize.height) {
            CGFloat offset = self.contentOffset.y;
            if (p.y < CGRectGetMinY(self.bounds) + 12) offset -= 12;
            else if (p.y > CGRectGetMaxY(self.bounds) - 12) offset += 12;
            offset = MIN(MAX(0, offset), MAX(0, self.contentSize.height - CGRectGetHeight(self.bounds)));
            [self setContentOffset:CGPointMake(0, offset) animated:NO];
            p = [recognizer locationInView:self];
            indexPath = [self indexPathForRowAtPoint:p];
        }

        if ([self isValidIndexPath:indexPath] && CGRectContainsPoint(self.bounds, p)) {
            if (draggingApp) {
                [self.selectionDelegate draggingDidEnterBoundsOfQuickSwitchTableView:self];
                draggingApp = nil;
            }

            if (![indexPath isEqual:lastHoveredIndexPath]) {
                if ([settings[@"hapticFeedback"] boolValue]) AudioServicesPlaySystemSound(1519);
                lastCellToAnimate = [self cellForRowAtIndexPath:lastHoveredIndexPath];
                thisCellToAnimate = [self cellForRowAtIndexPath:indexPath];
                [self animateZoomforCellremove:lastCellToAnimate];
                [self animateZoomforCell:thisCellToAnimate];
                lastHoveredIndexPath = indexPath;
            }
        } else if (draggedOutward && [self isValidIndexPath:lastHoveredIndexPath]) {
            if (!draggingApp) {
                draggingApp = [self applicationForBundleId:items[lastHoveredIndexPath.row]];
                [self animateZoomforCellremove:thisCellToAnimate];
                [self animateZoomforCellremove:lastCellToAnimate];
            }
            if (draggingApp) {
                [self.selectionDelegate quickSwitchTableView:self draggingDidChangeForQuickSwitchItem:draggingApp withPoint:p];
            }
        }
    }else if (recognizer.state == UIGestureRecognizerStateEnded){
        if (!isPresented) return;
        if (draggingApp) {
            [self.selectionDelegate quickSwitchTableView:self didDropApp:draggingApp atPoint:p];
        } else if ([self isValidIndexPath:indexPath] && CGRectContainsPoint(self.bounds, p)) {
            [self.selectionDelegate quickSwitchTableView:self didSelectBundleId:items[indexPath.row]];
        } else if (lastHoveredIndexPath) {
            [self.selectionDelegate draggingDidEnterBoundsOfQuickSwitchTableView:self];
        }
        [self end];
    }else{
        if (draggingApp) [self.selectionDelegate draggingDidEnterBoundsOfQuickSwitchTableView:self];
        [self end];
    }
}


#pragma mark — TableView

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return items.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 34;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"QuickSwitchCell";
    QuickSwitchTableViewCell *cell = [self dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[QuickSwitchTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if (indexPath.row < 0 || indexPath.row >= (NSInteger)items.count) return cell;
    [cell.imgView setImage:[POApplicationHelper imageForBundleId:items[indexPath.row]]];
    cell.imgView.frame = CGRectMake(8, 8, 18, 18);
    cell.layer.cornerRadius = 34/2;
    cell.clipsToBounds = YES;
    
    return cell;
}

- (NSMutableArray *)reversedArray:(NSMutableArray *)array {
    if ([array count] <= 1)
        return array;
    NSUInteger i = 0;
    NSUInteger j = [array count] - 1;
    while (i < j) {
        [array exchangeObjectAtIndex:i
                  withObjectAtIndex:j];
        
        i++;
        j--;
    }
    return array;
}




#pragma mark - Animations

-(void)present{
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 1;
    }];
}

-(BOOL)isPresented {
    return isPresented;
}

-(void)cancelPresentation {
    if (!isPresented && self.alpha == 0) return;
    ++presentationGeneration;
    isPresented = NO;
    [self.layer removeAllAnimations];
    for (UITableViewCell *cell in self.visibleCells) {
        [cell.layer removeAllAnimations];
        cell.transform = CGAffineTransformIdentity;
        cell.layer.zPosition = 0;
    }
    lastHoveredIndexPath = nil;
    lastCellToAnimate = nil;
    thisCellToAnimate = nil;
    draggingApp = nil;
    self.alpha = 0;
    [self.selectionDelegate quickSwitchTableViewDidDisappear:self];
}

-(void)end{
    if (!isPresented) return;
    isPresented = NO;
    NSUInteger generation = ++presentationGeneration;
    [self animateZoomforCellremove:thisCellToAnimate];
    [self animateZoomforCellremove:lastCellToAnimate];
    lastHoveredIndexPath = nil;
    lastCellToAnimate = nil;
    thisCellToAnimate = nil;
    draggingApp = nil;
    [self.layer removeAllAnimations];
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        if (generation == presentationGeneration) {
            [self.selectionDelegate quickSwitchTableViewDidDisappear:self];
        }
    }];
}

-(void)animateZoomforCell:(UITableViewCell*)zoomCell {
    if (!zoomCell) return;
    zoomCell.layer.zPosition = 3;
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState animations:^{
        zoomCell.transform = CGAffineTransformMakeScale(scale,scale);
    }completion:^(BOOL finished){}];
}

-(void)animateZoomforCellremove:(UITableViewCell*)zoomCell {
    if (!zoomCell) return;
    zoomCell.layer.zPosition = 2;
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState animations:^{
        zoomCell.transform = CGAffineTransformMakeScale(1.0,1.0);
    }completion:^(BOOL finished){}];
}


@end
