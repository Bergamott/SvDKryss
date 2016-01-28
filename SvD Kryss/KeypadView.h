//
//  KeypadView.h
//  SvD Kryss
//
//  Created by Karl on 2013-01-11.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KeypadView : UIView {
    
    IBOutlet UIView *keyPopup;
    IBOutlet UILabel *keyPopupCharacter;
}

-(void)showPopupAtKey:(UIButton*)key withText:(NSString*)txt;
-(void)showWidePopupAtKey:(UIButton*)key withText:(NSString*)txt;
-(void)hidePopup;
-(IBAction)portraitKeyDown:(id)sender;
-(IBAction)portraitKeyUp:(id)sender;
-(IBAction)portraitKeyCancel:(id)sender;
-(IBAction)landscapeKeyDown:(id)sender;
-(IBAction)landscapeKeyUp:(id)sender;
-(IBAction)landscapeKeyCancel:(id)sender;

@end
