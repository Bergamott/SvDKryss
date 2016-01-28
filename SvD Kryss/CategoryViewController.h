//
//  CategoryViewController.h
//  SvD Kryss
//
//  Created by Karl on 2013-02-01.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GAITrackedViewController.h"

@interface CategoryViewController : GAITrackedViewController <UITableViewDelegate, UITableViewDataSource> {

    IBOutlet UITableView *theTable;
}

-(void)setup;
-(void)refresh;
-(IBAction)backButtonPressed:(id)sender;

@end
