//
//  CrosswordHolder.h
//  SvD Kryss
//
//  Created by Karl on 2013-01-11.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FakeSegmentedControl.h"
#import "ProgressView.h"

@class OverlayView;
@class Metadata;
@class CrosswordViewController;
@class PDFDisplay;
@class LayoutView;

@interface CrosswordHolder : UIView <FakeSegmentListener,UITextFieldDelegate>{
    
    IBOutlet PDFDisplay *pdfDisplay;
    IBOutlet OverlayView *overlayView;
    IBOutlet CrosswordViewController *owner;
    
    IBOutlet UILabel *clockDigit0;
    IBOutlet UILabel *clockDigit1;
    IBOutlet UILabel *clockDigit2;
    IBOutlet UILabel *clockDigit3;
    IBOutlet UILabel *clockDigit4;
    IBOutlet UILabel *clockDigit5;
    NSArray *clockDigits;
    
    Metadata *myMetadata;
    NSTimer *clockTickTimer;
    NSDate *clockStartTime;
    int clockSeconds;
    BOOL hibernateFlag;
    IBOutlet UILabel *filledInText;
    IBOutlet ProgressView *filledInBar;
    
    IBOutlet UIButton *pencilButton;
    IBOutlet UIButton *markerButton;
    IBOutlet UIImageView *pencilImage;
    IBOutlet UIImageView *markerImage;
    IBOutlet UIButton *pencilButtonLandscape;
    IBOutlet UIButton *markerButtonLandscape;
    IBOutlet UIImageView *pencilImageLandscape;
    IBOutlet UIImageView *markerImageLandscape;
    IBOutlet UIButton *pencilToggleButton;
    IBOutlet UIButton *markerToggleButton;
    IBOutlet UIButton *pencilLandscapeToggleButton;
    IBOutlet UIButton *markerLandscapeToggleButton;
    
    
    // Alert and popovers
    IBOutlet UIView *popoverView;
    IBOutlet UIButton *popoverBackgroundButton;
    IBOutlet LayoutView *fakeAlertView;
    IBOutlet LayoutView *emailView;
    IBOutlet UILabel *addressWarning;
    IBOutlet UITextField *addressField;
    IBOutlet UILabel *fakeAlertHeadline;
    IBOutlet UITextView *fakeAlertText;
    IBOutlet UILabel *fakeCancelLabel;
    IBOutlet UIButton *fakeCancelButton;
    IBOutlet UILabel *fakeOKLabel;
    IBOutlet UIButton *fakeOKButton;
    int fakeAlertTag;
    IBOutlet UIView *clockPopdown;
    IBOutlet UIView *menuPopdown;
    IBOutlet UIImageView *menuBackgroundView;
    IBOutlet UIView *menuBottomRight;

    IBOutlet FakeSegmentedControl *fakeSegmentedControl;
    IBOutlet UIView *showMistakesButtonsView;
    IBOutlet UIView *fillInButtonsView;
    IBOutlet UIButton *competitionButton;
    IBOutlet UILabel *competitionLabel;
    
    float contentWidth;
    float contentHeight;
    
    IBOutlet UIImageView *selection;
}

-(void)setMetadata:(Metadata*)md;

-(IBAction)keyTyped:(id)sender;
-(void)setClockActive:(BOOL)act;
-(IBAction)resetClock:(id)sender;
-(void)realignClock;
-(void)enterBackground;
-(void)enterForeground;
-(void)updateClock;
-(void)setPercentageFilledIn:(int)p;
-(void)periodicSave;
-(void)uploadToServer;
-(void)setMarkerActive:(BOOL)act;

// Methods called from menu
-(IBAction)helpWithCharacterPressed:(id)sender;
-(IBAction)correctCharacterPressed:(id)sender;
-(IBAction)helpWithWordPressed:(id)sender;
-(IBAction)correctWordPressed:(id)sender;
-(IBAction)helpWithAllPressed:(id)sender;
-(IBAction)clueTypeChanged:(id)sender;
-(IBAction)resetButtonClicked:(id)sender;
-(IBAction)correctAllButtonClicked:(id)sender;
-(void)startOverConfirmed;
-(void)correctAllConfirmed;
-(void)adjustMenu;

// iPad actions
-(IBAction)markerPressed:(id)sender;
-(IBAction)pencilPressed:(id)sender;
// iPhone actions
-(IBAction)markerTogglePressed:(id)sender;
-(IBAction)pencilTogglePressed:(id)sender;

// Alert and popover views
-(IBAction)popoverBackgroundClicked:(id)sender;
-(void)hidePopdowns;
-(IBAction)clockButtonClicked:(id)sender;
-(IBAction)menuButtonClicked:(id)sender;
-(void)setAlertHeadline:(NSString*)hl andText:(NSString*)tx andCancel:(NSString*)cc andOK:(NSString*)ok andTag:(int)tg;
-(IBAction)fakeAlertCancelClicked:(id)sender;
-(IBAction)fakeAlertOKClicked:(id)sender;

-(void)sendGAEvent:(NSString*)action;

-(void)setPDFURL:(NSURL*)url content:(CGRect)ct andScale:(float)sc;
-(float)getContentWidth;
-(float)getContentHeight;
-(void)refreshCrossword;

// Gestures
-(void)setupGestures;
-(void)handleSingleTap:(UIGestureRecognizer *)gestureRecognizer;
-(void)handleDoubleTap:(UIGestureRecognizer *)gestureRecognizer;

// Competition
-(IBAction)competitionButtonPressed:(id)sender;
-(IBAction)confirmEmailCompetition:(id)sender;

-(void)seeIfWeNeedSyncing;

-(BOOL)NSStringIsValidEmail:(NSString *)checkString;

-(void)startPulsatingIcon;

@property(nonatomic,retain) Metadata *myMetadata;
@property(nonatomic,retain) NSArray *clockDigits;

@end
