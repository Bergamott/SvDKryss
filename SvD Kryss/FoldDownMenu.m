//
//  FoldDownMenu.m
//  XMLTest
//
//  Created by Karl on 2012-12-20.
//
//

#import "FoldDownMenu.h"
#import "Checkbox.h"
#import "PullTab.h"

#define HELP_SEGMENT 1
#define COMPETITION_SEGMENT 2

@implementation FoldDownMenu

@synthesize helpView;
@synthesize settingsView;
@synthesize competitionView;

@synthesize myViews;
@synthesize mySegment;
@synthesize pullDown;
@synthesize bottomEdge;

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

-(void)initiate
{
    myViews = [[NSArray alloc] initWithObjects:settingsView,helpView,competitionView, nil];
    [self showViewNumber:0 animated:FALSE];
    [self hideMenuAnimated:FALSE];
    [pullDown resetToHidden];
}

-(void)showViewNumber:(int)num animated:(BOOL)anm;
{
    for (int i=0;i<[myViews count];i++)
    {
        UIView *tmpV = [myViews objectAtIndex:i];
        tmpV.hidden = (i!=num);
    }
    float h = mySegment.frame.origin.y + mySegment.frame.size.height +
    ((UIView*)[myViews objectAtIndex:num]).frame.size.height;
    if (anm)
    {
        [UIView animateWithDuration:0.2 animations:^{
            self.frame = CGRectMake(0, 0, self.frame.size.width, h);
            pullDown.frame = CGRectMake(pullDown.frame.origin.x, h-bottomEdge.frame.size.height, pullDown.frame.size.width, pullDown.frame.size.height);
        }];
    }
    else
    {
        self.frame = CGRectMake(0, 0, self.frame.size.width, h);
        pullDown.frame = CGRectMake(pullDown.frame.origin.x, h-bottomEdge.frame.size.height, pullDown.frame.size.width, pullDown.frame.size.height);
    }
}

-(void)hideMenuAnimated:(BOOL)anm
{
    if (anm)
    {
        [UIView animateWithDuration:0.4 animations:^{
            self.frame = CGRectMake(0,-self.frame.size.height,self.frame.size.width,self.frame.size.height);
            pullDown.frame = CGRectMake(pullDown.frame.origin.x, -bottomEdge.frame.size.height, pullDown.frame.size.width, pullDown.frame.size.height);
        }];
    }
    else
    {
        self.frame = CGRectMake(0,-self.frame.size.height,self.frame.size.width,self.frame.size.height);
        pullDown.frame = CGRectMake(pullDown.frame.origin.x, -bottomEdge.frame.size.height, pullDown.frame.size.width, pullDown.frame.size.height);
    }
}

-(void)showMenuAnimated:(BOOL)anm
{
    if (anm)
    {
        [UIView animateWithDuration:0.4 animations:^{
            self.frame = CGRectMake(0,0,self.frame.size.width,self.frame.size.height);
            pullDown.frame = CGRectMake(pullDown.frame.origin.x, self.frame.size.height-bottomEdge.frame.size.height, pullDown.frame.size.width, pullDown.frame.size.height);
        }];
    }
    else
    {
        self.frame = CGRectMake(0,0,self.frame.size.width,self.frame.size.height);
        pullDown.frame = CGRectMake(pullDown.frame.origin.x, self.frame.size.height-bottomEdge.frame.size.height, pullDown.frame.size.width, pullDown.frame.size.height);
    }
}

-(void)downFlapPressed
{
    [self showMenuAnimated:TRUE];
}
-(void)upFlapPressed
{
    [self hideMenuAnimated:TRUE];
}

-(IBAction)didChangeSegmentControl:(id)sender
{
    UISegmentedControl *seg = (UISegmentedControl*)sender;
    [self showViewNumber:seg.selectedSegmentIndex animated:TRUE];
}

-(IBAction)toggleCheckbox:(id)sender
{
    Checkbox *tmpC = (Checkbox*)sender;
    tmpC.selected = !tmpC.selected;
}

-(void)enableHelp:(BOOL)active
{
    [mySegment setEnabled:active forSegmentAtIndex:HELP_SEGMENT];
}

-(void)activateMarker:(BOOL)act
{
    markerButton.selected = act;
}

-(void)activatePencil:(BOOL)act
{
    pencilButton.selected = act;
}

- (void)dealloc {
    [super dealloc];
	[helpView release];
	[settingsView release];
	[competitionView release];
    
    [myViews release];
    [mySegment release];
    [pullDown release];
    [bottomEdge release];

}

@end
