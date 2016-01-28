//
//  StartedViewController.h
//  SvD Kryss
//
//  Created by Karl on 2013-01-30.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import "ItemViewController.h"
#import "FakeSegmentedControl.h"

#define FILTER_WEEK 0
#define FILTER_MONTH 1
#define FILTER_ALL 2

@interface StartedViewController : GAITrackedViewController <UITableViewDelegate, UITableViewDataSource, FakeSegmentListener> {
        
    IBOutlet UITableView *theTable;
    
    DataHolder *myData;
    
    IBOutlet FakeSegmentedControl *fakeSegmentedControl;
}

-(void)setUp;
-(void)refresh;

@end
