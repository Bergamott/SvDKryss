//
//  CategoryListCell.m
//  SvD Kryss
//
//  Created by Karl on 2013-02-04.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import "CategoryListCell.h"

@implementation CategoryListCell

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

-(void)setHeadline:(NSString*)hl subtitle:(NSString*)st andSpecs:(NSString*)sp
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        headline.text = hl;
        subtitle.text = st;
    }
    else
    {
        // Both on the same line
        if (st != NULL)
            headline.text = [NSString stringWithFormat:@"%@ – %@",hl,st];
        else
            headline.text = hl;
    }
    specs.text = sp;
}

@end
