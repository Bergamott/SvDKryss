//
//  StoreItemListCell.h
//  SvD Kryss
//
//  Created by Karl on 2013-02-18.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import <UIKit/UIKit.h>

#define TABLE_ROW_HEIGHT_IPAD 129
#define TABLE_ROW_HEIGHT_IPHONE 90

@interface StoreItemListCell : UITableViewCell {
    IBOutlet UILabel *headline;
    IBOutlet UILabel *specs;
    
    IBOutlet UIImageView *icon;
    IBOutlet UIImageView *competitionFlag;
    
    IBOutlet UILabel *ownedLabel;

    IBOutlet UIImageView *arrowIcon;
    IBOutlet UIImageView *infoIcon;
    IBOutlet UIActivityIndicatorView *spinWheel;
}

-(void)setName:(NSString*)na description:(NSString*)de andType:(NSString*)tp alreadyOwned:(BOOL)ow;
-(void)setIconImage:(UIImage*)img;
-(void)setName:(NSString*)na setterInfo:(NSString*)se alreadyOwned:(BOOL)ow;
-(void)setCompetitionActive:(BOOL)act;

-(void)setAsDownloaded:(BOOL)dwl;
-(void)showSpinWheel;
-(void)hideSpinWheel;

@end
