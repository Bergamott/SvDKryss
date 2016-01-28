//
//  ItemListCell.h
//  SvD Kryss
//
//  Created by Karl on 2013-01-22.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import <UIKit/UIKit.h>

#define TABLE_ROW_HEIGHT_IPAD 129
#define TABLE_ROW_HEIGHT_IPHONE 90

@class ProgressView;

@interface ItemListCell : UITableViewCell {
    
    IBOutlet UILabel *headline;
    IBOutlet UILabel *specs;
    
    IBOutlet UIImageView *icon;
    IBOutlet UIImageView *competitionFlag;
    
    IBOutlet UILabel *solvedText;
    IBOutlet ProgressView *solvedProgress;
    
    IBOutlet UIImageView *arrowIcon;
    IBOutlet UIImageView *infoIcon;
    IBOutlet UIActivityIndicatorView *spinWheel;
}

//-(void)setHeadline:(NSString*)h1 subtitle:(NSString*)h2 andSpecs:(NSString*)sp;
-(void)setName:(NSString*)na description:(NSString*)de andType:(NSString*)tp;
-(void)setTitle:(NSString*)ti andDescription:(NSString*)de;
-(void)setIconImage:(UIImage*)img;
-(void)setCompetitionActive:(BOOL)act;
-(void)setPercentageFilledIn:(int)pc;
-(void)setAsDownloaded:(BOOL)dwl onStartedScreen:(BOOL)ss;
-(void)showSpinWheel;
-(void)hideSpinWheel;

@end
