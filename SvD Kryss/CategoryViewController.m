//
//  CategoryViewController.m
//  SvD Kryss
//
//  Created by Karl on 2013-02-01.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import "CategoryViewController.h"
#import "SvDKryssAppDelegate.h"
#import "SoundManager.h"
#import "StoreDataHolder.h"
#import "DataHolder.h"
#import "CategoryListCell.h"

@interface CategoryViewController ()

@end

@implementation CategoryViewController

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
    self.screenName = @"samtliga paket - hamta";
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

-(void)setup
{
    [self refresh];
}

-(void)refresh
{
    [theTable reloadData];
}

-(IBAction)backButtonPressed:(id)sender
{
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
//    [delegate goBackToStoreView];
    [delegate goBack];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark Table data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"CategoryViewController number of categories: %d",[[StoreDataHolder sharedStoreDataHolder] numberOfCategories]);
    return [[StoreDataHolder sharedStoreDataHolder] numberOfCategories];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	static NSString *CellIdentifier = @"CategoryListCellIdentifier";
    
	CategoryListCell *cell = (CategoryListCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *nib;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            nib = [[NSBundle mainBundle] loadNibNamed:@"CategoryListCell-iPad" owner:self options:nil];
        else
            nib = [[NSBundle mainBundle] loadNibNamed:@"CategoryListCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    NSDictionary *tmpP = [[StoreDataHolder sharedStoreDataHolder] categoryAtRow:[indexPath row]];
    
    NSString *title = [tmpP objectForKey:@"name"];
    NSString *subtitle = [tmpP objectForKey:@"description"];
    NSArray *packagesInCategory = [tmpP objectForKey:@"packages"];
    int alreadyOwned = [[DataHolder sharedDataHolder] numberOfPackagesAlreadyOwned:packagesInCategory];
    
    NSString *description;
    if (alreadyOwned == 0)
        description = [NSString stringWithFormat:@"Det finns %d %@.",[packagesInCategory count],[title lowercaseString]];
    else if (alreadyOwned == 1)
        description = [NSString stringWithFormat:@"Det finns %d %@ varav 1 är nedladdat.",[packagesInCategory count],[title lowercaseString]];
    else
        description = [NSString stringWithFormat:@"Det finns %d %@ varav %d är nedladdade.",[packagesInCategory count], [title lowercaseString], alreadyOwned];
    
    [cell setHeadline:title subtitle:subtitle andSpecs:description];
//    [cell setIconImage:[UIImage imageNamed:[NSString stringWithFormat:@"category%@.png",[tmpP objectForKey:@"type"]]]];
    
	return cell;
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
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
    [delegate showStorePackageViewForCategory:[[StoreDataHolder sharedStoreDataHolder] categoryAtRow:[indexPath row]]];
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
