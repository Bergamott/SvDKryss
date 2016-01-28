//
//  StoreSectionHeader.m
//  SvD Kryss
//
//  Created by Karl on 2013-02-01.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import "StoreSectionHeader.h"

@implementation StoreSectionHeader

@synthesize headline;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
    [headline release];
}


@end
