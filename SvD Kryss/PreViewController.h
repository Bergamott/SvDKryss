//
//  PreViewController.h
//  SvD Kryss
//
//  Created by Karl on 2013-02-18.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GAITrackedViewController.h"

@interface PreViewController : GAITrackedViewController <UIScrollViewDelegate> {
    
    IBOutlet UILabel *headline;
    IBOutlet UITextView *description;
    
    IBOutlet UIActivityIndicatorView *activityIndicator;
    
    IBOutlet UIScrollView *imageScroller;
    IBOutlet UIImageView *scrollContent;
    
    IBOutlet UIView *dotView;
    NSDictionary *package;
    int crosswordNumber;
    int crosswordCount;
    NSArray *trimmedIDList;
}

-(void)setUpWithPackage:(NSDictionary*)pk andCrosswordID:(NSNumber*)cwId;
-(void)loadCrossword;
-(IBAction)backButtonPressed:(id)sender;

-(IBAction)backwardArrowPressed:(id)sender;
-(IBAction)forwardArrowPressed:(id)sender;

-(void)crosswordLoaded;

-(void)sendGAEvent:(NSString*)action;

@property(nonatomic,retain) NSDictionary *package;
@property(nonatomic,retain) NSArray *trimmedIDList;

@end
