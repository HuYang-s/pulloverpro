#import <UIKit/UIKit.h>

// An independent native UIKit window, never inside the scaled app presenter.
// Text stays in memory until the user explicitly chooses Copy and Return.
@interface POKeyboardComposer : NSObject
@property(nonatomic,readonly,getter=isPresented) BOOL presented;
- (BOOL)presentFromWindow:(UIWindow *)host completion:(void (^)(BOOL copied))completion;
- (void)dismiss;
@end
