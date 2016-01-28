//
//  ItemViewController.h
//  SvD Kryss
//
//  Created by Karl on 2013-01-22.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GAITrackedViewController.h"

@class DataHolder;

@interface ItemViewController : GAITrackedViewController <UITableViewDelegate, UITableViewDataSource> {
    
    IBOutlet UILabel *headline;
    IBOutlet UILabel *subtitle;
    
    IBOutlet UITableView *theTable;
    
    DataHolder *myData;
    NSDictionary *currentPackage;
    
    IBOutlet UIView *downloadButtonView;
    IBOutlet UIView *downloadingSignView;
    IBOutlet UIView *buttonHolderView;
    IBOutlet UIActivityIndicatorView *spinWheel;
    
    BOOL downloading;
}

-(void)refresh;
-(IBAction)backButtonPressed:(id)sender;
-(void)setUpWithPackage:(NSDictionary*)pk;
-(IBAction)downloadButtonPressed:(id)sender;
-(void)downloadingDone;

@end
