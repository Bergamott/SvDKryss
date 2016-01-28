//
//  PackageViewController.h
//  SvD Kryss
//
//  Created by Karl on 2013-01-22.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GAITrackedViewController.h"

@class DataHolder;

@interface PackageViewController : GAITrackedViewController <UITableViewDelegate, UITableViewDataSource> {
    
    DataHolder *myData;
    IBOutlet UITableView *theTable;
}

-(void)refresh;
-(IBAction)backButtonPressed:(id)sender;
-(IBAction)restorePurchasesPressed:(id)sender;

-(void)hideAllDeleteButtons;
-(void)clearCrosswordsForCellRow:(int)r;

@end
