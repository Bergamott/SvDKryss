//
//  StoreSectionHeader.h
//  SvD Kryss
//
//  Created by Karl on 2013-02-01.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import <UIKit/UIKit.h>

#define SECTION_HEADER_HEIGHT_IPAD 48
#define SECTION_HEADER_HEIGHT_IPHONE 24

@interface StoreSectionHeader : UIView {
    
    IBOutlet UILabel *headline;
}

@property(nonatomic,retain) IBOutlet UILabel *headline;

@end
