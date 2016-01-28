//
//  Checkbox.m
//  XMLTest
//
//  Created by Karl on 2012-12-21.
//
//

#import "Checkbox.h"
#import "FoldDownMenu.h"

@implementation Checkbox

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(void)setChecked:(BOOL)chkd
{
    self.selected = chkd;
}

@end
