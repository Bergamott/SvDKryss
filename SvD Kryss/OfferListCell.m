//
//  OfferListCell.m
//  SvD Kryss
//
//  Created by Karl on 2013-02-01.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import "OfferListCell.h"

@implementation OfferListCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)setTitle:(NSString*)ti andSpecs:(NSString*)sp
{
    headline.text = ti;
    specs.text = sp;
}

-(void)setPackageTag:(int)t
{
    self.tag = t;
}

-(void)setPrice:(NSNumber*)pr
{
    if ([pr intValue] == 0)
        priceTag.text = @"Gratis";
    else
        priceTag.text = [NSString stringWithFormat:@"%d,%02d kr",([pr intValue]/100),([pr intValue]%100)];
}

-(void)setPrice:(NSNumber*)pr withSubscriberCost:(NSNumber*)sc
{
    if (sc != NULL && [sc intValue] == 0)
        priceTag.text = @"Ingår";
    else if ([pr intValue] == 0)
        priceTag.text = @"Gratis";
    else
        priceTag.text = [NSString stringWithFormat:@"%d,%02d kr",([pr intValue]/100),([pr intValue]%100)];
}

-(void)setPriceString:(NSString*)ps
{
    priceTag.text = ps;
}

-(void)setStatusDownloaded
{
    priceTag.text = @"Nedladdat";
}

-(void)setStatusNotDownloaded
{
    priceTag.text = @"Ladda ned";
}


@end
