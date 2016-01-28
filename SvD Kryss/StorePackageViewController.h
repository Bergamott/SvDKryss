//
//  StorePackageViewController.h
//  SvD Kryss
//
//  Created by Karl on 2013-02-04.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GAITrackedViewController.h"

#define STORE_PROBLEM_ALERT_TAG 1

@class OfferListCell;
@class LayoutView;

@interface StorePackageViewController : GAITrackedViewController <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate> {
    
    IBOutlet UITableView *theTable;
    IBOutlet UILabel *headline;
    IBOutlet UITextView *subtitle;
    
    NSMutableDictionary *theCategory;
    
    UIPopoverController *popoverController;
    
    IBOutlet LayoutView *layoutView;
}

-(void)setupWithCategory:(NSDictionary*)cat;
-(IBAction)backButtonPressed:(id)sender;
-(void)refresh;

-(void)fillCell:(OfferListCell*)ce withDataFromPackage:(NSDictionary*)pa;

// Package info / purchase methods
//-(IBAction)infoPressed:(id)sender;
//-(IBAction)purchasePressed:(id)sender;
-(OfferListCell*)findCellForTag:(int)tg;
//-(OfferListCell*)findCellForPackageId:(NSString*)pId;
-(void)downloadComplete:(NSNotification*)notif;

@property(nonatomic,retain) NSDictionary *theCategory;

@property(nonatomic,retain) UIPopoverController *popoverController;

@end
