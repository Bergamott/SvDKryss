//
//  StoreItemListCell.m
//  SvD Kryss
//
//  Created by Karl on 2013-02-18.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import "StoreItemListCell.h"

@implementation StoreItemListCell

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

-(void)setName:(NSString*)na description:(NSString*)de andType:(NSString*)tp alreadyOwned:(BOOL)ow;
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        headline.text = na;
        if (ow)
            specs.text = [NSString stringWithFormat:@"%@, redan ägt",de];
        else
            specs.text = de;
    }
    else
    {
        headline.text = [NSString stringWithFormat:@"%@ %@",na,de];
        if (ow)
            specs.text = [NSString stringWithFormat:@"%@, redan ägt",[tp capitalizedString]];
        else
            specs.text = tp;
    }
}

-(void)setIconImage:(UIImage*)img
{
    icon.image = img;
}

-(void)setName:(NSString*)na setterInfo:(NSString*)se alreadyOwned:(BOOL)ow
{
    headline.text = na;
    if (ownedLabel != NULL)
    {
        specs.text = se;
        if (ow)
            ownedLabel.text = @"(redan ägt)";
        else
            ownedLabel.text = @"";
    }
    else
    {
        if (ow)
            specs.text = [NSString stringWithFormat:@"%@ (redan ägt)",se];
        else
            specs.text = se;
    }
}


-(void)setAsDownloaded:(BOOL)dwl;
{
    arrowIcon.hidden = !dwl;
    infoIcon.hidden = dwl;
    spinWheel.hidden = TRUE;
    [spinWheel stopAnimating];
}

-(void)setCompetitionActive:(BOOL)act
{
    competitionFlag.hidden = !act;
}

-(void)showSpinWheel
{
    infoIcon.hidden = TRUE;
    spinWheel.hidden = FALSE;
    [spinWheel startAnimating];
}

-(void)hideSpinWheel
{
    if (arrowIcon.hidden)
        infoIcon.hidden = FALSE;
    spinWheel.hidden = TRUE;
    [spinWheel stopAnimating];
}

@end
