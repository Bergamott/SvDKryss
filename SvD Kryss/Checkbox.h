//
//  Checkbox.h
//  XMLTest
//
//  Created by Karl on 2012-12-21.
//
//

#import <UIKit/UIKit.h>

@class FoldDownMenu;

@interface Checkbox : UIButton {
    IBOutlet FoldDownMenu *owner;
}

-(void)setChecked:(BOOL)chkd;

@end
