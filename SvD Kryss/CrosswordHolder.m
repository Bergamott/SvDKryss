//
//  CrosswordHolder.m
//  SvD Kryss
//
//  Created by Karl on 2013-01-11.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import "CrosswordHolder.h"
#import "OverlayView.h"
#import "Metadata.h"
#import "CrosswordViewController.h"
#import "DataHolder.h"
#import "SoundManager.h"
#import "DownloadManager.h"
#import "PDFDisplay.h"
#import "SvDKryssAppDelegate.h"
#import "CustomAlertView.h"
#import "LayoutView.h"

#import "GAI.h"
#import "GAIDictionaryBuilder.h"

#define CLOCK_TICK_INTERVAL 0.2

#define ALERT_RESET_TAG 1
#define ALERT_CORRECT_ALL_TAG 2
#define ALERT_INCOMPLETE_SOLUTION 3
#define ALERT_NEEDS_LOGIN 4
#define ALERT_SYNC 5

#define SCALE_TO_72_DPI 0.24

#define SYNC_STRING @"Ja, synka!"

@implementation CrosswordHolder

@synthesize myMetadata;
@synthesize clockDigits;
//@synthesize popoverController;

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


-(void)setPDFURL:(NSURL*)url content:(CGRect)ct andScale:(float)sc
{
    [fakeSegmentedControl setup];
    showMistakesButtonsView.hidden = (fakeSegmentedControl.selectedSegmentIndex == 1);
    fillInButtonsView.hidden = (fakeSegmentedControl.selectedSegmentIndex == 0);
    [self hidePopdowns];
    
    pdfDisplay.pdfUrl = url;

    [pdfDisplay setScale:sc / SCALE_TO_72_DPI  picX:ct.origin.x * SCALE_TO_72_DPI picY:ct.origin.y * SCALE_TO_72_DPI picW:ct.size.width * SCALE_TO_72_DPI picH:ct.size.height * SCALE_TO_72_DPI];
    contentWidth = ct.size.width * sc;
    contentHeight = ct.size.height * sc;
    self.frame = CGRectMake(0, 0, contentWidth, contentHeight);
    [overlayView setLineThicknessScale:sc];
}

-(void)setMetadata:(Metadata*)md
{
    self.myMetadata = md;
    // Adjust menu buttons according to availability of solution
    if ([md solutionExists])
    {
        [showMistakesButtonsView setUserInteractionEnabled:TRUE];
        [fillInButtonsView setUserInteractionEnabled:TRUE];
        showMistakesButtonsView.alpha = 1.0;
        fillInButtonsView.alpha = 1.0;
        
        competitionButton.alpha = 0.3;
        competitionButton.enabled = FALSE;
        competitionLabel.alpha = 0.3;
//        competitionButton.alpha = 1.0; // Testing
//        competitionButton.enabled = TRUE;
//        competitionLabel.alpha = 1.0;
    }
    else
    {
        [showMistakesButtonsView setUserInteractionEnabled:FALSE];
        [fillInButtonsView setUserInteractionEnabled:FALSE];
        showMistakesButtonsView.alpha = 0.3;
        fillInButtonsView.alpha = 0.3;
        
        competitionButton.alpha = 1.0;
        competitionButton.enabled = TRUE;
        competitionLabel.alpha = 1.0;
    }
    // Adjust clock
    clockDigits = [[NSArray alloc] initWithObjects:clockDigit0, clockDigit1, clockDigit2, clockDigit3, clockDigit4, clockDigit5, nil];
    int sec = [myMetadata getClockSeconds];
    NSString *tmpS = [NSString stringWithFormat:@"%02d%02d%02d",(sec/3600),(sec/60)%60,(sec%60)];
    for (int i=0;i<6;i++)
    {
        UILabel *tmpL = [clockDigits objectAtIndex:i];
        tmpL.text = [tmpS substringWithRange:NSMakeRange(i, 1)];
    }
    
    // Initialize fake alert view
    [fakeAlertView determineMargins];
    addressWarning.hidden = FALSE;
    [emailView determineMargins];
    [emailView pack];
    
    [overlayView setupWithMetadata:md];
    [overlayView askForRedraw];
}

/*
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
	UITouch *touch = [[event allTouches] anyObject];
	CGPoint location = [touch locationInView:self];
    
    GridPos gp = [myMetadata getSelectionFromX:location.x andY:location.y];
    if (gp.h >= 0)
    {
        [myMetadata selectBoxAtH:gp.h andV:gp.v];
        [owner needsKeyboard];
        // Uncomment this line to enable zooming / panning
//        [owner zoomToRect:[myMetadata getWordBoundingBox]];
        //    [overlayView setNeedsDisplay];
        [overlayView askForRedraw];
    }
    else if ([myMetadata selectedClueAtX:location.x andY:location.y])
    {
        [owner needsKeyboard];
        [overlayView askForRedraw];
    }
    if ([myMetadata hasSelection])
        [owner panToCursor:[myMetadata getSelectedBoxCoordinates]];
}
*/

-(IBAction)keyTyped:(id)sender
{
    [self hidePopdowns];
    [overlayView keyTyped:(int)((UIButton*)sender).tag];
    [self setPercentageFilledIn:[myMetadata getFilledInPercent]];
    if ([myMetadata hasSelection])
    {
        selection.frame = [myMetadata getSelectedBoxCoordinates];
        [owner panToCursor:selection.frame];
    }
}

-(void)setClockActive:(BOOL)act
{
    [myMetadata activateClock:act];
    if (act)
    {
        if (clockTickTimer != nil)
        {
            [clockTickTimer invalidate];
            clockTickTimer = nil;
            [clockStartTime release];
        }
        clockSeconds = [myMetadata getClockSeconds];
        [self realignClock];
        hibernateFlag = FALSE;
        clockTickTimer = [NSTimer scheduledTimerWithTimeInterval: CLOCK_TICK_INTERVAL
                                                        target: self
                                                        selector:@selector(updateClock)
                                                        userInfo: nil repeats:YES];
        [self sendGAEvent:@"starta tidtagning"];
    }
    else
    {
        if (clockTickTimer != nil)
        {
            [clockTickTimer invalidate];
            clockTickTimer = nil;
        }
        [self sendGAEvent:@"stoppa tidtagning"];
    }
    [self hidePopdowns];
}

-(IBAction)resetClock:(id)sender
{
    [[SoundManager sharedInstance] playSound:CLOCK_SOUND];
    [owner setClockActive:FALSE];
    [myMetadata setClockSeconds:0];
    for (UILabel *tmpL in clockDigits)
        tmpL.text = @"0";
    [self hidePopdowns];
    [self sendGAEvent:@"nollstall tidtagning"];
}

-(void)realignClock
{
    clockStartTime = [[NSDate dateWithTimeIntervalSinceNow:-[myMetadata getClockSeconds]] retain];
}

-(void)enterBackground
{
    [self periodicSave];
    hibernateFlag = TRUE;
}

-(void)enterForeground
{
    [self startPulsatingIcon];
    hibernateFlag = FALSE;
}

-(void)updateClock
{
    if (hibernateFlag)
        [self realignClock];
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:clockStartTime];
    clockSeconds = (int)timeInterval;
    NSString *tmpS = [NSString stringWithFormat:@"%02d%02d%02d",(clockSeconds/3600),(clockSeconds/60)%60,(clockSeconds%60)];
//    clockSeconds++;
//    NSString *tmpS = [NSString stringWithFormat:@"%02d%02d%02d",(clockSeconds/3600),(clockSeconds/60)%60,(clockSeconds%60)];
    for (int i=0;i<6;i++)
    {
        UILabel *tmpL = [clockDigits objectAtIndex:i];
        tmpL.text = [tmpS substringWithRange:NSMakeRange(i, 1)];
    }
    [myMetadata setClockSeconds:clockSeconds];
}

-(void)periodicSave
{
    [myMetadata saveFilledInCharactersAs:[[DataHolder sharedDataHolder] getCurrentDataFilename]];
    [[DataHolder sharedDataHolder] saveMyCrosswords];
}

-(void)uploadToServer
{
    NSNumber *tmpN = [[DataHolder sharedDataHolder].currentCrossword objectForKey:@"cwId"];
    [[DownloadManager sharedDownloadManager] sendCharacterData:[myMetadata getFilledInCharactersAsBase64String] withPercent:[myMetadata getFilledInPercent] forID:[tmpN intValue]];
}

-(void)setMarkerActive:(BOOL)act
{
    // Adjust marker/pencil buttons on all keyboards
    markerToggleButton.hidden = !act;
    pencilToggleButton.hidden = act;
    markerLandscapeToggleButton.hidden = !act;
    pencilLandscapeToggleButton.hidden = act;
    markerButton.selected = act;
    pencilButton.selected = !act;
    markerButtonLandscape.selected = act;
    pencilButtonLandscape.selected = !act;
    markerImage.highlighted = act;
    pencilImage.highlighted = !act;
    markerImageLandscape.highlighted = act;
    pencilImageLandscape.highlighted = !act;
}

-(void)setPercentageFilledIn:(int)p
{
    filledInText.text = [NSString stringWithFormat:@"%d%% ifyllt",p];
    [filledInBar setValue:p];
    
/*    if (p > 0)
        [[DataHolder sharedDataHolder] setForCurrentCrosswordProperty:PERCENTAGE_SOLVED_TAG value:[NSString stringWithFormat:@"%d",p]];
    else
        [[DataHolder sharedDataHolder] setForCurrentCrosswordProperty:PERCENTAGE_SOLVED_TAG value:nil];*/
    [[DataHolder sharedDataHolder] setPercentageSolvedForCurrentCrossword:p];
}

-(IBAction)helpWithCharacterPressed:(id)sender
{
    [self hidePopdowns];
    [myMetadata helpWithCharacterAtSelection];
    [overlayView askForRedraw];
    [self sendGAEvent:@"ratta ruta"];
}

-(IBAction)correctCharacterPressed:(id)sender
{
    [self hidePopdowns];
    [myMetadata setCorrectCharacterAtSelection];
    [overlayView askForRedraw];
    [self setPercentageFilledIn:[myMetadata getFilledInPercent]];
    [self sendGAEvent:@"facit ruta"];
}

-(IBAction)helpWithWordPressed:(id)sender
{
    [self hidePopdowns];
    [myMetadata findWrongCharactersInWord];
    [overlayView askForRedraw];
    [self sendGAEvent:@"ratta ord"];
}

-(IBAction)correctWordPressed:(id)sender
{
    [self hidePopdowns];
    [myMetadata correctCharactersInWord];
    [overlayView askForRedraw];
    [self setPercentageFilledIn:[myMetadata getFilledInPercent]];
    [self sendGAEvent:@"facit ord"];
}

-(IBAction)helpWithAllPressed:(id)sender
{
    [myMetadata markAllWrongCharacters];
    [self hidePopdowns];
    [overlayView askForRedraw];
    [owner hideKeyboard];
    [owner zoomToContent];
    [self sendGAEvent:@"ratta korsord"];
}

-(void)correctAllConfirmed
{
    [myMetadata checkIfAllIsCorrect];
    [myMetadata markAllToRefresh];
    [overlayView showSolution];
    [owner hideKeyboard];
    [owner zoomToContent];
}

-(void)startOverConfirmed
{
    [myMetadata clearAllCharacters];
    [overlayView askForRedraw];
    [self setPercentageFilledIn:[myMetadata getFilledInPercent]];
//    [owner hideKeyboard];
    [owner zoomToContent];
}

// Segmented control changes clue button sets
-(IBAction)clueTypeChanged:(id)sender
{
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    UISegmentedControl *tmpS = sender;
    showMistakesButtonsView.hidden = (tmpS.selectedSegmentIndex == 1);
    fillInButtonsView.hidden = (tmpS.selectedSegmentIndex == 0);
}

-(void)fakeSegmentChanged:(id)sender;
{
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    FakeSegmentedControl *tmpFS = sender;
    showMistakesButtonsView.hidden = (tmpFS.selectedSegmentIndex == 1);
    fillInButtonsView.hidden = (tmpFS.selectedSegmentIndex == 0);
    if (tmpFS.selectedSegmentIndex == 0)
        [self sendGAEvent:@"toggla ratta"];
    else
        [self sendGAEvent:@"toggla facit"];
}

-(IBAction)markerPressed:(id)sender
{
    [[SoundManager sharedInstance] playSound:PEN_SOUND];
    markerButton.selected = TRUE;
    pencilButton.selected = FALSE;
    markerButtonLandscape.selected = TRUE;
    pencilButtonLandscape.selected = FALSE;
    markerImage.highlighted = TRUE;
    pencilImage.highlighted = FALSE;
    markerImageLandscape.highlighted = TRUE;
    pencilImageLandscape.highlighted = FALSE;
    [myMetadata activatePermanentMarker:TRUE];
}
-(IBAction)pencilPressed:(id)sender
{
    [[SoundManager sharedInstance] playSound:PENCIL_SOUND];
    markerButton.selected = FALSE;
    pencilButton.selected = TRUE;
    markerButtonLandscape.selected = FALSE;
    pencilButtonLandscape.selected = TRUE;
    markerImage.highlighted = FALSE;
    pencilImage.highlighted = TRUE;
    markerImageLandscape.highlighted = FALSE;
    pencilImageLandscape.highlighted = TRUE;
    [myMetadata activatePermanentMarker:FALSE];
}

-(IBAction)markerTogglePressed:(id)sender
{
    [[SoundManager sharedInstance] playSound:PENCIL_SOUND];
    markerToggleButton.hidden = TRUE;
    pencilToggleButton.hidden = FALSE;
    markerLandscapeToggleButton.hidden = TRUE;
    pencilLandscapeToggleButton.hidden = FALSE;
    [myMetadata activatePermanentMarker:FALSE];
}
-(IBAction)pencilTogglePressed:(id)sender
{
    [[SoundManager sharedInstance] playSound:PEN_SOUND];
    markerToggleButton.hidden = FALSE;
    pencilToggleButton.hidden = TRUE;
    markerLandscapeToggleButton.hidden = FALSE;
    pencilLandscapeToggleButton.hidden = TRUE;
    [myMetadata activatePermanentMarker:TRUE];
}

-(IBAction)resetButtonClicked:(id)sender
{
    [self hidePopdowns];
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    [self setAlertHeadline:@"Radera allt" andText:@"Är du säker på att du vill rensa korsordet och börja om från början?" andCancel:@"Avbryt" andOK:@"Radera" andTag:ALERT_RESET_TAG];
}

-(IBAction)correctAllButtonClicked:(id)sender
{
    [self hidePopdowns];
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    [self setAlertHeadline:@"Facit för hela korsordet" andText:@"Är du säker på att du vill visa lösningen för hela korsordet?" andCancel:@"Avbryt" andOK:@"Visa" andTag:ALERT_CORRECT_ALL_TAG];
}


#pragma mark -
#pragma mark Alert and popovers

-(IBAction)popoverBackgroundClicked:(id)sender
{
    [self hidePopdowns];
}

-(void)hidePopdowns
{
    clockPopdown.hidden = TRUE;
    menuPopdown.hidden = TRUE;
    fakeAlertView.hidden = TRUE;
    emailView.hidden = TRUE;
    popoverView.hidden = TRUE;
    [addressField resignFirstResponder];
}

-(IBAction)clockButtonClicked:(id)sender
{
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
        UIButton *tmpB = (UIButton*)sender;
        float centX = [tmpB superview].frame.origin.x + tmpB.frame.origin.x + tmpB.frame.size.width*0.5;
        clockPopdown.center = CGPointMake(centX, clockPopdown.center.y);
    clockPopdown.hidden = FALSE;
    popoverView.backgroundColor = [UIColor clearColor];
    popoverView.hidden = FALSE;
    popoverBackgroundButton.enabled = TRUE;
}

-(IBAction)menuButtonClicked:(id)sender
{
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    [self adjustMenu];
    menuPopdown.hidden = FALSE;
    popoverView.backgroundColor = [UIColor clearColor];
    popoverView.hidden = FALSE;
    popoverBackgroundButton.enabled = TRUE;
}

-(void)adjustMenu
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        if (popoverView.frame.size.width < 321.0) // Portrait
        {
            // With competition
//            menuPopdown.frame = CGRectMake(70.0, 35.0, 259.0, 408.0);
            
            // Without competition
            menuPopdown.frame = CGRectMake(70.0, 35.0, 259.0, 338.0);
            menuBottomRight.frame = CGRectMake(33.0, 163.0, 192.0, 131.0);
            
            menuBackgroundView.highlighted = FALSE;
        }
        else // Landscape
        {
            menuPopdown.frame = CGRectMake(popoverView.frame.size.width-459.0, 35.0, 467.0, 270.0);
            
            // Without competition
            menuBottomRight.frame = CGRectMake(241.0, 5.0, 192.0, 131.0);
            
            menuBackgroundView.highlighted = TRUE;
        }
    }
}

-(void)setAlertHeadline:(NSString*)hl andText:(NSString*)tx andCancel:(NSString*)cc andOK:(NSString*)ok andTag:(int)tg
{
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
        fakeOKButton.frame = CGRectMake(fakeOKLabel.frame.origin.x, fakeOKButton.frame.origin.y, fakeOKButton.frame.size.width, fakeOKButton.frame.size.height);
        fakeCancelLabel.hidden = FALSE;
        fakeCancelButton.hidden = FALSE;
    }
    fakeAlertTag = tg;
    fakeAlertView.hidden = FALSE;
    [fakeAlertView pack];
    popoverView.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.3];
    popoverView.hidden = FALSE;
    popoverBackgroundButton.enabled = FALSE;
}

-(IBAction)fakeAlertCancelClicked:(id)sender
{
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    [self hidePopdowns];
    switch (fakeAlertTag)
    {
        case ALERT_SYNC:
            [[DataHolder sharedDataHolder] removeUpdatedSolutionForCurrent];
            break;
        default:
            break;
    }
}

-(IBAction)fakeAlertOKClicked:(id)sender
{
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    [self hidePopdowns];
    switch (fakeAlertTag)
    {
        case ALERT_RESET_TAG:
            [self startOverConfirmed];
            [self sendGAEvent:@"rensa hela"];
            break;
        case ALERT_CORRECT_ALL_TAG:
            [self correctAllConfirmed];
            [self sendGAEvent:@"facit korsord"];
            break;
        case ALERT_INCOMPLETE_SOLUTION:
            break;
        case ALERT_NEEDS_LOGIN:
            [owner jumpBackToMainMenu];
            break;
        case ALERT_SYNC:
            [myMetadata setUserDataFromData:[[DataHolder sharedDataHolder] getUpdatedSolutionDataForCurrent]];
            [owner setClockActive:[myMetadata isClockActive]];
            [self setPercentageFilledIn:[myMetadata getFilledInPercent]];
            [myMetadata markAllToRefresh];
            [overlayView askForRedraw];
            [[DataHolder sharedDataHolder] removeUpdatedSolutionForCurrent];
            break;
    }
}

-(float)getContentWidth
{
    return contentWidth;
}
-(float)getContentHeight
{
    return contentHeight;
}

-(void)refreshCrossword
{
    selection.frame = CGRectMake(-1000.0, -1000.0, 20.0, 20.0);
    selection.alpha = 1.0;
    [self startPulsatingIcon];
    [pdfDisplay setNeedsDisplay];
}

-(void)sendGAEvent:(NSString*)action
{
    id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:GA_ID];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"UIAction"
                                                          action:@"buttonPress"
                                                           label:@"action"
                                                           value:nil] build]];

}

// Gestures
-(void)setupGestures
{
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    
    [doubleTap setNumberOfTapsRequired:2];
    
    [self addGestureRecognizer:singleTap];
    [self addGestureRecognizer:doubleTap];

    [singleTap release];
    [doubleTap release];
}

-(void)handleSingleTap:(UIGestureRecognizer *)gestureRecognizer
{
	CGPoint location = [gestureRecognizer locationInView:gestureRecognizer.view];
    
    GridPos gp = [myMetadata getSelectionFromX:location.x andY:location.y];
    if (gp.h >= 0)
    {
        [myMetadata selectBoxAtH:gp.h andV:gp.v];
        [owner needsKeyboard];
        // Uncomment this line to enable zooming / panning
        //        [owner zoomToRect:[myMetadata getWordBoundingBox]];
        //    [overlayView setNeedsDisplay];
        [overlayView askForRedraw];
    }
    else if ([myMetadata selectedClueAtX:location.x andY:location.y])
    {
        [owner needsKeyboard];
        [overlayView askForRedraw];
    }
    if ([myMetadata hasSelection])
    {
        selection.frame = [myMetadata getSelectedBoxCoordinates];
        [owner panToCursor:[myMetadata getSelectedBoxCoordinates]];
    }
}

-(void)handleDoubleTap:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint location = [gestureRecognizer locationInView:gestureRecognizer.view];
    [owner doubleTapZoomToPoint:location];
}

#pragma mark -
#pragma mark Competition

-(IBAction)competitionButtonPressed:(id)sender
{
    [self hidePopdowns];
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    int status = [myMetadata checkSolutionStatus];
    if (status == SOLUTION_FILLED_IN)
    {
        if ([[DownloadManager sharedDownloadManager] isLoggedInWithRealAccount])
        {
            [[DownloadManager sharedDownloadManager] sendCompetitionData:[myMetadata getCompetitionString] forID:[(NSNumber*)[[DataHolder sharedDataHolder].currentCrossword objectForKey:@"cwId"] intValue]];
        }
        else
        {
            // Player needs to login or specify email address
            addressField.text = [DownloadManager sharedDownloadManager].registeredEmail;

            addressWarning.hidden = TRUE;
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
                emailView.center = owner.view.center;
            emailView.hidden = FALSE;
            popoverView.backgroundColor = [UIColor clearColor];
            popoverView.hidden = FALSE;
            popoverBackgroundButton.enabled = TRUE;
        }
    }
    else // Missing letters
    {
        [self setAlertHeadline:@"Ofullständigt tävlingsbidrag" andText:@"Tävlingsbidrag har inte skickats in eftersom samtliga rutor som krävs inte är ifyllda." andCancel:nil andOK:@"OK" andTag:ALERT_INCOMPLETE_SOLUTION];
    }
/*    else if (status == SOLUTION_MISSING_NUMBERS)
    {
        [self setAlertHeadline:@"Ofullständig lösning" andText:@"Alla sifferrutor måste vara ifyllda" andCancel:NULL andOK:@"OK" andTag:ALERT_INCOMPLETE_SOLUTION];
    }
    else // Missing letters
    {
        [self setAlertHeadline:@"Ofullständig lösning" andText:@"Alla bokstäver måste vara ifyllda" andCancel:NULL andOK:@"OK" andTag:ALERT_INCOMPLETE_SOLUTION];
    }*/
}

-(IBAction)confirmEmailCompetition:(id)sender
{
    if ([self NSStringIsValidEmail:addressField.text])
    {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
            emailView.center = owner.view.center;
        [[DownloadManager sharedDownloadManager] setRegisteredEmail:addressField.text];
        [[DownloadManager sharedDownloadManager] registerEmailAddress:addressField.text];
        [[DownloadManager sharedDownloadManager] sendCompetitionData:[myMetadata getCompetitionString] forID:[(NSNumber*)[[DataHolder sharedDataHolder].currentCrossword objectForKey:@"cwId"] intValue]];
        [self hidePopdowns];
    }
    else
        addressWarning.hidden = FALSE;
}

#pragma mark -

-(void)seeIfWeNeedSyncing
{
    if ([myMetadata isEqualToUserData:[[DataHolder sharedDataHolder] getUpdatedSolutionDataForCurrent]])
    {
        // Solution data identical to locally stored solution. Don't sync. Delete it.
        [[DataHolder sharedDataHolder] removeUpdatedSolutionForCurrent];
    }
    else
    {
        NSString *questionString = [[DataHolder sharedDataHolder] updatedSolutionResponseForPercent:[myMetadata getFilledInPercent]];
        if (questionString != NULL)
        {
            [self setAlertHeadline:@"Synkning" andText:questionString andCancel:@"Nej" andOK:SYNC_STRING andTag:ALERT_SYNC];
        }
    }
}

-(void)startPulsatingIcon
{
    selection.alpha = 1.0;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationDelay:1.0];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView setAnimationRepeatAutoreverses:TRUE];
    [UIView setAnimationRepeatCount:10000.0f];
    
    selection.alpha = 0.5;
    
    [UIView commitAnimations];
}

#pragma mark -
#pragma mark UITextFieldDelegate

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        emailView.center = CGPointMake(owner.view.center.x, (owner.view.frame.size.height - emailView.frame.size.height)/2.0);
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [self confirmEmailCompetition:NULL];
    return NO;
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

@end
