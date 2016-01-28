//
//  ItemViewController.m
//  SvD Kryss
//
//  Created by Karl on 2013-01-22.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import "ItemViewController.h"
#import "SvDKryssAppDelegate.h"
#import "ItemListCell.h"
#import "DataHolder.h"
#import "SoundManager.h"
#import "DownloadManager.h"

@interface ItemViewController ()

@end

@implementation ItemViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.screenName = @"paketinnehall - eget";
    myData = [DataHolder sharedDataHolder];
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setUpWithPackage:(NSDictionary*)pk
{
    currentPackage = pk;
    [myData getSubsetFromPackage:pk];
    
    [self refresh];
}

-(void)refresh
{
    headline.text = [myData getHeadlineFromPackage:currentPackage];
    NSString *tmpDesc = [currentPackage objectForKey:@"description"];
    if (tmpDesc == nil || tmpDesc.length == 0)
        subtitle.text = @"Paketet innehåller följande korsord";
    else
        subtitle.text = tmpDesc;
    
    // Adjust table size depending on the download button being visible
    float y = buttonHolderView.frame.origin.y;
    if ([myData haveAllCrosswordsBeenDownloaded:currentPackage])
    {
        buttonHolderView.hidden = TRUE;
    }
    else
    {
        y += buttonHolderView.frame.size.height;
        buttonHolderView.hidden = FALSE;
    }
    theTable.frame = CGRectMake(0,y,self.view.frame.size.width,self.view.frame.size.height - y);

    downloadButtonView.hidden = downloading;
    downloadingSignView.hidden = !downloading;
    spinWheel.hidden = !downloading;
    if (downloading)
        [spinWheel startAnimating];
    else
        [spinWheel stopAnimating];

    [theTable reloadData];
}

-(IBAction)backButtonPressed:(id)sender
{
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
//    [delegate goBackToPackageView];
    [delegate goBack];
}
#pragma mark -
#pragma mark Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [myData.crosswordSubsetList count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	static NSString *CellIdentifier = @"ItemListCellIdentifier";
    
	ItemListCell *cell = (ItemListCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *nib;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            nib = [[NSBundle mainBundle] loadNibNamed:@"ItemListCell-iPad" owner:self options:nil];
        else
            nib = [[NSBundle mainBundle] loadNibNamed:@"ItemListCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
	
    int row = [indexPath row];
    NSDictionary *rowDic = [myData getMyCrosswordNumbered:row];
    
    NSString *crosswordType = [rowDic objectForKey:@"type"];
    
    NSString *competitionEnd = [rowDic objectForKey:@"competitionEnd"];
    long competitionEndSeconds = [competitionEnd longLongValue]/1000;
    BOOL competition = (competitionEndSeconds > [[NSDate date] timeIntervalSince1970]);
//    NSString *percentS = [rowDic objectForKey:@"percentage-solved"];
    NSString *percentS = [[DataHolder sharedDataHolder] getPercentageSolvedForCrosswordId:[rowDic objectForKey:@"cwId"]];
    int partSolved = [percentS intValue];
    
    BOOL downloaded = [myData hasThisCrosswordBeenDownloaded:rowDic];
    [cell setTitle:[myData getHeadlineFromCrossword:rowDic] andDescription:[myData getDescriptionFromCrossword:rowDic]];
    [cell setPercentageFilledIn:partSolved];
    [cell setCompetitionActive:competition];
    [cell setAsDownloaded:downloaded onStartedScreen:FALSE];
    if (downloading && !downloaded)
        [cell showSpinWheel];
    else
        [cell hideSpinWheel];
    
    // Set icon depending on crossword type
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        if ([crosswordType isEqualToString:@"krypto"])
            [cell setIconImage:[UIImage imageNamed:@"krypto_195.png"]];
        else if ([crosswordType isEqualToString:@"ordflata"])
            [cell setIconImage:[UIImage imageNamed:@"ordflata_195.png"]];
        else
            [cell setIconImage:[UIImage imageNamed:@"bildkryss_195.png"]];
    }
    else
    {
        if ([crosswordType isEqualToString:@"krypto"])
            [cell setIconImage:[UIImage imageNamed:@"krypto_110.png"]];
        else if ([crosswordType isEqualToString:@"ordflata"])
            [cell setIconImage:[UIImage imageNamed:@"ordflata_110.png"]];
        else
            [cell setIconImage:[UIImage imageNamed:@"bildkryss_110.png"]];
    }
    
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
    myData.currentCrossword = [myData getMyCrosswordNumbered:[indexPath row]];
    SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
    if ([myData.currentCrossword objectForKey:@"downloaded"] != NULL)
        [delegate showCrosswordView];
    else
        [delegate showPreviewWithPackage:currentPackage andCrosswordID:[myData.currentCrossword objectForKey:@"cwId"]];
}

#pragma mark -
#pragma mark Download methods

-(IBAction)downloadButtonPressed:(id)sender
{
    downloading = TRUE;
    [[DownloadManager sharedDownloadManager] completePackage:currentPackage];
    [self refresh];
}

-(void)downloadingDone
{
    downloading = FALSE;
    if ([myData haveAllCrosswordsBeenDownloaded:currentPackage])
    {
        [self setUpWithPackage:currentPackage];
    }
    else
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
