//
//  LayoutView.h
//  AutoLayout
//
//  Created by Karl on 2013-06-25.
//  Copyright (c) 2013 Eweguo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LayoutView : UIView {
    
    float topMargins[100];
    float bottomMargin;
    float originalHeight;
    float combinedHeight;
}

-(void)determineMargins;
-(void)resizeSweep;
-(void)pack;
-(void)fillUp;

@end
