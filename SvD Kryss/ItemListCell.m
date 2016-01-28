//
//  ItemListCell.m
//  SvD Kryss
//
//  Created by Karl on 2013-01-22.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import "ItemListCell.h"
#import "ProgressView.h"

@implementation ItemListCell

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

-(void)setName:(NSString*)na description:(NSString*)de andType:(NSString*)tp
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        headline.text = na;
        specs.text = de;
    }
    else
    {
        headline.text = [NSString stringWithFormat:@"%@ %@",na,de];
        specs.text = [tp capitalizedString];
    }
}

-(void)setTitle:(NSString*)ti andDescription:(NSString*)de
{
    headline.text = ti;
    specs.text = de;
}

/*-(void)setHeadline:(NSString*)h1 subtitle:(NSString*)h2 andSpecs:(NSString*)sp
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        headline.text = h1;
    }
    else
    {
        headline.text = [NSString stringWithFormat:@"%@ %@",h1,h2];
    }
    specs.text = sp;
}*/

-(void)setIconImage:(UIImage*)img
{
    icon.image = img;
}

-(void)setCompetitionActive:(BOOL)act
{
    competitionFlag.hidden = !act;
}

-(void)setPercentageFilledIn:(int)pc
{
    if (pc == 0)
    {
        solvedText.hidden = TRUE;
        solvedProgress.hidden = TRUE;
    }
    else
    {
        solvedText.hidden = FALSE;
        solvedProgress.hidden = FALSE;
//        solvedProgress.progress = 0.01*pc;
        [solvedProgress setValue:pc];
        solvedText.text = [NSString stringWithFormat:@"%d\%% ifyllt",pc];
    }
}

-(void)setAsDownloaded:(BOOL)dwl onStartedScreen:(BOOL)ss
{
    if (dwl)
        icon.alpha = 1.0;
    else
        icon.alpha = 0.5;
    arrowIcon.hidden = !dwl;
    infoIcon.hidden = dwl;
    infoIcon.highlighted = ss;
    spinWheel.hidden = TRUE;
    [spinWheel stopAnimating];
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
