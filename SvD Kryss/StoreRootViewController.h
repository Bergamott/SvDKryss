//
//  StoreRootViewController.h
//  SvD Kryss
//
//  Created by Karl on 2013-01-31.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StorePackageViewController.h"

@interface StoreRootViewController : StorePackageViewController {

    IBOutlet UIView *activityView;
    IBOutlet UIActivityIndicatorView *activityIndicator;
    
    // Data loading stuff. Change later
    NSMutableData *receivedData;
    NSArray *urlList;
    int fileCounter;
    
    int packageToShow;
    
    IBOutlet UIView *subscribeButtonView;
    IBOutlet UIButton *revertButton;
    IBOutlet UIView *encloserView;
    
    IBOutlet UIWebView *webView;
}

-(void)setupWithPackageToShow:(int)pkId;
-(void)receivedProductVerifications:(NSNotification*)notif;
-(void)problemConnectingToStore:(NSNotification*)notif;

-(IBAction)showAllPackagesPressed:(id)sender;

-(IBAction)subscribeButtonPressed:(id)sender;
-(IBAction)revertButtonPressed:(id)sender;

@property(nonatomic,assign) NSMutableData *receivedData;

@end
