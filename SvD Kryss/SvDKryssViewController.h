//
//  SvDKryssViewController.h
//  SvD Kryss
//
//  Created by Karl on 2013-01-09.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#include <sys/types.h>
#include <sys/sysctl.h>

#import <UIKit/UIKit.h>

#import "GAITrackedViewController.h"

@class LayoutView;

@interface SvDKryssViewController : GAITrackedViewController <UITextFieldDelegate,UIAlertViewDelegate,
UIWebViewDelegate> {
    
    IBOutlet UIButton *packagesButton;
    IBOutlet UIButton *startedButton;
    IBOutlet UIButton *storeButton;
    
    IBOutlet UIButton *backgroundButton;
    IBOutlet UIView *helpView;
    IBOutlet UIView *infoView;
    IBOutlet UILabel *loginLabel;
    IBOutlet UILabel *logoutLabel;
    IBOutlet UIButton *loginButton;
    IBOutlet UIButton *logoutButton;
    IBOutlet UIActivityIndicatorView *loginIndicator;
    
    IBOutlet UILabel *versionLabel;
    
    IBOutlet UILabel *addressWarning;
    IBOutlet LayoutView *loginView;
    IBOutlet UITextField *emailField;
    IBOutlet UITextField *passwordField;
    
    IBOutlet UIView *encloserView;
    IBOutlet UIButton *slideBackButton;
    IBOutlet UIWebView *forgottenPasswordView;
    
    // Fake alert view
    IBOutlet LayoutView *fakeAlertView;
    IBOutlet UILabel *fakeAlertHeadline;
    IBOutlet UITextView *fakeAlertText;
    IBOutlet UILabel *fakeCancelLabel;
    IBOutlet UILabel *fakeOKLabel;
    IBOutlet UIButton *fakeCancelButton;
    IBOutlet UIButton *fakeOKButton;
    int fakeAlertTag;
    BOOL modalAlertActive;
}

-(IBAction)packageButtonPressed:(id)sender;
-(IBAction)startedButtonPressed:(id)sender;
-(IBAction)storeButtonPressed:(id)sender;

-(IBAction)helpButtonPressed:(id)sender;
-(IBAction)infoButtonPressed:(id)sender;
-(IBAction)backgroundButtonPressed:(id)sender;
-(void)handleBackgroundButtonPressed;
-(void)hideBackgroundButton;
-(void)showLoginIndicator;

-(IBAction)loginButtonPressed:(id)sender;
-(IBAction)logoutButtonPressed:(id)sender;
-(void)setLoggedIn:(BOOL)manually;
-(void)setLoggedOut;
-(void)showFailedLoginWarning;
-(IBAction)loginViewButtonPressed:(id)sender;
-(IBAction)forgotPasswordButtonPressed:(id)sender;
-(IBAction)migrateButtonPressed:(id)sender;
-(IBAction)readMoreButtonPressed:(id)sender;

-(BOOL)NSStringIsValidEmail:(NSString *)checkString;
-(void)sendGAEvent:(NSString*)action;
-(NSString*)platformName;

// Fake alert view
-(void)setAlertHeadline:(NSString*)hl andText:(NSString*)tx andCancel:(NSString*)cc andOK:(NSString*)ok andTag:(int)tg modal:(BOOL)md;
-(IBAction)fakeAlertCancelClicked:(id)sender;
-(IBAction)fakeAlertOKClicked:(id)sender;

-(void)hideLoginIndicator;

@end
