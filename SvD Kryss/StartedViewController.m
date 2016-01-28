//
//  StartedViewController.m
//  SvD Kryss
//
//  Created by Karl on 2013-01-30.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import "StartedViewController.h"
#import "DataHolder.h"
#import "SoundManager.h"
#import "SvDKryssAppDelegate.h"
#import "ItemViewController.h"
#import "ItemListCell.h"
#import "SoundManager.h"

@interface StartedViewController ()

@end

@implementation StartedViewController

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
    self.screenName = @"paborjade korsord";
    myData = [DataHolder sharedDataHolder];
    [fakeSegmentedControl setup];
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

-(void)setUp
{
    int filteringMode = fakeSegmentedControl.selectedSegmentIndex;
    if (filteringMode == FILTER_ALL)
        [[DataHolder sharedDataHolder] getListOfStartedCrosswords];
    else if (filteringMode == FILTER_MONTH)
        [[DataHolder sharedDataHolder] getListOfStartedCrosswordsSince:[NSDate dateWithTimeIntervalSinceNow:-3600*24*30]];
    else // Week
        [[DataHolder sharedDataHolder] getListOfStartedCrosswordsSince:[NSDate dateWithTimeIntervalSinceNow:-3600*24*7]];
    [theTable reloadData];
}

-(IBAction)backButtonPressed:(id)sender
{
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
//    [delegate showInitialView];
    [delegate goBack];
}

-(void)refresh
{
    [theTable reloadData];
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
    
    [cell setTitle:[myData getHeadlineFromCrossword:rowDic] andDescription:[myData getDescriptionFromCrossword:rowDic]];
    [cell setPercentageFilledIn:partSolved];
    [cell setCompetitionActive:competition];
    [cell setAsDownloaded:[myData hasThisCrosswordBeenDownloaded:rowDic] onStartedScreen:TRUE];
    
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
        [delegate showItemViewWithPackage:[myData getPackageThatContainsCrossword:[myData.currentCrossword objectForKey:@"cwId"]]];
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

#pragma mark -

-(void)fakeSegmentChanged:(id)sender;
{
    [self setUp];
}

#pragma mark -

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
