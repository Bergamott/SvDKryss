//
//  PackageListCell.h
//  SvD Kryss
//
//  Created by Karl on 2013-01-22.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import <UIKit/UIKit.h>

#define TABLE_ROW_HEIGHT_IPAD 129
#define TABLE_ROW_HEIGHT_IPHONE 90

@class PackageViewController;

@interface PackageListCell : UITableViewCell {
    IBOutlet UILabel *headline;
    IBOutlet UILabel *specs;
    
    IBOutlet UIImageView *icon;
    IBOutlet UIView *downloadBadge;
    
    IBOutlet UIView *deleteView;
    
    PackageViewController *owner;
    
    int rowNumber;
}

-(void)setTitle:(NSString*)ti rowNumber:(int)rn andSpecs:(NSString*)sp;
-(void)setAllCrosswordsDownloaded:(BOOL)dwl andDefault:(BOOL)def;

-(void)handleSwipe:(UISwipeGestureRecognizer*)swipe;
-(IBAction)hideDeleteViewPressed:(id)sender;
-(void)hideDeleteView;
-(IBAction)DeleteConfirmedPressed:(id)sender;

@property (nonatomic,retain) PackageViewController *owner;

@end
