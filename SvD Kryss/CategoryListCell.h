//
//  CategoryListCell.h
//  SvD Kryss
//
//  Created by Karl on 2013-02-04.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import <UIKit/UIKit.h>

#define TABLE_ROW_HEIGHT_IPAD 90
#define TABLE_ROW_HEIGHT_IPHONE 78

@interface CategoryListCell : UITableViewCell {
    
    IBOutlet UILabel *headline;
    IBOutlet UILabel *subtitle;
    IBOutlet UILabel *specs;
}

-(void)setHeadline:(NSString*)hl subtitle:(NSString*)st andSpecs:(NSString*)sp;

@end
