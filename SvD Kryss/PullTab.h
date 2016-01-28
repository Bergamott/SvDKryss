//
//  PullTab.h
//  XMLTest
//
//  Created by Karl on 2012-12-21.
//
//

#import <UIKit/UIKit.h>

@class FoldDownMenu;

@interface PullTab : UIView {
    float downX;
    float startX;
    
    IBOutlet UIImageView *button;
    BOOL buttonHighlighted;
    IBOutlet FoldDownMenu *owner;
}

-(void)resetToHidden;

@end
