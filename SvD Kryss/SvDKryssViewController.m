//
//  SvDKryssViewController.m
//  SvD Kryss
//
//  Created by Karl on 2013-01-09.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import "SvDKryssViewController.h"
#import "SvDKryssAppDelegate.h"
#import "SoundManager.h"
#import "DownloadManager.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "LayoutView.h"
#import "CustomAlertView.h"

#define SCREEN_ADJUST_TIME 0.25
#define SCREEN_ADJUST_OFFSET -90.0

#define SLIDE_DURATION 0.25

#define ALERT_ACCOUNT_PROBLEM 1
#define ALERT_LOGOUT 2
#define ALERT_LOGIN_CONFIRMATION 3

#define FORGOT_PASSWORD_URL @"https://kundservice.svd.se/in_app/nyttlosenord/"
#define DEFAULT_OFFLINE_MESSAGE @"<HTML><head></head><body><h3>Uppkopplingsproblem</h3>Det gick inte att ladda sidan. Kontrollera att uppkopplingen till Internet fungerar.</body></HTML>"
// Temporary
#define READ_MORE_URL @"https://kundservice.svd.se/in_app/nyttlosenord/"

@interface SvDKryssViewController ()

@end

@implementation SvDKryssViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.screenName = @"start";
    
    UIImage *highlight = [[UIImage imageNamed:@"cellselection.png"] stretchableImageWithLeftCapWidth:12 topCapHeight:12.0];
    [packagesButton setBackgroundImage:highlight forState:UIControlStateHighlighted];
    [startedButton setBackgroundImage:highlight forState:UIControlStateHighlighted];
    [storeButton setBackgroundImage:highlight forState:UIControlStateHighlighted];
    
    [loginView determineMargins];
    
    [fakeAlertView determineMargins];
    
    versionLabel.text = [NSString stringWithFormat:@"Version %@",[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]];
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)packageButtonPressed:(id)sender
{
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
    [delegate showPackageView];
}

-(IBAction)startedButtonPressed:(id)sender
{
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
    [delegate showStartedView];
}

-(IBAction)storeButtonPressed:(id)sender
{
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
    [delegate showStoreViewWithPackage:-1];
}

#pragma mark -
#pragma mark Help and info

-(IBAction)backgroundButtonPressed:(id)sender
{
    if (!modalAlertActive)
        [self handleBackgroundButtonPressed];
}

-(void)hideBackgroundButton
{
    [self hideLoginIndicator];
    [self handleBackgroundButtonPressed];
}

-(void)showLoginIndicator
{
    modalAlertActive = TRUE; // Background button unpressable
    backgroundButton.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
    backgroundButton.hidden = FALSE;
    loginIndicator.hidden = FALSE;
    [loginIndicator startAnimating];
}

-(void)handleBackgroundButtonPressed
{
    modalAlertActive = FALSE;
    infoView.hidden = TRUE;
    helpView.hidden = TRUE;
    backgroundButton.hidden = TRUE;
    backgroundButton.backgroundColor = [UIColor clearColor];
    fakeAlertView.hidden = TRUE;
    loginView.hidden = TRUE;
    loginButton.enabled = TRUE;
    [emailField resignFirstResponder];
    [passwordField resignFirstResponder];
}

-(IBAction)helpButtonPressed:(id)sender
{
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    backgroundButton.hidden = FALSE;
    helpView.hidden = FALSE;
}

-(IBAction)infoButtonPressed:(id)sender
{
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    backgroundButton.hidden = FALSE;
    infoView.hidden = FALSE;
}

#pragma mark -
#pragma mark UITextFieldDelegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == emailField)
    {
        [passwordField becomeFirstResponder];
    }
    else
    {
        [self loginViewButtonPressed:NULL];
    }
    return NO;
}

#pragma mark -
#pragma mark UIALertViewDelegate method

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    if ([title isEqualToString:@"Logga ut"])
    {
        [[DownloadManager sharedDownloadManager] makeLogout];
        [self sendGAEvent:@"logga ut"];
    }
}

#pragma mark -
#pragma mark Login

-(IBAction)loginButtonPressed:(id)sender
{
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    fakeAlertView.hidden = TRUE;
    if ([DownloadManager sharedDownloadManager].email != NULL)
    {
        emailField.text = [DownloadManager sharedDownloadManager].email;
        passwordField.text = [DownloadManager sharedDownloadManager].password;
    }
    loginButton.enabled = FALSE;
    backgroundButton.hidden = FALSE;
    addressWarning.hidden = TRUE;
    passwordField.text = @"";
    loginView.hidden = FALSE;
    [loginView pack];
}

-(IBAction)logoutButtonPressed:(id)sender
{
    [self setAlertHeadline:@"Vill du verkligen logga ut?" andText:@"Du måste vara inloggad för att ha tillgång till de korsord som hör till ditt SvD-konto." andCancel:@"Avbryt" andOK:@"Logga ut" andTag:ALERT_LOGOUT modal:TRUE];
}

-(void)setLoggedIn:(BOOL)manually;
{
    [self hideBackgroundButton];
    loginLabel.hidden = TRUE;
    logoutLabel.hidden = FALSE;
    loginButton.hidden = TRUE;
    logoutButton.hidden = FALSE;
    if (manually)
        [self setAlertHeadline:@"Du är nu inloggad" andText:@"Dina korsord och lösningar blir nu tillgängliga på samtliga enheter som använder ditt SvD-konto." andCancel:NULL andOK:@"OK" andTag:ALERT_LOGIN_CONFIRMATION modal:TRUE];
}

-(void)setLoggedOut
{
    [self hideBackgroundButton];
    loginLabel.hidden = FALSE;
    logoutLabel.hidden = TRUE;
    loginButton.hidden = FALSE;
    logoutButton.hidden = TRUE;
}

-(void)showFailedLoginWarning
{
    [self hideBackgroundButton];
    [self setAlertHeadline:@"Inloggningen misslyckades" andText:@"Antingen har dina kontouppgifter ändrats eller ditt SvD-konto avslutats p.g.a. inaktivitet.\nLogga in med rätt uppgifter eller bekräfta att ditt konto är avslutat och överför din användardata från SvD-kontot till denna enhet." andCancel:@"Logga in" andOK:@"Flytta" andTag:ALERT_ACCOUNT_PROBLEM modal:FALSE];
}

-(IBAction)loginViewButtonPressed:(id)sender
{
    if ([self NSStringIsValidEmail:emailField.text])
    {
        [self handleBackgroundButtonPressed];
        // Send login request
        [[DownloadManager sharedDownloadManager] loginWithEmail:emailField.text andPassword:passwordField.text];
        loginIndicator.hidden = FALSE;
        [loginIndicator startAnimating];
        [self sendGAEvent:@"logga in"];
    }
    else
    {
        addressWarning.hidden = FALSE;
    }
}

/*-(IBAction)forgotPasswordButtonPressed:(id)sender
{
    [self backgroundButtonPressed:NULL];
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
    [delegate showPasswordView];
}*/

-(IBAction)forgotPasswordButtonPressed:(id)sender
{
    [forgottenPasswordView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:FORGOT_PASSWORD_URL]]];
    [UIView animateWithDuration:SLIDE_DURATION delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^(void){
        encloserView.frame = CGRectMake(slideBackButton.frame.size.width-encloserView.frame.size.width, 0.0, encloserView.frame.size.width, encloserView.frame.size.height);
    }completion:^(BOOL Finished){
        slideBackButton.hidden = FALSE;
    }];
}

-(IBAction)readMoreButtonPressed:(id)sender
{   
    [forgottenPasswordView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle]
                                                                          pathForResource:[[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone?@"subscribe-iphone":@"subscribe-ipad" ofType:@"html"]isDirectory:NO]]];
    
    [UIView animateWithDuration:SLIDE_DURATION delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^(void){
        encloserView.frame = CGRectMake(slideBackButton.frame.size.width-encloserView.frame.size.width, 0.0, encloserView.frame.size.width, encloserView.frame.size.height);
    }completion:^(BOOL Finished){
        slideBackButton.hidden = FALSE;
    }];
}

-(IBAction)slideBackButtonPressed:(id)sender
{
    [UIView animateWithDuration:SLIDE_DURATION delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^(void){
        encloserView.frame = CGRectMake(0.0, 0.0, encloserView.frame.size.width, encloserView.frame.size.height);
    }completion:^(BOOL Finished){
        slideBackButton.hidden = TRUE;
    }];
}


-(IBAction)migrateButtonPressed:(id)sender
{
    [self handleBackgroundButtonPressed];
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    [[DownloadManager sharedDownloadManager] requestMerge];
}

#pragma mark -
#pragma mark Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(BOOL)shouldAutorotate
{
    return TRUE;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark -
#pragma mark Help functions

-(BOOL)NSStringIsValidEmail:(NSString *)checkString
{
    BOOL stricterFilter = YES; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    NSString *stricterFilterString = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSString *laxString = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}

-(void)sendGAEvent:(NSString*)action
{
    id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:GA_ID];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"UIAction"
                                                          action:@"buttonPress"
                                                           label:@"action"
                                                           value:NULL] build]];
}

-(NSString*)platformName
{
    int mib[2];
    size_t len;
    char *machine;
    
    mib[0] = CTL_HW;
    mib[1] = HW_MACHINE;
    sysctl(mib, 2, NULL, &len, NULL, 0);
    machine = malloc(len);
    sysctl(mib, 2, machine, &len, NULL, 0);
    
    NSString *platform = [NSString stringWithCString:machine encoding:NSASCIIStringEncoding];
    free(machine);
    
    if ([platform rangeOfString:@"iphone2"].location == 0)
        return @"iphone 3";
    if ([platform rangeOfString:@"iphone3"].location == 0 || [platform rangeOfString:@"iphone4"].location == 0)
        return @"iphone 4";
    if ([platform rangeOfString:@"iphone5"].location == 0)
        return @"iphone 5";
    if ([platform rangeOfString:@"ipod"].location == 0)
        return @"ipod touch";
    if ([platform rangeOfString:@"ipad1"].location == 0)
        return @"ipad 1";
    if ([platform rangeOfString:@"ipad2,5"].location == 0)
        return @"ipad mini";
    if ([platform rangeOfString:@"ipad2"].location == 0)
        return @"ipad 2";
    if ([platform rangeOfString:@"ipad3"].location == 0)
        return @"ipad 3";
    
    return platform;
}

// Fake alert methods

-(void)setAlertHeadline:(NSString*)hl andText:(NSString*)tx andCancel:(NSString*)cc andOK:(NSString*)ok andTag:(int)tg modal:(BOOL)md
{
    if (hl == NULL)
        fakeAlertHeadline.hidden = TRUE;
    else
        fakeAlertHeadline.text = hl;
    fakeAlertText.text = tx;
    fakeCancelLabel.text = cc;
    fakeOKLabel.text = ok;
    if (cc == NULL) // Just an OK button
    {
        fakeOKLabel.center = CGPointMake(fakeAlertHeadline.center.x, fakeCancelLabel.center.y);
        fakeOKButton.center = CGPointMake(fakeAlertHeadline.center.x, fakeOKButton.center.y);
        fakeCancelLabel.hidden = TRUE;
        fakeCancelButton.hidden = TRUE;
    }
    else
    {
        fakeOKLabel.frame = CGRectMake(fakeAlertView.frame.size.width-fakeOKLabel.frame.size.width-fakeCancelLabel.frame.origin.x, fakeOKLabel.frame.origin.y, fakeOKLabel.frame.size.width, fakeOKLabel.frame.size.height);
        fakeOKButton.center = CGPointMake(fakeOKLabel.center.x, fakeOKButton.center.y);
        fakeCancelLabel.hidden = FALSE;
        fakeCancelButton.hidden = FALSE;
    }
    fakeAlertTag = tg;
    fakeAlertView.hidden = FALSE;
    [fakeAlertView pack];
    modalAlertActive = md;
    if (md)
    {
        backgroundButton.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
    }
    backgroundButton.hidden = FALSE;
}

-(IBAction)fakeAlertCancelClicked:(id)sender
{
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    [self handleBackgroundButtonPressed];
    switch (fakeAlertTag)
    {
        case ALERT_ACCOUNT_PROBLEM:
            // Try to log in manually after autologin failed
            emailField.text = NULL;
            passwordField.text = NULL;
            
            loginButton.enabled = FALSE;
            backgroundButton.hidden = FALSE;
            addressWarning.hidden = TRUE;
            loginView.hidden = FALSE;
            break;
        default:
            break;
    }
}

-(IBAction)fakeAlertOKClicked:(id)sender
{
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    [self handleBackgroundButtonPressed];
    switch (fakeAlertTag)
    {
        case ALERT_LOGOUT:
            [[DownloadManager sharedDownloadManager] makeLogout];
            [self sendGAEvent:@"logga ut"];
            break;
        case ALERT_ACCOUNT_PROBLEM:
            // Migrate
            [[DownloadManager sharedDownloadManager] requestMerge];
            break;
       default:
            break;
    }
}

-(void)hideLoginIndicator
{
    [loginIndicator stopAnimating];
    loginIndicator.hidden = TRUE;
}

#pragma mark -
#pragma mark Web View delegate

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [forgottenPasswordView loadHTMLString:DEFAULT_OFFLINE_MESSAGE baseURL:NULL];
}

@end
