//
//  OfferListCell.h
//  SvD Kryss
//
//  Created by Karl on 2013-02-01.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import <UIKit/UIKit.h>

#define TABLE_ROW_HEIGHT_IPAD 129
#define TABLE_ROW_HEIGHT_IPHONE 92


typedef enum {
    packageNotBought,
    packageBoughtButNotDownloaded,
    packageDownloading,
    packageDownloaded
} packageState;

@interface OfferListCell : UITableViewCell {
    
    IBOutlet UILabel *headline;
    IBOutlet UILabel *specs;
    
    IBOutlet UIImageView *icon;
    IBOutlet UILabel *priceTag;
}

-(void)setTitle:(NSString*)ti andSpecs:(NSString*)sp;
-(void)setPackageTag:(int)t;
-(void)setPrice:(NSNumber*)pr;
-(void)setPrice:(NSNumber*)pr withSubscriberCost:(NSNumber*)sc;
-(void)setPriceString:(NSString*)ps;
-(void)setStatusDownloaded;
-(void)setStatusNotDownloaded;

@end
