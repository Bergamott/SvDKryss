//
//  FakeSegmentedControl.m
//  SvD Kryss
//
//  Created by Karl on 2013-02-17.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import "FakeSegmentedControl.h"

@implementation FakeSegmentedControl

@synthesize selectedSegmentIndex;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


-(void)setup
{    
    [self markSegment:0];
}

-(void)markSegment:(int)segNum
{
    selectedSegmentIndex = segNum;
    background0.highlighted = (segNum == 0);
    background1.highlighted = (segNum == 1);
    background2.highlighted = (segNum == 2);
    label0.highlighted = (segNum == 0);
    label1.highlighted = (segNum == 1);
    label2.highlighted = (segNum == 2);
}

-(IBAction)segmentClicked:(id)sender
{
    [self markSegment:((UIButton*)sender).tag];
    
    [owner fakeSegmentChanged:self];
}

@end
