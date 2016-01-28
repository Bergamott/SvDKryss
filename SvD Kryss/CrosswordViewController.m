//
//  CrosswordViewController.m
//  SvD Kryss
//
//  Created by Karl on 2013-01-09.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import "CrosswordViewController.h"
#import "SvDKryssAppDelegate.h"
#import "KeypadView.h"
#import "CrosswordHolder.h"
#import "Metadata.h"
#import "DataHolder.h"
#import "SoundManager.h"
#import "CustomAlertView.h"
#import "DownloadManager.h"

#import "GAI.h"
#import "GAIDictionaryBuilder.h"

#define MAX_PIXELS_DEFAULT 4000000
#define MAX_PIXELS_IPAD1 3500000
#define MAX_PIXELS_IPOD4 600000
#define MAX_PIXELS_IPOD5 3000000
#define MAX_PIXELS_IPHONE3GS 4000000
#define MAX_PIXELS_IPHONE4 1500000
#define MAX_PIXELS_IPHONE4S 2500000
#define MAX_PIXELS_IPHONE5 4000000

#define MAX_ZOOM 1.0
//#define RESTRICTED_MAX_ZOOM 1.0

#define ALERT_RESET_TAG 1
#define ALERT_CORRECT_ALL_TAG 2

#define SCROLL_PAN_TIME 0.5

@interface CrosswordViewController ()

@end

@implementation CrosswordViewController

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    [crosswordHolder setupGestures];
    self.screenName = @"korsord";
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

-(void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    
    id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:GA_ID];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Warning"
                                                          action:@"memory"
                                                           label:@"memory"
                                                           value:nil] build]];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    portraitMode = (interfaceOrientation == UIInterfaceOrientationPortrait ||
                    interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
    return YES;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    portraitMode = (fromInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || fromInterfaceOrientation == UIInterfaceOrientationLandscapeRight);

    if (keyboardVisible)
    {
        landscapeKeyboard.hidden = portraitMode;
        portraitKeyboard.hidden = !portraitMode;
        landscapeKeyboardShadow.hidden = portraitMode;
        portraitKeyboardShadow.hidden = !portraitMode;

        if (portraitMode)
        {
            scrollView.frame = CGRectMake(0, topBarHeight, portraitKeyboard.frame.size.width, portraitKeyboard.frame.origin.y-topBarHeight);
        }
        else
        {
            scrollView.frame = CGRectMake(0, topBarHeight, landscapeKeyboard.frame.size.width, landscapeKeyboard.frame.origin.y-topBarHeight);
        }
    }
    [self adjustZoomScale];
    [crosswordHolder adjustMenu];
    [scrollView setZoomScale:scrollView.zoomScale*1.005]; // Adjust zoom to force re-centering

}

-(void)initiateWithCurrentCrossword
{
    NSDictionary *cw = [DataHolder sharedDataHolder].currentCrossword;
    portraitMode = UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]);
    topBarHeight = topBar.frame.size.height;
    // Initially hide keyboards
    [self hideKeyboard];
    [portraitKeyboard hidePopup];
    
    NSURL *tmpPdfUrl = NULL; // Picture URL
    NSData *crosswordData = NULL; // Metadata
    
    NSData *userData = [[DownloadManager sharedDownloadManager] getUserDataForCrossword:[[DataHolder sharedDataHolder] getCurrentDataFilename]];
    // See if we need to sync data from merged account on same device
    NSData *syncDataFromSameDevice = [[DataHolder sharedDataHolder] getUpdatedSolutionIfSameAsThisDevice];
    if (syncDataFromSameDevice != NULL)
    {
        NSLog(@"Syncing merged data");
        userData = syncDataFromSameDevice;
        [[DataHolder sharedDataHolder] removeUpdatedSolutionForCurrent];
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *localFilePath;
    NSString *localPicture = [cw objectForKey:@"local-picture"];
    if (localPicture != nil)
    {
        NSString *pdfStringURL = [[NSBundle mainBundle] pathForResource:[cw objectForKey:@"local-metadata"] ofType:@"pdf"];
        tmpPdfUrl = [NSURL fileURLWithPath:pdfStringURL];
    }
    else
    {
        NSLog(@"Loading locally stored image");
        NSString *pictureS = [cw objectForKey:@"pdf"];
        localFilePath = [documentsDirectory stringByAppendingPathComponent:pictureS];
        tmpPdfUrl = [NSURL fileURLWithPath:localFilePath];
    }
    
    NSString *localMetadata = [cw objectForKey:@"local-metadata"];
    if (localMetadata != nil)
    {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:localMetadata ofType:@"xwd"];
        crosswordData = [NSData dataWithContentsOfFile:filePath];
    }
    else
    {
        NSLog(@"Loading locally stored metadata");
        NSString *fileS = [cw objectForKey:@"metadata"];
        localFilePath = [documentsDirectory stringByAppendingPathComponent:fileS];
        crosswordData = [NSData dataWithContentsOfFile:localFilePath];
    }
    
    Metadata *md = [[Metadata alloc] init];
    [md setupWithData:crosswordData];
    if (userData != NULL)
        [md setUserDataFromData:userData];
    [crosswordHolder setMetadata:md];

    [crosswordHolder setMarkerActive:[md isPermanentMarkerActive]];
    [self setClockActive:[md isClockActive]];
    [crosswordHolder setPercentageFilledIn:[md getFilledInPercent]];
    
    // Determine scale factor
    CGRect contentRect = [md getContentRect];
    float scaleFactor = [self determineScaleFactorFromWidth:contentRect.size.width andHeight:contentRect.size.height];
    if (scaleFactor < 0.5)
        maxZoomScale = MAX_ZOOM * 2.0;
    else
        maxZoomScale = MAX_ZOOM / scaleFactor;
    [md setScaleFactor:scaleFactor];
    
    [md release];
    
    // Reset crossword holder size and provide picture and size information
    [crosswordHolder removeFromSuperview];
    crosswordHolder.transform = CGAffineTransformIdentity;    
    [crosswordHolder setPDFURL:tmpPdfUrl content:contentRect andScale:scaleFactor];
    
    [scrollView addSubview:crosswordHolder];
    
    scrollView.delegate = self;
    scrollView.contentSize = CGSizeMake([crosswordHolder getContentWidth],[crosswordHolder getContentHeight]);
    [crosswordHolder refreshCrossword];
    [self adjustZoomScale];
    
    // Timed save
    if (saveTimer == nil)
    {
        saveTimer = [NSTimer scheduledTimerWithTimeInterval: SAVE_INTERVAL
                                                     target: self
                                                   selector:@selector(periodicSave)
                                                   userInfo: nil repeats:YES];
    }
    [self zoomToContent];
    
    [crosswordHolder seeIfWeNeedSyncing];
}

// Determine smallest zoom scale so that the entire crossword is visible
-(void)adjustZoomScale
{
    float oldMinZoomScale = scrollView.minimumZoomScale;
    float xMinScale = scrollView.frame.size.width/[crosswordHolder getContentWidth];
    float yMinScale = scrollView.frame.size.height/[crosswordHolder getContentHeight];
    if (xMinScale < yMinScale)
        scrollView.minimumZoomScale = xMinScale;
    else
        scrollView.minimumZoomScale = yMinScale;
    scrollView.maximumZoomScale = maxZoomScale;
    if (scrollView.minimumZoomScale > oldMinZoomScale || scrollView.zoomScale*[crosswordHolder getContentHeight] < scrollView.frame.size.height)
        [scrollView setZoomScale:scrollView.zoomScale*1.001]; // Make tiny zoom, to force an adjustment
    else
        [scrollView setZoomScale:scrollView.zoomScale*0.999];
}

-(void)showKeyboard
{
    keyboardVisible = TRUE;
    landscapeKeyboard.hidden = portraitMode;
    portraitKeyboard.hidden = !portraitMode;
    landscapeKeyboardShadow.hidden = portraitMode;
    portraitKeyboardShadow.hidden = !portraitMode;
    
    if (portraitMode)
    {
        scrollView.frame = CGRectMake(0, topBarHeight, portraitKeyboard.frame.size.width, portraitKeyboard.frame.origin.y-topBarHeight);
    }
    else
    {
        scrollView.frame = CGRectMake(0, topBarHeight, landscapeKeyboard.frame.size.width, landscapeKeyboard.frame.origin.y-topBarHeight);
    }
    [self adjustZoomScale];
}

-(void)hideKeyboard
{
    keyboardVisible = FALSE;
    landscapeKeyboard.hidden = TRUE;
    portraitKeyboard.hidden = TRUE;
    landscapeKeyboardShadow.hidden = TRUE;
    portraitKeyboardShadow.hidden = TRUE;
    
    if (portraitMode)
    {
        scrollView.frame = CGRectMake(0, topBarHeight, portraitKeyboard.frame.size.width, portraitKeyboard.frame.origin.y+portraitKeyboard.frame.size.height-topBarHeight);
    }
    else
    {
        scrollView.frame = CGRectMake(0, topBarHeight, landscapeKeyboard.frame.size.width, landscapeKeyboard.frame.origin.y+landscapeKeyboard.frame.size.height-topBarHeight);
    }
    [self adjustZoomScale];
}

// Called when a square is pressed
-(void)needsKeyboard
{
    if (!keyboardVisible)
        [self showKeyboard];
}

// Auto zoom and scroll to selected word
// Currently not used
-(void)zoomToRect:(CGRect)r
{
    CGRect visibleRect;
    visibleRect.origin = scrollView.contentOffset;
    visibleRect.size = scrollView.bounds.size;
    visibleRect.origin.x /= scrollView.zoomScale;
    visibleRect.origin.y /= scrollView.zoomScale;
    visibleRect.size.width /= scrollView.zoomScale;
    visibleRect.size.height /= scrollView.zoomScale;
    
    NSLog(@"Visible area: (%.f,%.f) to (%.f,%.f)",visibleRect.origin.x,visibleRect.origin.y,
          (visibleRect.origin.x+visibleRect.size.width),(visibleRect.origin.y+visibleRect.size.height));
    NSLog(@"Selected area: (%.f,%.f) to (%.f,%.f)",r.origin.x,r.origin.y,
          (r.origin.x+r.size.width),(r.origin.y+r.size.height));
    
    // Do nothing if the enclosing rectangle is already fully visible
    if (r.origin.x >= visibleRect.origin.x && r.origin.y >= visibleRect.origin.y &&
        r.origin.x + r.size.width < visibleRect.origin.x + visibleRect.size.width &&
        r.origin.y + r.size.height < visibleRect.origin.y + visibleRect.size.height)
        return;

    if (r.size.width < visibleRect.size.width && r.size.height < visibleRect.size.height)
    {
        int w = scrollView.contentSize.width / scrollView.zoomScale;
        int h = scrollView.contentSize.height / scrollView.zoomScale;
        
        float newX = visibleRect.origin.x;
        float newY = visibleRect.origin.y;
        if (r.origin.x < visibleRect.origin.x)
            newX -= visibleRect.origin.x - r.origin.x;
        else if (r.origin.x + r.size.width > visibleRect.origin.x + visibleRect.size.width)
            newX += r.origin.x + r.size.width - (visibleRect.origin.x + visibleRect.size.width);
        if (r.origin.y < visibleRect.origin.y)
            newY -= visibleRect.origin.y - r.origin.y;
        else if (r.origin.y + r.size.height > visibleRect.origin.y + visibleRect.size.height)
            newY += r.origin.y + r.size.height - (visibleRect.origin.y + visibleRect.size.height);

        if (newX < 0)
            newX = 0;
        else if (newX + visibleRect.size.width > w)
            newX = w - visibleRect.size.width;
        if (newY < 0)
            newY = 0;
        else if (newY + visibleRect.size.height > h)
            newY = h - visibleRect.size.height;
        CGPoint newOrigin = CGPointMake(newX*scrollView.zoomScale,newY*scrollView.zoomScale);
        [UIView animateWithDuration:SCROLL_PAN_TIME animations:^(void){
            [scrollView setContentOffset:newOrigin animated:FALSE];
        }];
//        [scrollView setContentOffset:newOrigin animated:TRUE];
        
    }
    else
    {
        
        float newScale = scrollView.zoomScale;
        if (r.size.width/visibleRect.size.width < r.size.height/visibleRect.size.height)
            newScale *= visibleRect.size.height / r.size.height;
        else
            newScale *= visibleRect.size.width / r.size.width;
        
/*        float visibleCenterX = (r.origin.x + r.size.width*0.5)*scrollView.zoomScale - scrollView.contentOffset.x;
        float visibleCenterY = (r.origin.y + r.size.height*0.5)*scrollView.zoomScale - scrollView.contentOffset.y;
        
        float newOffsetX = (r.origin.x + r.size.width*0.5) - visibleCenterX/newScale;
        float newOffsetY = (r.origin.y + r.size.height*0.5) - visibleCenterY/newScale;
        float newWidth = scrollView.bounds.size.width / newScale;
        float newHeight = scrollView.bounds.size.height / newScale;
        
        if (r.origin.x < newOffsetX)
            newOffsetX = r.origin.x;
        else if (r.origin.x + r.size.width > newOffsetX + newWidth)
            newOffsetX = r.origin.x + r.size.width - newWidth;
        if (r.origin.y < newOffsetY)
            newOffsetY = r.origin.y;
        else if (r.origin.y + r.size.height > newOffsetY + newHeight)
            newOffsetY = r.origin.y + r.size.height - newHeight; */
//        CGPoint newOrigin = CGPointMake(newOffsetX*newScale,newOffsetY*newScale);
       
        
//        [scrollView zoomToRect:r animated:TRUE];
//        [UIView animateWithDuration:SCROLL_PAN_TIME animations:^(void){
//            [scrollView zoomToRect:r animated:FALSE];
//        }];
        
        NSLog(@"Only changing zoom scale");
        
        [UIView animateWithDuration:SCROLL_PAN_TIME animations:^(void){
//            [scrollView setContentOffset:newOrigin animated:FALSE];
//            [scrollView setZoomScale:newScale];
            scrollView.zoomScale = newScale;
        }];

    }
    
}

// If possible, maintain screen location of point while zooming to 2X
-(void)doubleTapZoomToPoint:(CGPoint)p
{
    CGPoint currentOrigin = scrollView.contentOffset;
    float oldScale = scrollView.zoomScale;
    float newScale = 2.0 * oldScale;
    if (newScale > scrollView.maximumZoomScale)
        newScale = scrollView.maximumZoomScale;
    [scrollView setZoomScale:newScale];
    float newOffsetX = p.x * (newScale - oldScale) + currentOrigin.x;
    float newOffsetY = p.y * (newScale - oldScale) + currentOrigin.y;
    if (newOffsetX < 0)
        newOffsetX = 0;
    if (newOffsetY < 0)
        newOffsetY = 0;
    scrollView.contentOffset = CGPointMake(newOffsetX, newOffsetY);
}

-(void)panToCursor:(CGRect)cu
{
    CGRect visibleRect;
    visibleRect.origin = scrollView.contentOffset;
    visibleRect.size = scrollView.bounds.size;
    visibleRect.origin.x /= scrollView.zoomScale;
    visibleRect.origin.y /= scrollView.zoomScale;
    visibleRect.size.width /= scrollView.zoomScale;
    visibleRect.size.height /= scrollView.zoomScale;
    
    float x = cu.origin.x-cu.size.width*0.5; // Extra margins
    float y = cu.origin.y-cu.size.height*0.5;
    float w = cu.size.width*2.0;
    float h = cu.size.height*2.0;
    float maxW = scrollView.contentSize.width/scrollView.zoomScale;
    float maxH = scrollView.contentSize.height/scrollView.zoomScale;
    if (x < 0)
        x = 0;
    else if (x + w > maxW)
        x = maxW - w;
    if (y < 0)
        y = 0;
    else if (y + h > maxH)
        y = maxH - h;
    
    CGRect r = CGRectMake(x,y,w,h);    
    if (r.origin.x >= visibleRect.origin.x && r.origin.y >= visibleRect.origin.y &&
        r.origin.x + r.size.width < visibleRect.origin.x + visibleRect.size.width &&
        r.origin.y + r.size.height < visibleRect.origin.y + visibleRect.size.height)
        return;
    
    float newX = visibleRect.origin.x;
    float newY = visibleRect.origin.y;
    if (r.origin.x < visibleRect.origin.x)
        newX -= visibleRect.origin.x - r.origin.x;
    else if (r.origin.x + r.size.width > visibleRect.origin.x + visibleRect.size.width)
        newX += r.origin.x + r.size.width - (visibleRect.origin.x + visibleRect.size.width);
    if (r.origin.y < visibleRect.origin.y)
        newY -= visibleRect.origin.y - r.origin.y;
    else if (r.origin.y + r.size.height > visibleRect.origin.y + visibleRect.size.height)
        newY += r.origin.y + r.size.height - (visibleRect.origin.y + visibleRect.size.height);
    
    CGPoint newOrigin = CGPointMake(newX*scrollView.zoomScale,newY*scrollView.zoomScale);
    
    [scrollView setContentOffset:newOrigin animated:TRUE];
}


-(void)zoomToContent
{
    [scrollView setZoomScale:scrollView.zoomScale*1.01]; // Force a zoom adjustment
    [scrollView zoomToRect:CGRectMake(0,0,[crosswordHolder getContentWidth],[crosswordHolder getContentHeight]) animated:FALSE];
}

#pragma mark -
#pragma mark Menu-called methods

-(IBAction)backButtonPressed:(id)sender
{
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    if (saveTimer)
    {
        [saveTimer invalidate];
        saveTimer = nil;
    }
    [crosswordHolder periodicSave];
    [crosswordHolder uploadToServer];
    [crosswordHolder setClockActive:FALSE];
    SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
//    [delegate goBackFromCrossword];
    [delegate goBack];
}

-(void)prepareToLeave
{
    if (saveTimer)
    {
        [saveTimer invalidate];
        saveTimer = nil;
    }
    [crosswordHolder periodicSave];
    [crosswordHolder setClockActive:FALSE];
}

-(void)jumpBackToMainMenu
{
    self.view.tag = SCREEN_SVD_KRYSS_VIEW_CONTROLLER;
    [self prepareToLeave];
    SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
    [delegate goBack];
}

-(IBAction)hideKeyboardPressed:(id)sender
{
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    [self hideKeyboard];
}

-(IBAction)toggleClock:(id)sender
{
    [[SoundManager sharedInstance] playSound:CLOCK_SOUND];
    BOOL clockActiveState = clockStopLabel.hidden;
    [self setClockActive:clockActiveState];
}

-(void)setClockActive:(BOOL)act
{
    [crosswordHolder setClockActive:act];
    clockStartLabel.hidden = act;
    clockStopLabel.hidden = !act;
}

-(void)periodicSave
{
    // At the moment local save only
    [crosswordHolder periodicSave];
}

#pragma mark -
#pragma mark Leaving or entering foreground

-(void)enterBackground
{
    [crosswordHolder enterBackground];
}

-(void)enterForeground
{
    [crosswordHolder enterForeground];
}

#pragma mark -
#pragma mark Scaling stuff

-(NSString*)platform
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
    return platform;
}

-(float)determineScaleFactorFromWidth:(float)w andHeight:(float)h
{
    float pixels = w*h;
    int maxPixels = MAX_PIXELS_DEFAULT;
    NSString *platformName = [[self platform] lowercaseString];
    
    if ([platformName rangeOfString:@"ipad1"].location == 0)
    {
        maxPixels = MAX_PIXELS_IPAD1;
    }
    else if ([platformName rangeOfString:@"ipod4"].location == 0)
    {
        maxPixels = MAX_PIXELS_IPOD4;
    }
    else if ([platformName rangeOfString:@"ipod5"].location == 0)
    {
        maxPixels = MAX_PIXELS_IPOD5;
    }
    else if ([platformName rangeOfString:@"iphone2"].location == 0)
    {
        maxPixels = MAX_PIXELS_IPHONE3GS;
    }
    else if ([platformName rangeOfString:@"iphone3"].location == 0)
    {
        maxPixels = MAX_PIXELS_IPHONE4;
    }
    else if ([platformName rangeOfString:@"iphone4"].location == 0)
    {
        maxPixels = MAX_PIXELS_IPHONE4S;
    }
    else if ([platformName rangeOfString:@"iphone5"].location == 0)
    {
        maxPixels = MAX_PIXELS_IPHONE5;
    }
    
    NSLog(@"Max pixels: %d",maxPixels);
    
    if (maxPixels >= pixels)
        return 1.0;
    else
        return sqrt(maxPixels/pixels);
}

#pragma mark -
#pragma mark Scroll view delegate methods

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return crosswordHolder;
}

-(void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
}

#pragma mark -
#pragma Rotation

-(BOOL)shouldAutorotate
{
    return TRUE;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

#pragma mark -
#pragma mark For proper centering

-(void)view:(UIView*)view setCenter:(CGPoint)centerPoint
{
    CGRect vf = view.frame;
    CGPoint co = scrollView.contentOffset;
    
    CGFloat x = centerPoint.x - vf.size.width / 2.0;
    CGFloat y = centerPoint.y - vf.size.height / 2.0;
    
    if(x < 0)
    {
        co.x = -x;
        vf.origin.x = 0.0;
    }
    else
    {
        vf.origin.x = x;
    }
    if(y < 0)
    {
        co.y = -y;
        vf.origin.y = 0.0;
    }
    else
    {
        vf.origin.y = y;
    }
    
    view.frame = vf;
    scrollView.contentOffset = co;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    CGPoint centerPoint = CGPointMake(CGRectGetMidX(scrollView.bounds),
                                      CGRectGetMidY(scrollView.bounds));
    [self view:crosswordHolder setCenter:centerPoint];
}

-(void)scrollViewDidZoom:(UIScrollView *)sv
{
    UIView* zoomView = [sv.delegate viewForZoomingInScrollView:sv];
    CGRect zvf = zoomView.frame;
    if(zvf.size.width < sv.bounds.size.width)
    {
        zvf.origin.x = (sv.bounds.size.width - zvf.size.width) / 2.0;
    }
    else
    {
        zvf.origin.x = 0.0;
    }
    if(zvf.size.height < sv.bounds.size.height)
    {
        zvf.origin.y = (sv.bounds.size.height - zvf.size.height) / 2.0;
    }
    else
    {
        zvf.origin.y = 0.0;
    }
    zoomView.frame = zvf;
}

-(void)dealloc {
    [super dealloc];
}

@end
