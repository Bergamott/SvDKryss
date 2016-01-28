//
//  PreViewController.m
//  SvD Kryss
//
//  Created by Karl on 2013-02-18.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import "PreViewController.h"
#import "SvDKryssAppDelegate.h"
#import "SoundManager.h"
#import "StoreDataHolder.h"
#import "DataHolder.h"

#import "SDWebImage/UIImageView+WebCache.h"

#import "GAI.h"
#import "GAIDictionaryBuilder.h"

#define WEB_CROSSWORD_DIRECTORY @"http://www.javaonthebrain.com/korsord/"

@interface PreViewController ()

@end

@implementation PreViewController

@synthesize package;
@synthesize trimmedIDList;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.screenName = @"preview - hamta";
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
-(void)setUpWithPackage:(NSDictionary*)pk andCrosswordNumber:(int)cn
{
    self.package = pk;
    crosswordNumber = cn;
    NSArray *cwIDs = [package objectForKey:@"crosswords"];
    crosswordCount = [cwIDs count];
    NSArray *viewsToRemove = [dotView subviews];
    for (UIView *v in viewsToRemove) {
        [v removeFromSuperview];
    }
    float dotWidth;
    float dotHeight;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        dotWidth = 12.0;
        dotHeight = 12.0;
    }
    else
    {
        dotWidth = 20.0;
        dotHeight = 21.0;
    }
    UIImage *plainDot = [UIImage imageNamed:@"radiobutton_unselected.png"];
    UIImage *selectedDot = [UIImage imageNamed:@"radiobutton_selected.png"];
    for (int i=0;i<crosswordCount;i++)
    {
        UIImageView *tmpIV = [[UIImageView alloc] initWithImage:plainDot];
        [tmpIV setHighlightedImage:selectedDot];
        CGRect r = CGRectMake(dotView.frame.size.width*0.5-crosswordCount*dotWidth*0.65+i*dotWidth*1.3, dotView.frame.size.height*0.5-dotHeight*0.5, dotWidth, dotHeight);
        [tmpIV setFrame:r];
        [dotView addSubview:tmpIV];
        [tmpIV release];
    }
    
    [self loadCrossword];
}
*/

-(void)setUpWithPackage:(NSDictionary*)pk andCrosswordID:(NSNumber*)cwId
{
    self.package = pk;
    self.trimmedIDList = [[StoreDataHolder sharedStoreDataHolder] filterOutUnpublishedCrosswords:[package objectForKey:@"crosswords"]];
    crosswordNumber = (int)[trimmedIDList indexOfObject:cwId];
    crosswordCount = (int)[trimmedIDList count];
    
    NSArray *viewsToRemove = [dotView subviews];
    for (UIView *v in viewsToRemove) {
        [v removeFromSuperview];
    }
    float dotWidth;
    float dotHeight;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        dotWidth = 12.0;
        dotHeight = 12.0;
    }
    else
    {
        dotWidth = 20.0;
        dotHeight = 21.0;
    }
    UIImage *plainDot = [UIImage imageNamed:@"radiobutton_unselected.png"];
    UIImage *selectedDot = [UIImage imageNamed:@"radiobutton_selected.png"];
    for (int i=0;i<crosswordCount;i++)
    {
        UIImageView *tmpIV = [[UIImageView alloc] initWithImage:plainDot];
        [tmpIV setHighlightedImage:selectedDot];
        CGRect r = CGRectMake(dotView.frame.size.width*0.5-crosswordCount*dotWidth*0.65+i*dotWidth*1.3, dotView.frame.size.height*0.5-dotHeight*0.5, dotWidth, dotHeight);
        [tmpIV setFrame:r];
        [dotView addSubview:tmpIV];
        [tmpIV release];
    }
    
    [self loadCrossword];
}

-(void)loadCrossword
{
    NSDictionary *cw = [[StoreDataHolder sharedStoreDataHolder].storeCrosswords objectAtIndex:[[StoreDataHolder sharedStoreDataHolder].storeCrosswordIds indexOfObject:[trimmedIDList objectAtIndex:crosswordNumber]]];
//    headline.text = [cw objectForKey:@"name"];
//    description.text = [cw objectForKey:@"fullDescription"];
    description.text = [[DataHolder sharedDataHolder] getHeadlineFromCrossword:cw];
    NSURL *url = [NSURL URLWithString:[[cw objectForKey:@"previewUrl"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
//    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];

    activityIndicator.hidden = FALSE;
    [activityIndicator startAnimating];
    [scrollContent setImageWithURL:url placeholderImage:NULL options:SDWebImageProgressiveDownload
                           success:^(UIImage *image, BOOL cached) {
                               [self crosswordLoaded];
                           }
                           failure:^(NSError *error) {
                               [activityIndicator stopAnimating];
                               activityIndicator.hidden = TRUE;
                           }];
    
    for (int i=0;i<crosswordCount;i++)
    {
        UIImageView *tmpIV = [[dotView subviews] objectAtIndex:i];
        tmpIV.highlighted = (i == crosswordNumber);
    }
}

-(IBAction)backButtonPressed:(id)sender
{
    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
    SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];

    [delegate goBack];
}

-(IBAction)backwardArrowPressed:(id)sender
{
    if (activityIndicator.hidden)
    {
        crosswordNumber = (crosswordNumber + crosswordCount - 1) % crosswordCount;
        [self loadCrossword];
        [self sendGAEvent:@"bladdra preview"];
    }
}

-(IBAction)forwardArrowPressed:(id)sender
{
    if (activityIndicator.hidden)
    {
        crosswordNumber = (crosswordNumber + 1) % crosswordCount;
        [self loadCrossword];
        [self sendGAEvent:@"bladdra preview"];
    }
}

-(void)sendGAEvent:(NSString*)action
{
    id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:GA_ID];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"UIAction"
                                                          action:@"buttonPress"
                                                           label:@"action"
                                                           value:nil] build]];
}

-(void)crosswordLoaded
{
    [activityIndicator stopAnimating];
    activityIndicator.hidden = TRUE;
    imageScroller.delegate = self;
    
    float imW = scrollContent.image.size.width;
    float imH = scrollContent.image.size.height;
    float scW = imageScroller.frame.size.width;
    float scH = imageScroller.frame.size.height;
    
    [scrollContent removeFromSuperview];
    scrollContent.transform = CGAffineTransformIdentity;
    scrollContent.frame = CGRectMake(0,0,imW,imH);
    
    float minScale = scW/imW;
    if (scH / imH < minScale)
        minScale = scH / imH;
    
    [imageScroller addSubview:scrollContent];
    imageScroller.contentSize = CGSizeMake(imW,imH);
    
    imageScroller.minimumZoomScale = minScale;
    imageScroller.maximumZoomScale = 1.0;
    [imageScroller zoomToRect:CGRectMake(0,0,imW,imH) animated:FALSE];
}

#pragma mark -
#pragma Scroll view delegate methods

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return scrollContent;
}

-(void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
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
#pragma mark For proper centering

-(void)view:(UIView*)view setCenter:(CGPoint)centerPoint
{
    CGRect vf = view.frame;
    CGPoint co = imageScroller.contentOffset;
    
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
    imageScroller.contentOffset = co;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    CGPoint centerPoint = CGPointMake(CGRectGetMidX(imageScroller.bounds),
                                      CGRectGetMidY(imageScroller.bounds));
    [self view:scrollContent setCenter:centerPoint];
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


@end
