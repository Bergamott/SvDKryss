//
//  StoreRootViewController.m
//  SvD Kryss
//
//  Created by Karl on 2013-01-31.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import "StoreRootViewController.h"
#import "SvDKryssAppDelegate.h"
#import "SoundManager.h"
#import "StoreDataHolder.h"
#import "StoreSectionHeader.h"
#import "StoreSectionFooter.h"
#import "OfferListCell.h"
#import "InAppPurchaseManager.h"
#import "DownloadManager.h"
#import "CustomAlertView.h"
#import "LayoutView.h"

#define SLIDE_DURATION 0.25

@interface StoreRootViewController ()

@end

@implementation StoreRootViewController

@synthesize receivedData;

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedProductVerifications:)
                                                     name:kInAppPurchaseManagerProductsFetchedNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(problemConnectingToStore:)
                                                     name:kInAppPurchaseManagerStoreGeneralProblem
                                                   object:nil];
    }
    return self;
}

-(void)setupWithPackageToShow:(int)pkId
{
    packageToShow = pkId;
    activityView.hidden = FALSE;
    [activityIndicator startAnimating];
    [[DownloadManager sharedDownloadManager] queueStoreDataDownloads];
    subscribeButtonView.hidden = [[DownloadManager sharedDownloadManager] isSubscriber];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.screenName = @"hamta korsord";
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

// Triggered through Notification Center
-(void)receivedProductVerifications:(NSNotification*)notif
{
    [activityIndicator stopAnimating];
    activityView.hidden = TRUE;
    
    NSArray *nib;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        nib = [[NSBundle mainBundle] loadNibNamed:@"StoreSectionFooter-iPad" owner:self options:nil];
    else
        nib = [[NSBundle mainBundle] loadNibNamed:@"StoreSectionFooter" owner:self options:nil];
    
    if ([StoreDataHolder sharedStoreDataHolder].storeCategoryIds.count > 0)
    {
/*        if ([StoreDataHolder sharedStoreDataHolder].storeIntroText != NULL)
            subtitle.text = [StoreDataHolder sharedStoreDataHolder].storeIntroText;*/
        // Use static text now, depending on subscriber status
        if ([[DownloadManager sharedDownloadManager] isSubscriber])
            subtitle.text = @"Här visas de senaste korsordspaketen som ännu inte laddats ned.";
        else
            subtitle.text = @"Som prenumerant måste du logga in för att ladda ned korsorden utan extra kostnad.";
        theTable.tableFooterView = [nib objectAtIndex:0];
    }
    else // Special information text when there are no more packages to buy
    {
        subtitle.text = @"Det finns inga nya korsord att ladda ned.";
        theTable.tableFooterView = NULL;
        
/*        for (UIView *tmpV in theTable.tableFooterView.subviews)
        {
            if ([tmpV isKindOfClass:[UIControl class]])
                ((UIControl*)tmpV).enabled = FALSE;
            else
                tmpV.alpha = 0.5;
        }*/
    }
    [theTable reloadData];
 
    if ([[StoreDataHolder sharedStoreDataHolder] getPackageNumberFromId:[NSNumber numberWithInt:packageToShow]] != NSNotFound)
    {
        SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
        [delegate showDisclosureViewForPackage:[[StoreDataHolder sharedStoreDataHolder] getPackageFromId:[NSNumber numberWithInt: packageToShow]]];
        packageToShow = -1;
    }
    [layoutView determineMargins];
    [layoutView fillUp];
    // Special check to avoid long tables from extending beyond the screen
//    theTable.bounds = CGRectMake(0, theTable.bounds.origin.y, theTable.bounds.size.width, self.view.bounds.size.height-theTable.bounds.origin.y);
}
-(void)refresh
{
    NSArray *tmpA = [theCategory objectForKey:@"packages"];
    NSMutableArray *newPackageList = [[NSMutableArray alloc] initWithCapacity:[tmpA count]];
    for (NSNumber *tmpN in tmpA)
    {
        if ([[StoreDataHolder sharedStoreDataHolder].storePackageIds containsObject:tmpN])
            [newPackageList addObject:tmpN];
    }
    if ([newPackageList count] < [tmpA count])
        [theCategory setValue:newPackageList forKey:@"packages"];
    [newPackageList release];
    [theTable reloadData];
    if ([StoreDataHolder sharedStoreDataHolder].storeCategoryIds.count == 0)
    {
        subtitle.text = @"Det finns inga nya korsord att ladda ned.";
        theTable.tableFooterView = NULL;
    }
}

-(IBAction)backButtonPressed:(id)sender
{
    [[InAppPurchaseManager sharedInAppPurchaseManager] cancelRequestWhenLeavingStore];
    [[DownloadManager sharedDownloadManager] cancelStoreDataFetch]; // In case the loading got stuck
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
//    [delegate showInitialView];
    [delegate goBack];
}

-(IBAction)showAllPackagesPressed:(id)sender
{
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
    [delegate showCategoryView];
}

-(void)problemConnectingToStore:(NSNotification*)notif
{
    [activityIndicator stopAnimating];
    activityView.hidden = TRUE;
    
    // Show alert
    NSLog(@"Showing alert");
    UIAlertView *message = [[CustomAlertView alloc] initWithTitle:@"Hoppsan!"
                                                      message:@"Det gick inte att ansluta till butiken"
                                                     delegate:self
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
    message.tag = STORE_PROBLEM_ALERT_TAG;
    [message show];
}


#pragma mark -
#pragma mark Alert view delegate method

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == STORE_PROBLEM_ALERT_TAG)
    {
        SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
        [delegate goBack];
    }
}

-(void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark Table data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[StoreDataHolder sharedStoreDataHolder] numberOfPackagesInOfferSection:section];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[StoreDataHolder sharedStoreDataHolder] numberOfOfferSections];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	static NSString *CellIdentifier = @"OfferListCellIdentifier";
    
	OfferListCell *cell = (OfferListCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *nib;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            nib = [[NSBundle mainBundle] loadNibNamed:@"OfferListCell-iPad" owner:self options:nil];
        else
            nib = [[NSBundle mainBundle] loadNibNamed:@"OfferListCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }

    NSDictionary *tmpP = [[StoreDataHolder sharedStoreDataHolder] packageInOfferSection:[indexPath section] andRow:[indexPath row]];
    
    [self fillCell:cell withDataFromPackage:tmpP];
    
	return cell;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{

    return [[StoreDataHolder sharedStoreDataHolder] titleForOfferSection:section];
}

#pragma mark Header stuff

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    StoreSectionHeader *storeSectionHeader;
    NSArray *nib;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        nib = [[NSBundle mainBundle] loadNibNamed:@"StoreSectionHeader-iPad" owner:self options:nil];
    else
        nib = [[NSBundle mainBundle] loadNibNamed:@"StoreSectionHeader" owner:self options:nil];
    storeSectionHeader = [nib objectAtIndex:0];
    storeSectionHeader.headline.text = [[[StoreDataHolder sharedStoreDataHolder] titleForOfferSection:section] uppercaseString];
    
    return storeSectionHeader;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return SECTION_HEADER_HEIGHT_IPAD;
    else
        return SECTION_HEADER_HEIGHT_IPHONE;
}

#pragma mark Selection

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OfferListCell *tmpC = (OfferListCell*)[tableView cellForRowAtIndexPath:indexPath];

    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
    [delegate showDisclosureViewForPackage:[[StoreDataHolder sharedStoreDataHolder] getPackageFromId:[NSNumber numberWithInt: tmpC.tag]]];
}

#pragma mark -
#pragma mark Subscriptions


-(IBAction)subscribeButtonPressed:(id)sender
{
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle]
                                                                                            pathForResource:[[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone?@"subscribe-iphone":@"subscribe-ipad" ofType:@"html"]isDirectory:NO]]];
    [UIView animateWithDuration:SLIDE_DURATION delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^(void){
        encloserView.frame = CGRectMake(self.view.frame.size.width-encloserView.frame.size.width, 0.0, encloserView.frame.size.width, encloserView.frame.size.height);
    }completion:^(BOOL Finished){
        revertButton.hidden = FALSE;
    }];
}

-(IBAction)revertButtonPressed:(id)sender
{
    [UIView animateWithDuration:SLIDE_DURATION delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^(void){
        encloserView.frame = CGRectMake(0.0, 0.0, encloserView.frame.size.width, encloserView.frame.size.height);
    }completion:^(BOOL Finished){
        revertButton.hidden = TRUE;
    }];
}

@end
