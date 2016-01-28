//
//  StorePackageViewController.m
//  SvD Kryss
//
//  Created by Karl on 2013-02-04.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import "StorePackageViewController.h"
#import "SoundManager.h"
#import "SvDKryssAppDelegate.h"
#import "StoreDataHolder.h"
#import "DataHolder.h"
#import "OfferListCell.h"
#import "InAppPurchaseManager.h"
#import "CustomAlertView.h"
#import "LayoutView.h"
#import "DownloadManager.h"

@interface StorePackageViewController ()

@end

@implementation StorePackageViewController

@synthesize theCategory;
@synthesize popoverController;

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [layoutView determineMargins];
    self.screenName = @"paketkategori - hamta";
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setupWithCategory:(NSDictionary*)cat;
{
    theCategory = [cat mutableCopy];
    headline.text = [cat objectForKey:@"name"];
//    subtitle.text = [NSString stringWithFormat:@"Här är samtliga %@ som finns för SvD Korsord",hl];
    subtitle.text = [cat objectForKey:@"description"];
    [theTable reloadData];
    [layoutView fillUp];
}

-(IBAction)backButtonPressed:(id)sender
{
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
//    [delegate goBackToCategoryView];
    [delegate goBack];
}

-(void)refresh
{

    [theTable reloadData];

    if (((NSArray*)[theCategory objectForKey:@"packages"]).count == 0) // All empty. Go back to category list
    {
        NSLog(@"Empty. Going back.");
        [self backButtonPressed:NULL];
    }
}

#pragma mark -
#pragma mark Package info / purchase methods

/*-(IBAction)infoPressed:(id)sender
{
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    UIButton *tmpB = (UIButton*)sender;

    NSDictionary *tmpP = [[StoreDataHolder sharedStoreDataHolder] getPackageFromNumber:tmpB.tag];
    NSArray *tmpA = [tmpP objectForKey:@"crosswords"];
    NSString *infoString = [NSString stringWithFormat:@"%@ innehåller följande kryss:\n",[tmpP objectForKey:@"headline"]];

    int counter = 0;
    BOOL alreadyHas = FALSE;
    for (NSString *tmpS in tmpA)
    {
        counter++;
        NSDictionary *tmpD = [[StoreDataHolder sharedStoreDataHolder].storeCrosswords objectForKey:tmpS];
        infoString = [infoString stringByAppendingFormat:@"\n%d. %@, %@",counter,[tmpD objectForKey:@"title"],[tmpD objectForKey:@"subtitle"]];
        NSLog(@"%@",tmpS);
        if ([[DataHolder sharedDataHolder] alreadyOwnsCrossword:tmpS])
        {
            alreadyHas = TRUE;
            infoString = [infoString stringByAppendingString:@" «"];
        }
    }
    if (alreadyHas)
        infoString = [infoString stringByAppendingString:@"\n\n« Redan köpt i annat paket"];
    CGSize tmpSz = [infoString sizeWithFont:[UIFont systemFontOfSize:14.0] constrainedToSize:CGSizeMake(400.0, 1000.0) lineBreakMode:NSLineBreakByWordWrapping];
    UITextView *tmpTX = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 400, tmpSz.height)];
    tmpTX.backgroundColor = [UIColor darkGrayColor];
    tmpTX.textColor = [UIColor whiteColor];
    tmpTX.font = [UIFont systemFontOfSize:14.0];
    tmpTX.text = infoString;
    UIViewController* popoverContent = [[UIViewController alloc]
                                        init];
    popoverContent.view = tmpTX;
    
    // Put in some margin for the text view
    popoverContent.contentSizeForViewInPopover = CGSizeMake(tmpSz.width + 24.0, tmpSz.height + 24.0);
    
    //create a popover controller
    self.popoverController = [[UIPopoverController alloc]
                              initWithContentViewController:popoverContent];
    
    CGRect tmpR = [self.view convertRect:CGRectMake(0,0,tmpB.frame.size.width,tmpB.frame.size.height) fromView:tmpB];
    
    [popoverController presentPopoverFromRect:tmpR inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:FALSE];
    //release the popover content
    [popoverContent release];
    [tmpTX release];
}*/

/*-(IBAction)purchasePressed:(id)sender
{
    NSLog(@"Trying to purchase selected package");
    int tmpTag = ((UIButton*)sender).tag;
    NSDictionary *tmpP = [[StoreDataHolder sharedStoreDataHolder] getPackageFromNumber:tmpTag];
    OfferListCell *tmpOLC = [self findCellForTag:tmpTag];
    [tmpOLC markAsDownloading];
    [[InAppPurchaseManager sharedInAppPurchaseManager] mockPurchasePackage:tmpP];
}*/

-(OfferListCell*)findCellForTag:(int)tg
{
    NSArray *tmpA = [theTable visibleCells];
    OfferListCell *olc = NULL;
    for (OfferListCell *tmpC in tmpA)
    {
        if (tmpC.tag == tg)
        {
            olc = tmpC;
        }
    }
    return olc;
}
/*
-(OfferListCell*)findCellForPackageId:(NSString*)pId
{
    return [self findCellForTag:[[StoreDataHolder sharedStoreDataHolder] getPackageNumberFromId:pId]];
}*/

-(void)downloadComplete:(NSNotification*)notif
{
    [theTable reloadData];
}

#pragma mark -
#pragma mark Alert view delegate method

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{

}

#pragma mark -
#pragma mark Table data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSArray *tmpA = [theCategory objectForKey:@"packages"];
    int listLength;
    NSMutableArray *newPackageList = [[NSMutableArray alloc] initWithCapacity:[tmpA count]];
    for (NSNumber *tmpN in tmpA)
    {
        if ([[StoreDataHolder sharedStoreDataHolder].storePackageIds containsObject:tmpN])
            [newPackageList addObject:tmpN];
    }
    listLength = [newPackageList count];
    if (listLength < [tmpA count])
        [theCategory setValue:newPackageList forKey:@"packages"];
    [newPackageList release];

    NSLog(@"StorePackageViewController number of packages: %d",listLength);
    return listLength;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSLog(@"StorePackageViewController obtain cell");
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
    
    NSArray *tmpA = [theCategory objectForKey:@"packages"];
    NSDictionary *tmpP = [[StoreDataHolder sharedStoreDataHolder] getPackageFromId:[tmpA objectAtIndex:[indexPath row]]];
    
    [self fillCell:cell withDataFromPackage:tmpP];
    
	return cell;
}


-(void)fillCell:(OfferListCell*)ce withDataFromPackage:(NSDictionary*)pa
{
//    NSString *title = [pa objectForKey:@"name"];
    NSString *title = [[DataHolder sharedDataHolder] getHeadlineFromPackage:pa];

    NSString *specs = [[StoreDataHolder sharedStoreDataHolder] getContentDescriptionFromPackage:pa];
    
    [ce setTitle:title andSpecs:specs];
    packageState tmpS = packageNotBought;
    NSNumber *tmpId = [pa objectForKey:@"paId"];
    if ([[DataHolder sharedDataHolder] isPackageFullyDownloaded:tmpId])
        tmpS = packageDownloaded;
    else if ([[StoreDataHolder sharedStoreDataHolder] hasPurchasedPackage:tmpId])
        tmpS = packageBoughtButNotDownloaded;
    else if ([[StoreDataHolder sharedStoreDataHolder] isBeingDownloaded:tmpId])
        tmpS = packageDownloading;
    if (tmpS == packageDownloaded)
    {
        [ce setStatusDownloaded];
    }
    else if (tmpS == packageBoughtButNotDownloaded)
    {
        [ce setStatusNotDownloaded];
    }
    else
    {
        [ce setPriceString:[[DownloadManager sharedDownloadManager] getPriceLabelForPackage:pa]];
    }
    [ce setPackageTag:[tmpId intValue]];
}


-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return TABLE_ROW_HEIGHT_IPAD;
    else
        return TABLE_ROW_HEIGHT_IPHONE;
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
