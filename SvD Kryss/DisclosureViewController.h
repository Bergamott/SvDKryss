//
//  DisclosureViewController.h
//  SvD Kryss
//
//  Created by Karl on 2013-02-05.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GAITrackedViewController.h"

@interface DisclosureViewController : GAITrackedViewController  <UITableViewDelegate, UITableViewDataSource> {
    
//    BOOL cameFromStoreRootView;
    NSDictionary *storePackage;
    
    IBOutlet UILabel *headline;
    IBOutlet UILabel *subtitle;
    IBOutlet UIActivityIndicatorView *activityIndicator;
    
    IBOutlet UITableView *theTable;
    NSArray *crosswordIDs;
    
    IBOutlet UIView *purchaseButtonView;
    IBOutlet UILabel *purchasePriceLabel;
    IBOutlet UIView *downloadButtonView;
    IBOutlet UIView *downloadingSignView;
    IBOutlet UIView *downloadedSignView;
}

-(void)setupWithStorePackage:(NSDictionary*)sp;
-(IBAction)backButtonPressed:(id)sender;
-(void)markAsDownloading;
-(void)downloadComplete:(NSNotification*)notif;
-(void)refresh;
-(IBAction)purchasePressed:(id)sender;
-(IBAction)downloadButtonPressed:(id)sender;

@property(nonatomic,retain) NSDictionary *storePackage;
@property(nonatomic,retain) NSArray *crosswordIDs;

@end
