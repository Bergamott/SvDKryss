//
//  SvDKryssAppDelegate.m
//  SvD Kryss
//
//  Created by Karl on 2013-01-09.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import "SvDKryssAppDelegate.h"

#import "SvDKryssViewController.h"
#import "CrosswordViewController.h"
#import "PackageViewController.h"
#import "ItemViewController.h"
#import "StartedViewController.h"
#import "DataHolder.h"
#import "StoreDataHolder.h"

#import "StoreRootViewController.h"
#import "CategoryViewController.h"
#import "StorePackageViewController.h"
#import "DisclosureViewController.h"
#import "PreViewController.h"

#import "InAppPurchaseManager.h"
#import "DownloadManager.h"

#import "OpenUDID.h"
#import "CustomAlertView.h"

#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"
#import "GAILogger.h"


#define IOS_OLDER_THAN_6 ( [ [ [ UIDevice currentDevice ] systemVersion ] floatValue ] < 6.0 )
#define IOS_NEWER_OR_EQUAL_TO_6 ( [ [ [ UIDevice currentDevice ] systemVersion ] floatValue ] >= 6.0 )

#define BETA_IDENTIFIER @"2da54219a19177e9afb6b2158e9706a7"
#define LIVE_IDENTIFIER @"2da54219a19177e9afb6b2158e9706a7"

#define NOTIFICATION_GENERAL 0
#define NOTIFICATION_PACKAGE 1

@implementation SvDKryssAppDelegate

@synthesize crosswordViewController;
@synthesize packageViewController;
@synthesize itemViewController;
@synthesize startedViewController;

@synthesize storeRootViewController;
@synthesize categoryViewController;
@synthesize storePackageViewController;
@synthesize disclosureViewController;
@synthesize preViewController;

@synthesize opDict;

- (void)dealloc
{
    [_window release];
    [_viewController release];
    [crosswordViewController release];
    [packageViewController release];
    [itemViewController release];
    [startedViewController release];
    
    [storeRootViewController release];
    [categoryViewController release];
    [storePackageViewController release];
    [disclosureViewController release];
    [preViewController release];
    [opDict release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
   if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.viewController = [[[SvDKryssViewController alloc] initWithNibName:@"SvDKryssViewController_iPhone" bundle:nil] autorelease];
    } else {
        self.viewController = [[[SvDKryssViewController alloc] initWithNibName:@"SvDKryssViewController_iPad" bundle:nil] autorelease];
    }
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    
    // Google Analytics
/*    // Optional: automatically send uncaught exceptions to Google Analytics.
//    [GAI sharedInstance].trackUncaughtExceptions = YES;
    // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
    [GAI sharedInstance].dispatchInterval = 20;
    // Optional: set debug to YES for extra debugging information.
    [GAI sharedInstance].debug = YES;
    // Create tracker instance.
    id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:GA_ID];
    if (tracker == NULL)
        NSLog(@"Problem");*/
    
    // Configure tracker from GoogleService-Info.plist.
    GAI *gai = [GAI sharedInstance];
    [gai trackerWithTrackingId:GA_ID];
    gai.trackUncaughtExceptions = YES;  // report uncaught exceptions
    
    // HockeyApp
/*
    [[BITHockeyManager sharedHockeyManager] configureWithBetaIdentifier: BETA_IDENTIFIER liveIdentifier: LIVE_IDENTIFIER delegate:self];
    [[BITHockeyManager sharedHockeyManager] startManager];
*/
    
    // Data management
    [[DownloadManager sharedDownloadManager] setup];
    [[DataHolder sharedDataHolder] loadEverything];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedTransactionResult:)
                                                 name:kInAppPurchaseManagerTransactionSucceededNotification
                                               object:nil];    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedTransactionResult:)
                                                 name:kInAppPurchaseManagerTransactionFailedNotification
                                               object:nil];
    // For testing purposes
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedTransactionResult:)
                                                 name:kInAppPurchaseManagerFreePurchaseNotification
                                               object:nil];
    [[InAppPurchaseManager sharedInAppPurchaseManager] loadStore];
    
    system6orLater = ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] == NSOrderedDescending);
    
	// Let the device know we want to receive push notifications
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:
     (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];    
    
    // Handle push notifications
    if (launchOptions != nil)
	{
		NSDictionary* dictionary = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
		if (dictionary != nil)
		{
			NSLog(@"Launched from push notification: %@", dictionary);
			
            int notificationType = [(NSNumber*)[dictionary objectForKey:@"type"] intValue];
            if (notificationType == NOTIFICATION_PACKAGE)
            {
                newPackageId = [(NSNumber*)[dictionary objectForKey:@"pkId"] intValue];
            }
		}
	}
    [[FBSDKApplicationDelegate sharedInstance] application:application
                             didFinishLaunchingWithOptions:launchOptions];
    return YES;
}

#pragma mark -
#pragma mark Push notifications

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
	NSLog(@"My token is: %@", deviceToken);
    // Store for later shipment
    NSString *cleanToken = [deviceToken description];
    cleanToken = [cleanToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    cleanToken = [cleanToken stringByReplacingOccurrencesOfString:@" " withString:@""];

    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:cleanToken forKey:@"apstoken"];
    [prefs synchronize];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
	NSLog(@"Failed to get token, error: %@", error);
}

- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo
{
	NSLog(@"Received notification: %@", userInfo);
	NSDictionary *aps = [userInfo objectForKey:@"aps"];
    int notificationType = [(NSNumber*)[userInfo objectForKey:@"type"] intValue];
    if (notificationType == NOTIFICATION_PACKAGE)
    {
        newPackageId = [(NSNumber*)[userInfo objectForKey:@"pkId"] intValue];
        UIAlertView *message = [[CustomAlertView alloc] initWithTitle:NULL
                                                              message:[aps objectForKey:@"alert"]
                                                             delegate:self
                                                    cancelButtonTitle:@"Stäng"
                                                    otherButtonTitles:@"Visa", nil];
        [message show];
    }
    else if (notificationType == NOTIFICATION_GENERAL)
    {
        UIAlertView *message = [[CustomAlertView alloc] initWithTitle:NULL
                                                              message:[aps objectForKey:@"alert"]
                                                             delegate:self
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles:nil];
        [message show];
    }
}

-(void)checkNewPackageNotification
{
    if (newPackageId > 0)
    {
        currentViewController = SCREEN_SVD_KRYSS_VIEW_CONTROLLER;
        [self showStoreViewWithPackage:newPackageId];
        newPackageId = -1;
    }
    else if (newCrosswordId > 0)
    {
        NSLog(@"Checking new crossword id");
        DataHolder *myData = [DataHolder sharedDataHolder];
        NSNumber *cwId = [NSNumber numberWithInt:newCrosswordId];
        newCrosswordId = 0;
        if ([myData alreadyOwnsCrossword:cwId])
        {
            myData.currentCrossword = [myData getCrosswordFromID:cwId];
            [self showCrosswordView];
        }
    }
}

#pragma mark -
#pragma mark Standard app behavior

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSDate date] forKey:@"lastActive"];
    [defaults synchronize];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    if (currentViewController == SCREEN_CROSSWORD_VIEW_CONTROLLER)
    {
        [crosswordViewController enterBackground];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    if (currentViewController == SCREEN_CROSSWORD_VIEW_CONTROLLER)
    {
        [crosswordViewController enterForeground];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"Did become active");
    if ([[DownloadManager sharedDownloadManager] isLoggedInWithRealAccount])
        [_viewController setLoggedIn:FALSE];
    
    if ([[DownloadManager sharedDownloadManager] authenticate:FALSE])
        [self showLoginBlocker];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark -
#pragma mark Methods for switching views

-(void)showLoginBlocker
{
    if (_window.rootViewController != _viewController)
    {
        // We need to add an overlay view to prevent interaction
        loginOverlayView = [[UIView alloc] initWithFrame:_window.frame];
        [loginOverlayView setBackgroundColor:[UIColor blackColor]];
        loginOverlayView.alpha = 0.4;
        UIActivityIndicatorView *actInd = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [loginOverlayView addSubview:actInd];
        actInd.center = CGPointMake(loginOverlayView.frame.size.width*0.5, loginOverlayView.frame.size.height*0.5);
        [actInd startAnimating];
        [_window addSubview:loginOverlayView];
        [actInd release];
    }
}

-(void)showCrosswordView
{
	if (crosswordViewController == nil)
	{
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			crosswordViewController = [[CrosswordViewController alloc] initWithNibName:@"CrosswordViewController-iPad" bundle:nil];
		else
			crosswordViewController = [[CrosswordViewController alloc] initWithNibName:@"CrosswordViewController" bundle:nil];
		if (crosswordViewController == nil)
			NSLog(@"NIL!!!!");
	}
    [self switchToViewController:crosswordViewController];
    [crosswordViewController initiateWithCurrentCrossword];
    crosswordViewController.view.tag = currentViewController;
    currentViewController = SCREEN_CROSSWORD_VIEW_CONTROLLER;
}

-(void)showPackageView
{
	if (packageViewController == nil)
	{
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			packageViewController = [[PackageViewController alloc] initWithNibName:@"PackageViewController-iPad" bundle:nil];
		else
			packageViewController = [[PackageViewController alloc] initWithNibName:@"PackageViewController" bundle:nil];
		if (packageViewController == nil)
			NSLog(@"NIL!!!!");
	}
    [self switchToViewController:packageViewController];

    [packageViewController refresh];
    packageViewController.view.tag = currentViewController;
    currentViewController = SCREEN_PACKAGE_VIEW_CONTROLLER;
}

-(void)showItemViewWithPackage:(NSDictionary*)pk
{
	if (itemViewController == nil)
	{
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			itemViewController = [[ItemViewController alloc] initWithNibName:@"ItemViewController-iPad" bundle:nil];
		else
			itemViewController = [[ItemViewController alloc] initWithNibName:@"ItemViewController" bundle:nil];
		if (itemViewController == nil)
			NSLog(@"NIL!!!!");
	}
    [self switchToViewController:itemViewController];
    
    lastViewBeforeCrosswordWasItemView = TRUE;
    [itemViewController setUpWithPackage:pk];
    itemViewController.view.tag = currentViewController;
    currentViewController = SCREEN_ITEM_VIEW_CONTROLLER;
}

-(void)showStartedView
{
	if (startedViewController == nil)
	{
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			startedViewController = [[StartedViewController alloc] initWithNibName:@"StartedViewController-iPad" bundle:nil];
		else
			startedViewController = [[StartedViewController alloc] initWithNibName:@"StartedViewController" bundle:nil];
		if (startedViewController == nil)
			NSLog(@"NIL!!!!");
	}
    [self switchToViewController:startedViewController];
    
    lastViewBeforeCrosswordWasItemView = FALSE;
    [startedViewController setUp];
    startedViewController.view.tag = currentViewController;
    currentViewController = SCREEN_STARTED_VIEW_CONTROLLER;
}

-(void)showStoreViewWithPackage:(int)pkId
{
	if (storeRootViewController == nil)
	{
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			storeRootViewController = [[StoreRootViewController alloc] initWithNibName:@"StoreRootViewController-iPad" bundle:nil];
		else
			storeRootViewController = [[StoreRootViewController alloc] initWithNibName:@"StoreRootViewController" bundle:nil];
		if (storeRootViewController == nil)
			NSLog(@"NIL!!!!");
	}
    [self switchToViewController:storeRootViewController];
    
    [storeRootViewController setupWithPackageToShow:pkId];
    storeRootViewController.view.tag = currentViewController;
    currentViewController = SCREEN_STORE_ROOT_VIEW_CONTROLLER;
}

-(void)showCategoryView
{
	if (categoryViewController == nil)
	{
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			categoryViewController = [[CategoryViewController alloc] initWithNibName:@"CategoryViewController-iPad" bundle:nil];
		else
			categoryViewController = [[CategoryViewController alloc] initWithNibName:@"CategoryViewController" bundle:nil];
		if (storeRootViewController == nil)
			NSLog(@"NIL!!!!");
	}
    [self switchToViewController:categoryViewController];
    [categoryViewController setup];
    categoryViewController.view.tag = currentViewController;
    currentViewController = SCREEN_CATEGORY_VIEW_CONTROLLER;
}

-(void)showStorePackageViewForCategory:(NSDictionary*)cat
{
	if (storePackageViewController == nil)
	{
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			storePackageViewController = [[StorePackageViewController alloc] initWithNibName:@"StorePackageViewController-iPad" bundle:nil];
		else
			storePackageViewController = [[StorePackageViewController alloc] initWithNibName:@"StorePackageViewController" bundle:nil];
		if (storePackageViewController == nil)
			NSLog(@"NIL!!!!");
	}
    [self switchToViewController:storePackageViewController];
    [storePackageViewController setupWithCategory:cat];
    storePackageViewController.view.tag = currentViewController;
    currentViewController = SCREEN_STORE_PACKAGE_VIEW_CONTROLLER;
}

-(void)showDisclosureViewForPackage:(NSDictionary*)pk
{
	if (disclosureViewController == nil)
	{
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            disclosureViewController = [[DisclosureViewController alloc] initWithNibName:@"DisclosureViewController-iPad" bundle:nil];
        else
            disclosureViewController = [[DisclosureViewController alloc] initWithNibName:@"DisclosureViewController" bundle:nil];
        if (disclosureViewController == nil)
			NSLog(@"NIL!!!!");
	}
    [self switchToViewController:disclosureViewController];
    [disclosureViewController setupWithStorePackage:pk];
    disclosureViewController.view.tag = currentViewController;
    currentViewController = SCREEN_DISCLOSURE_VIEW_CONTROLLER;
}

#pragma mark -
#pragma mark Store transaction notifications

-(void)receivedTransactionResult:(NSNotification*)notif
{
    if ([[notif name] isEqualToString:kInAppPurchaseManagerTransactionSucceededNotification])
    {
        NSLog(@"Received successful transaction notification");
        SKPaymentTransaction *transaction = [notif.userInfo objectForKey:@"transaction"];
        NSString *tmpID = transaction.payment.productIdentifier;
        NSNumber *pkdId = [NSNumber numberWithInt:[tmpID intValue]];
        NSData *receiptData = transaction.transactionReceipt;
        if ([[DataHolder sharedDataHolder].myPackageIds indexOfObject:pkdId] == NSNotFound &&
            [[StoreDataHolder sharedStoreDataHolder] getPackageFromId:pkdId] != NULL) // Really in store?
        {
            [[StoreDataHolder sharedStoreDataHolder] setAsBeingDownloaded:pkdId];
            [[DownloadManager sharedDownloadManager] registerPurhcaseID:pkdId withWallet:@"appstore" withTransactionId:transaction.transactionIdentifier andReceipt:[[DownloadManager sharedDownloadManager] base64forData:receiptData]];
        }
    }
    else if ([[notif name] isEqualToString:kInAppPurchaseManagerTransactionFailedNotification])
    {
        NSLog(@"Transaction failed");
        UIAlertView *message = [[CustomAlertView alloc] initWithTitle:nil
                                                              message:@"Nedladdning ej möjlig just nu – ingen kontakt med servern." // Earlier @"Köpet gick inte att genomföra"
                                                             delegate:nil
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles:nil];
        [message show];
        if (disclosureViewController != nil)
            [disclosureViewController downloadComplete:nil];
    }
    else // Bypassed App Store and went straight here when price was 0
    {
        NSNumber *tmpID = [notif.userInfo objectForKey:@"paId"];
        [[StoreDataHolder sharedStoreDataHolder] setAsBeingDownloaded:tmpID];
        [[DownloadManager sharedDownloadManager] registerPurhcaseID:tmpID withWallet:@"free" withTransactionId:@"0" andReceipt:@""];
    }
}

-(void)showPreviewWithPackage:(NSDictionary*)pk andCrosswordID:(NSNumber*)cwId;
{
	if (preViewController == nil)
	{
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            preViewController = [[PreViewController alloc] initWithNibName:@"PreViewController-iPad" bundle:nil];
        else
            preViewController = [[PreViewController alloc] initWithNibName:@"PreViewController" bundle:nil];
        if (preViewController == nil)
			NSLog(@"NIL!!!!");
	}
    [self switchToViewController:preViewController];
    [preViewController setUpWithPackage:pk andCrosswordID:cwId];
    preViewController.view.tag = currentViewController;
    currentViewController = SCREEN_PRE_VIEW_CONTROLLER;
}

-(void)goBack
{
    currentViewController = _window.rootViewController.view.tag;
    switch(currentViewController)
    {
        case SCREEN_SVD_KRYSS_VIEW_CONTROLLER:
            [self switchToViewController:_viewController];
            break;
        case SCREEN_PACKAGE_VIEW_CONTROLLER:
            [self switchToViewController:packageViewController];
            [packageViewController refresh];
            break;
        case SCREEN_ITEM_VIEW_CONTROLLER:
            [self switchToViewController:itemViewController];
            [itemViewController refresh];
            break;
        case SCREEN_STARTED_VIEW_CONTROLLER:
            [self switchToViewController:startedViewController];
            [startedViewController refresh];
            break;
        case SCREEN_STORE_ROOT_VIEW_CONTROLLER:
            [self switchToViewController:storeRootViewController];
            [storeRootViewController refresh];
            break;
        case SCREEN_STORE_PACKAGE_VIEW_CONTROLLER:
            NSLog(@"Going back to StorePackageViewController");
            [self switchToViewController:storePackageViewController];
            NSLog(@"Refreshing ...");
            [storePackageViewController refresh];
            break;
        case SCREEN_CATEGORY_VIEW_CONTROLLER:
            [self switchToViewController:categoryViewController];
            [categoryViewController refresh];
            break;
        case SCREEN_DISCLOSURE_VIEW_CONTROLLER:
            [self switchToViewController:disclosureViewController];
            [_window setRootViewController:disclosureViewController];
            break;
        default:
            break;
    }
}

-(void)switchToViewController:(UIViewController*)uivc
{
    [_viewController.view removeFromSuperview];
    if (TRUE)
        [_window setRootViewController:uivc];
    else
        [_window addSubview:uivc.view];
}

-(void)completionDownloadProgress:(BOOL)finished
{
    if (finished)
    {
        if (itemViewController != NULL)
            [itemViewController downloadingDone];
        if (disclosureViewController != NULL)
            [disclosureViewController setupWithStorePackage:disclosureViewController.storePackage];
    }
    else
    {
        if (itemViewController != NULL)
            [itemViewController refresh];
    }
}

#pragma mark -
#pragma mark Alert view delegate method

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) // Not cancel
    {
        NSLog(@"Go to the store!");
        
        if (currentViewController == SCREEN_CROSSWORD_VIEW_CONTROLLER)
        {
            // Make sure to save
            [crosswordViewController prepareToLeave];
        }
        currentViewController = SCREEN_SVD_KRYSS_VIEW_CONTROLLER;
        [self showStoreViewWithPackage:newPackageId];
    }
}

/*#pragma mark -
#pragma mark HockeyApp delegate method
- (NSString *)customDeviceIdentifierForUpdateManager:(BITUpdateManager *)updateManager {
#ifndef CONFIGURATION_AppStore
    return [OpenUDID value];
#endif
    return nil;
}*/


#pragma mark -
#pragma mark State transition methods

-(void)successfullyLoggedIn:(BOOL)manually;
{
    [_viewController setLoggedIn:manually];
    [self checkIfLoginBlock];
}

-(void)successfullyLoggedOut
{
    [_viewController setLoggedOut];
    [self checkIfLoginBlock];
}

-(void)automaticLoginFailed
{
    [_viewController showFailedLoginWarning];
}

-(void)showLoginIndicator
{
    [_viewController showLoginIndicator];
}

-(void)hideLoginIndicator
{
    [_viewController hideBackgroundButton];
    [self checkIfLoginBlock];
}

-(void)checkIfLoginBlock
{
    if (loginOverlayView != NULL)
    {
        [loginOverlayView removeFromSuperview];
        [loginOverlayView release];
        loginOverlayView = NULL;
    }
    
}

#pragma mark -
#pragma mark Custom URL scheme

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    NSLog(@"URL: %@", url);
    NSLog(@"Opened from : %@", sourceApplication);
    NSLog(@"Annotation : %@", annotation);
    
    NSString *uStr = [url absoluteString];
    if ([uStr containsString:@"fb180327315501236"])
        return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                              openURL:url
                                                    sourceApplication:sourceApplication
                                                           annotation:annotation
                ];
    int i = uStr.length;
    while (i>0 && [uStr characterAtIndex:i-1] != '/')
        i--;
    if (i>0)
    {
        newCrosswordId = [[uStr substringFromIndex:i] intValue];
    }
    return YES;
}

@end
