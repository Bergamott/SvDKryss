//
//  SuecaRegularLabel.m
//  svdkorsord
//
//  Created by Karl on 2013-02-21.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import "SuecaRegularLabel.h"

@implementation SuecaRegularLabel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.font = [UIFont fontWithName:@"SuecaWebSlab-Regular" size:self.font.pointSize];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end