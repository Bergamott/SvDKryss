//
//  DisclosureViewController.m
//  SvD Kryss
//
//  Created by Karl on 2013-02-05.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import "DisclosureViewController.h"
#import "SoundManager.h"
#import "SvDKryssAppDelegate.h"
#import "StoreDataHolder.h"
#import "DataHolder.h"
#import "InAppPurchaseManager.h"
#import "StoreItemListCell.h"
#import "DownloadManager.h"

@interface DisclosureViewController ()

@end

@implementation DisclosureViewController

@synthesize storePackage;
@synthesize crosswordIDs;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(downloadComplete:)
                                                     name:kInAppPurchaseManagerDownloadComplete
                                                   object:nil];
    }
    return self;
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

-(void)setupWithStorePackage:(NSDictionary*)sp
{
//    cameFromStoreRootView = og;
    self.storePackage = sp;
    
    headline.text = [[DataHolder sharedDataHolder] getHeadlineFromPackage:sp];
    NSString *tmpDesc = [storePackage objectForKey:@"description"];

    if (tmpDesc == nil || tmpDesc.length == 0)
        subtitle.text = @"Paketet innehåller följande korsord";
    else
        subtitle.text = tmpDesc;
    self.crosswordIDs = [[StoreDataHolder sharedStoreDataHolder] filterOutUnpublishedCrosswords: [storePackage objectForKey:@"crosswords"]];
        
//    NSNumber *price = [sp objectForKey:@"cost"];
//    NSNumber *subscriberCost = [sp objectForKey:SUBSCRIBER_COST];
    
    NSNumber *tmpId = [sp objectForKey:@"paId"];
    NSLog(@"Setting up with ID: %@",tmpId);
    
    purchaseButtonView.hidden = TRUE;
    downloadButtonView.hidden = TRUE;
    downloadingSignView.hidden = TRUE;
    downloadedSignView.hidden = TRUE;
    
    if ([[DataHolder sharedDataHolder] isPackageFullyDownloaded:tmpId])
    {
        downloadedSignView.hidden = FALSE;
        activityIndicator.hidden = TRUE;
        [activityIndicator stopAnimating];
    }
    else
    {
        if ([[StoreDataHolder sharedStoreDataHolder] hasPurchasedPackage:tmpId])
        {
            downloadButtonView.hidden = FALSE;
            activityIndicator.hidden = TRUE;
            [activityIndicator stopAnimating];
        }
        else if ([[StoreDataHolder sharedStoreDataHolder] isBeingDownloaded:tmpId])
        {
            downloadingSignView.hidden = FALSE;
            activityIndicator.hidden = FALSE;
            [activityIndicator startAnimating];
        }
        else
        {
            purchaseButtonView.hidden = FALSE;
/*            if ([price intValue] == 0 || (subscriberCost != NULL && [subscriberCost intValue] == 0))
//                purchasePriceLabel.text = @"Gratis";
                purchasePriceLabel.text = @"Ladda ned";
            else
                purchasePriceLabel.text = [NSString stringWithFormat:@"%d,%02d kr",([price intValue]/100),([price intValue]%100)];*/
            purchasePriceLabel.text = [[DownloadManager sharedDownloadManager] getPriceLabelForPackage:storePackage];
            activityIndicator.hidden = TRUE;
            [activityIndicator stopAnimating];
        }
    }
    [theTable reloadData];
}

-(IBAction)backButtonPressed:(id)sender
{
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
/*    if (cameFromStoreRootView)
        [delegate goBackToStoreView];
    else
        [delegate goBackToStorePackageView];*/
    [delegate goBack];
}

-(IBAction)purchasePressed:(id)sender
{
    NSLog(@"Trying to purchase selected package");
    [self markAsDownloading];
    [[InAppPurchaseManager sharedInAppPurchaseManager] purchasePackage:storePackage];
}

-(IBAction)downloadButtonPressed:(id)sender
{
    [self markAsDownloading];
    if ([[DataHolder sharedDataHolder] alreadyRegisteredPackage:[storePackage objectForKey:@"paId"]])
        [[DownloadManager sharedDownloadManager] completePackage:storePackage];
    else
        [[DownloadManager sharedDownloadManager] downloadPackage:storePackage];
}

-(void)markAsDownloading
{
    downloadingSignView.hidden = FALSE;
    purchaseButtonView.hidden = TRUE;
    downloadButtonView.hidden = TRUE;
    
    activityIndicator.hidden = FALSE;
    [activityIndicator startAnimating];
    [self refresh];
}

-(void)downloadComplete:(NSNotification*)notif
{
    if (notif == nil) // Something went wrong
    {
        [[StoreDataHolder sharedStoreDataHolder] cancelDownload:[storePackage objectForKey:@"paId"]];
    }
    [self setupWithStorePackage:storePackage];
    [self refresh];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.screenName = @"paketinnehall - hamta";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)refresh
{
    [theTable reloadData];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [crosswordIDs count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSLog(@"DisclosureViewController obtain cell");
	static NSString *CellIdentifier = @"StoreItemListCellIdentifier";
    
	StoreItemListCell *cell = (StoreItemListCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *nib;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            nib = [[NSBundle mainBundle] loadNibNamed:@"StoreItemListCell-iPad" owner:self options:nil];
        else
            nib = [[NSBundle mainBundle] loadNibNamed:@"StoreItemListCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
	
    int row = [indexPath row];
    NSDictionary *rowDic = [[StoreDataHolder sharedStoreDataHolder].storeCrosswords objectAtIndex:[[StoreDataHolder sharedStoreDataHolder].storeCrosswordIds indexOfObject:[crosswordIDs objectAtIndex:row]]];
        
    BOOL downloadedAlready = [[DataHolder sharedDataHolder] alreadyOwnsCrossword:[crosswordIDs objectAtIndex:row]];
    NSString *competitionEnd = [rowDic objectForKey:@"competitionEnd"];
    long competitionEndSeconds = [competitionEnd longLongValue]/1000;
    BOOL competition = (competitionEndSeconds > [[NSDate date] timeIntervalSince1970]);
    
    // Show "Already owned" text only if entire package has not yet been downloaded
    [cell setName:[[DataHolder sharedDataHolder] getHeadlineFromCrossword:rowDic] setterInfo:[[DataHolder sharedDataHolder] getDescriptionFromCrossword:rowDic] alreadyOwned:downloadedAlready && downloadedSignView.hidden];
    [cell setAsDownloaded:downloadedAlready];
    [cell setCompetitionActive:competition];
    if (!downloadingSignView.hidden && !downloadedAlready)
        [cell showSpinWheel];
    else
        [cell hideSpinWheel];
    
	return cell;
}

-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return TABLE_ROW_HEIGHT_IPAD;
    else
        return TABLE_ROW_HEIGHT_IPHONE;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    DataHolder *myData = [DataHolder sharedDataHolder];
    SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
//    [delegate showPreviewWithCrossword:[[StoreDataHolder sharedStoreDataHolder].storeCrosswords objectForKey:[crosswordIDs objectAtIndex:[indexPath row]]]];
    NSNumber *cwId = [crosswordIDs objectAtIndex:indexPath.row];
    
    if ([myData alreadyOwnsCrossword:[crosswordIDs objectAtIndex:indexPath.row]])
    {
        myData.currentCrossword = [myData getCrosswordFromID:cwId];
        [delegate showCrosswordView];
    }
    else
        [delegate showPreviewWithPackage:storePackage andCrosswordID:cwId];
}


#pragma mark -
#pragma mark Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(BOOL)shouldAutorotate
{
    return TRUE;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

@end
