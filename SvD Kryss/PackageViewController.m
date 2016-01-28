//
//  PackageViewController.m
//  SvD Kryss
//
//  Created by Karl on 2013-01-22.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import "PackageViewController.h"
#import "SvDKryssAppDelegate.h"
#import "PackageListCell.h"
#import "DataHolder.h"
#import "SoundManager.h"
#import "LayoutView.h"
#import "InAppPurchaseManager.h"

#define PACKAGE_ROW_HEIGHT_IPHONE 67
#define PACKAGE_ROW_HEIGHT_IPAD 129

@interface PackageViewController ()

@end

@implementation PackageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Register notification for when purchases are restored
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(refresh)
                                                     name:kInAppPurchaseManagerDownloadComplete
                                                   object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.screenName = @"mina korsordspaket";
    myData = [DataHolder sharedDataHolder];
    
    NSArray *nib;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        nib = [[NSBundle mainBundle] loadNibNamed:@"PackageSectionFooter-iPad" owner:self options:nil];
    else
        nib = [[NSBundle mainBundle] loadNibNamed:@"PackageSectionFooter" owner:self options:nil];
    LayoutView *footer = (LayoutView*)[nib objectAtIndex:0];
    [footer determineMargins];
    [footer pack];
    theTable.tableFooterView = footer;
}

-(BOOL)prefersStatusBarHidden {
    return YES;
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

-(IBAction)backButtonPressed:(id)sender
{
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
//    [delegate showInitialView];
    [delegate goBack];
}

-(IBAction)restorePurchasesPressed:(id)sender
{
    NSLog(@"Restore purchases pressed");
    [[InAppPurchaseManager sharedInAppPurchaseManager] restoreAllPurchases];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [myData.myPackageIds count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	static NSString *CellIdentifier = @"PackageListCellIdentifier";
		
	PackageListCell *cell = (PackageListCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *nib;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            nib = [[NSBundle mainBundle] loadNibNamed:@"PackageListCell-iPad" owner:self options:nil];
        else
            nib = [[NSBundle mainBundle] loadNibNamed:@"PackageListCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
	
    int row = [indexPath row];
    NSDictionary *rowDic = [myData getMyPackageNumbered:row];
    
    NSString *headline = [myData getHeadlineFromPackage:rowDic];
    
    NSString *specs = [myData getContentDescriptionFromPackage:rowDic];
    
    cell.owner = self;
    [cell setTitle:headline rowNumber:(int)indexPath.row andSpecs:specs];
    [cell setAllCrosswordsDownloaded:[myData haveAllCrosswordsBeenDownloaded:rowDic] andDefault:[myData isPackagePartOfDefault:[rowDic objectForKey:@"paId"]]];
    
	return cell;
	
}

-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return PACKAGE_ROW_HEIGHT_IPAD;
    else
        return PACKAGE_ROW_HEIGHT_IPHONE;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
   [delegate showItemViewWithPackage:[myData getMyPackageNumbered:[indexPath row]]];
}

-(void)hideAllDeleteButtons
{
    for (PackageListCell *tmpC in theTable.visibleCells)
        [tmpC hideDeleteView];
}

-(void)clearCrosswordsForCellRow:(int)r
{
    NSLog(@"Clearing crosswords for cell row %d",r);
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    [myData clearCrosswordsInPackageNumber:r];
    [self refresh];
}

#pragma mark -
#pragma Rotation

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
