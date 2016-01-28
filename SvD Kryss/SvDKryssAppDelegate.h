//
//  SvDKryssAppDelegate.h
//  SvD Kryss
//
//  Created by Karl on 2013-01-09.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
//#import <HockeySDK/HockeySDK.h>

#define SCREEN_SVD_KRYSS_VIEW_CONTROLLER 0
#define SCREEN_PACKAGE_VIEW_CONTROLLER 1
#define SCREEN_ITEM_VIEW_CONTROLLER 2
#define SCREEN_STARTED_VIEW_CONTROLLER 3
#define SCREEN_STORE_ROOT_VIEW_CONTROLLER 4
#define SCREEN_CATEGORY_VIEW_CONTROLLER 5
#define SCREEN_STORE_PACKAGE_VIEW_CONTROLLER 6
#define SCREEN_DISCLOSURE_VIEW_CONTROLLER 7
#define SCREEN_PRE_VIEW_CONTROLLER 8
#define SCREEN_CROSSWORD_VIEW_CONTROLLER 9
#define SCREEN_PASSWORD_VIEW_CONTROLLER 10

#define GA_ID @"UA-1717270-16"

#define FACEBOOK_APP_ID @"180327315501236"

@class SvDKryssViewController;
@class CrosswordViewController;
@class PackageViewController;
@class ItemViewController;
@class StartedViewController;
@class StoreRootViewController;
@class CategoryViewController;
@class StorePackageViewController;
@class DisclosureViewController;
@class PreViewController;

//@interface SvDKryssAppDelegate : UIResponder <UIApplicationDelegate,BITHockeyManagerDelegate, BITUpdateManagerDelegate, BITCrashManagerDelegate, UIAlertViewDelegate> {
@interface SvDKryssAppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate> {
    
    CrosswordViewController *crosswordViewController;
    PackageViewController *packageViewController;
    ItemViewController *itemViewController;
    StartedViewController *startedViewController;
    
    StoreRootViewController *storeRootViewController;
    CategoryViewController *categoryViewController;
    StorePackageViewController *storePackageViewController;
    DisclosureViewController *disclosureViewController;
    PreViewController *preViewController;
   
    BOOL lastViewBeforeCrosswordWasItemView;
    
    // Store authentificaton and data storage / retrieval
    NSMutableDictionary *opDict;
    
    int currentViewController;
    BOOL system6orLater;
    
    int newPackageId;
    int newCrosswordId; // For opening crosswords from a URL
    
    // Special view to prevent user interaction during login
    UIView *loginOverlayView;
}

#pragma mark -
#pragma mark Methods for switching views

-(void)showLoginBlocker;
-(void)showCrosswordView;
-(void)showPackageView;
-(void)showItemViewWithPackage:(NSDictionary*)pk;
-(void)showStartedView;

-(void)showStoreViewWithPackage:(int)pkId;
-(void)showCategoryView;
-(void)showStorePackageViewForCategory:(NSDictionary*)cat;
-(void)showDisclosureViewForPackage:(NSDictionary*)pk;
-(void)showPreviewWithPackage:(NSDictionary*)pk andCrosswordID:(NSNumber*)id;

-(void)goBack;
-(void)switchToViewController:(UIViewController*)uivc;

-(void)completionDownloadProgress:(BOOL)finished;

-(void)checkNewPackageNotification;

#pragma mark -
#pragma mark Store transaction notifications

-(void)receivedTransactionResult:(NSNotification*)notif;

#pragma mark -
#pragma mark State transition methods

-(void)successfullyLoggedIn:(BOOL)manually;
-(void)successfullyLoggedOut;
-(void)automaticLoginFailed;
-(void)showLoginIndicator;
-(void)hideLoginIndicator;
-(void)checkIfLoginBlock;

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) SvDKryssViewController *viewController;
@property (nonatomic, retain) CrosswordViewController *crosswordViewController;
@property (nonatomic, retain) PackageViewController *packageViewController;
@property (nonatomic, retain) ItemViewController *itemViewController;
@property (nonatomic, retain) StartedViewController *startedViewController;

@property (nonatomic, retain) StoreRootViewController *storeRootViewController;
@property (nonatomic, retain) CategoryViewController *categoryViewController;
@property (nonatomic, retain) StorePackageViewController *storePackageViewController;
@property (nonatomic, retain) DisclosureViewController *disclosureViewController;
@property (nonatomic, retain) PreViewController *preViewController;

@property (nonatomic, retain) NSMutableDictionary *opDict;

@end
