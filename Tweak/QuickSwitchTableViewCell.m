//
//  QuickSwitchTableViewCell.m
//  PullOverPro
//
//  Created by Will Smillie on 4/8/19.
//

#import "QuickSwitchTableViewCell.h"
#import "POApplicationHelper.h"

@implementation QuickSwitchTableViewCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.imgView = [[UIImageView alloc] initWithFrame:CGRectMake(8, 8, 18, 18)];
        self.imgView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:self.imgView];
        self.appNameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.appNameLabel.font = [UIFont systemFontOfSize:15];
        self.appNameLabel.textColor = [UIColor labelColor];
        self.appNameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.contentView addSubview:self.appNameLabel];
        
        if (@available(iOS 13, *)){
            self.backgroundColor = [UIColor performSelector:@selector(secondarySystemBackgroundColor)];
        }else{
            self.backgroundColor = [[POApplicationHelper settings][@"darkHandle"] boolValue] ? [UIColor darkGrayColor] : [UIColor whiteColor];
        }

        
        if ([[POApplicationHelper settings][@"leftHanded"] boolValue]){
            self.imgView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
        }
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.appNameLabel.frame = CGRectMake(50, 0, MAX(0, self.contentView.bounds.size.width - 62), self.contentView.bounds.size.height);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.layer removeAllAnimations];
    self.transform = CGAffineTransformIdentity;
    self.layer.zPosition = 0;
    self.imgView.image = nil;
    self.appNameLabel.text = nil;
}

@end
