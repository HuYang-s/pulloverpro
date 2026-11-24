//
//  PullOverViewController.h
//  PullOverPro
//
//  Created by Will Smillie on 4/8/19.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>


#import "BaseScrollView.h"
#import "POHandle.h"
#import "QuickSwitchTableView.h"
#import "ContextHostManager.h"

#import "headers.h"


@interface PullOverViewController : UIViewController <UIScrollViewDelegate, UIGestureRecognizerDelegate, POHandleDelegate, QuickSwitchSelectionDelegate>

-(void)open;
-(void)close;
-(void)endHosting;
-(void)refreshHosting;
-(void)closeAndStopHosting;
-(void)invalidate;
-(void)setPresentationAllowed:(BOOL)allowed;
-(void)updateHandleVisibility:(float)progress;
@property (nonatomic) BOOL isOpened;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIScrollView *handleScrollView;
@property (nonatomic, strong) UIView *backgroundView;

@property (nonatomic, strong) POHandle *handle;
@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) QuickSwitchTableView *quickSwitchTableView;
@property (nonatomic, strong, readonly) QuickSwitchTableView *expandedSwitchMenu;
@property (nonatomic, strong, readonly) UIView *drawerControls;


@end

