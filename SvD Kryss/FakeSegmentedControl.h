//
//  FakeSegmentedControl.h
//  SvD Kryss
//
//  Created by Karl on 2013-02-17.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FakeSegmentListener
-(void)fakeSegmentChanged:(id)sender;
@end

@interface FakeSegmentedControl : UIView {
    
    IBOutlet UILabel *label0;
    IBOutlet UILabel *label1;
    IBOutlet UILabel *label2;
    IBOutlet UIImageView *background0;
    IBOutlet UIImageView *background1;
    IBOutlet UIImageView *background2;
    
    IBOutlet id <FakeSegmentListener> owner;
    
    int selectedSegmentIndex;
}

-(void)setup;
-(void)markSegment:(int)segNum;
-(IBAction)segmentClicked:(id)sender;

@property (nonatomic) int selectedSegmentIndex;

@end
