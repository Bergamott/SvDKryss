//
//  CrosswordViewController.h
//  SvD Kryss
//
//  Created by Karl on 2013-01-09.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#include <sys/types.h>
#include <sys/sysctl.h>

#import <UIKit/UIKit.h>

#import "GAITrackedViewController.h"

#define SAVE_INTERVAL 15.0

@class KeypadView;
@class CrosswordHolder;

@interface CrosswordViewController : GAITrackedViewController <UIScrollViewDelegate> {
    
    float topBarHeight;
    IBOutlet UIScrollView *scrollView;
    IBOutlet CrosswordHolder *crosswordHolder;
    
    IBOutlet UIView *topBar;
    
    IBOutlet KeypadView *portraitKeyboard;
    IBOutlet KeypadView *landscapeKeyboard;
    
    IBOutlet UILabel *clockStartLabel;
    IBOutlet UILabel *clockStopLabel;
    
    BOOL portraitMode;
    BOOL keyboardVisible;
    
    NSTimer *saveTimer;
    
    IBOutlet UIImageView *portraitKeyboardShadow;
    IBOutlet UIImageView *landscapeKeyboardShadow;
    
    float maxZoomScale;
}

-(void)initiateWithCurrentCrossword;

-(void)showKeyboard;
-(void)hideKeyboard;
-(void)needsKeyboard;
-(void)adjustZoomScale;
-(void)zoomToContent;
-(void)zoomToRect:(CGRect)r;
-(void)doubleTapZoomToPoint:(CGPoint)p;
-(void)panToCursor:(CGRect)cu;



-(void)periodicSave;

#pragma mark -
#pragma mark Leaving or entering foreground

-(void)enterBackground;
-(void)enterForeground;


#pragma mark -
#pragma mark Menu-called methods

-(IBAction)backButtonPressed:(id)sender;

-(IBAction)hideKeyboardPressed:(id)sender;
-(IBAction)toggleClock:(id)sender;
-(void)setClockActive:(BOOL)act;

#pragma mark -
#pragma mark Switching screens

-(void)prepareToLeave;
-(void)jumpBackToMainMenu;

#pragma mark -
#pragma mark Scaling stuff

-(NSString*)platform;
-(float)determineScaleFactorFromWidth:(float)w andHeight:(float)h;

#pragma mark -
#pragma mark For proper centering

-(void)view:(UIView*)view setCenter:(CGPoint)centerPoint;

@end
