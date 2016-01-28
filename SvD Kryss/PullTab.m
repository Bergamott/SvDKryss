//
//  PullTab.m
//  XMLTest
//
//  Created by Karl on 2012-12-21.
//
//

#import "PullTab.h"
#import "FoldDownMenu.h"

@implementation PullTab

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

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [[event allTouches] anyObject];
	CGPoint location = [touch locationInView:self.superview];
    downX = location.x;
    startX = self.frame.origin.x;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [[event allTouches] anyObject];
	CGPoint location = [touch locationInView:self.superview];
    float newX = startX + location.x - downX;
    if (newX < 0)
        newX = 0;
    else if (newX > owner.frame.size.width-self.frame.size.width)
        newX = owner.frame.size.width-self.frame.size.width;
    self.frame = CGRectMake(newX, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [[event allTouches] anyObject];
	CGPoint location = [touch locationInView:self.superview];
    float upX = location.x;
    if ((upX - downX)*(upX - downX) < 200)
    {
        buttonHighlighted = !buttonHighlighted;
        button.highlighted = buttonHighlighted;
        if (buttonHighlighted)
        {
            [owner downFlapPressed];
        }
        else
        {
            [owner upFlapPressed];
        }
    }
}

-(void)resetToHidden
{
    buttonHighlighted = FALSE;
    button.highlighted = FALSE;
}

@end
