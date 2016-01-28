//
//  KeypadView.m
//  SvD Kryss
//
//  Created by Karl on 2013-01-11.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import "KeypadView.h"

@implementation KeypadView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(IBAction)portraitKeyDown:(id)sender
{
    UIButton *tmpB = (UIButton*)sender;
    [self showPopupAtKey:tmpB withText:[NSString stringWithFormat:@"%C",(short)tmpB.tag]];
}

-(IBAction)portraitKeyUp:(id)sender
{
    [self hidePopup];
}

-(IBAction)portraitKeyCancel:(id)sender
{
    [self hidePopup];
}

-(void)showPopupAtKey:(UIButton*)key withText:(NSString*)txt
{
    keyPopupCharacter.text = txt;
    keyPopup.frame = CGRectMake(key.frame.origin.x-25.0,key.frame.origin.y-65.0,keyPopup.frame.size.width,keyPopup.frame.size.height);
    keyPopup.hidden = FALSE;
}

-(void)hidePopup
{
    keyPopup.hidden = TRUE;
}

-(IBAction)landscapeKeyDown:(id)sender
{
    UIButton *tmpB = (UIButton*)sender;
    [self showWidePopupAtKey:tmpB withText:[NSString stringWithFormat:@"%C",(short)tmpB.tag]];
}

-(IBAction)landscapeKeyUp:(id)sender
{
    [self hidePopup];
}

-(IBAction)landscapeKeyCancel:(id)sender
{
    [self hidePopup];
}

-(void)showWidePopupAtKey:(UIButton*)key withText:(NSString*)txt
{
    keyPopupCharacter.text = txt;
    keyPopup.frame = CGRectMake(key.frame.origin.x-20.0,key.frame.origin.y-77.0,keyPopup.frame.size.width,keyPopup.frame.size.height);
    keyPopup.hidden = FALSE;
}


@end
