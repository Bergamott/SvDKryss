//
//  PackageListCell.m
//  SvD Kryss
//
//  Created by Karl on 2013-01-22.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import "PackageListCell.h"
#import "PackageViewController.h"

@implementation PackageListCell

@synthesize owner;

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

-(void)setTitle:(NSString*)ti rowNumber:(int)rn andSpecs:(NSString*)sp;
{
    headline.text = ti;
    specs.text = sp;
    rowNumber = rn;
}

-(void)setAllCrosswordsDownloaded:(BOOL)dwl andDefault:(BOOL)def
{
    if (dwl)
        icon.alpha = 1.0;
    else
        icon.alpha = 0.5;
    downloadBadge.hidden = dwl;
    
    deleteView.hidden = TRUE;
    if (dwl && !def) // Should be possible to delete
    {
        if (self.gestureRecognizers.count == 0)
        {
            UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
            // Setting the swipe direction.
            [swipeLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
            // Adding the swipe gesture on image view
            [self addGestureRecognizer:swipeLeft];
        }
    }
    else
    {
        for (UIGestureRecognizer *gr in self.gestureRecognizers)
        {
            [self removeGestureRecognizer:gr];
        }
    }
}

#pragma mark - Deleting packages

-(void)handleSwipe:(UISwipeGestureRecognizer*)swipe
{
    [owner hideAllDeleteButtons];
    deleteView.hidden = FALSE;
}

-(IBAction)hideDeleteViewPressed:(id)sender
{
    deleteView.hidden = TRUE;
}

-(void)hideDeleteView
{
    deleteView.hidden = TRUE;
}

-(IBAction)DeleteConfirmedPressed:(id)sender
{
    [owner clearCrosswordsForCellRow:rowNumber];
}

@end
