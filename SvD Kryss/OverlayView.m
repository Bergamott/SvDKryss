//
//  OverlayView.m
//  SvD Kryss
//
//  Created by Karl on 2013-01-11.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import "OverlayView.h"
#import "Metadata.h"

@implementation OverlayView

@synthesize metadata;
@synthesize letterImages;
@synthesize selector;
//@synthesize selectorGreen;
@synthesize darkGreen;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)setupWithMetadata:(Metadata*)md
{
    self.metadata = md;
    
	letterImages = [[NSMutableArray alloc] initWithCapacity:35];
	UIImage *tmp = [UIImage imageNamed:@"lettergrid.png"];
	for (int i=0;i<6;i++)
		for (int j=0;j<5;j++)
		{
			CGRect fromRect = CGRectMake(j*100, i*100, 100, 100);
			CGImageRef drawImage = CGImageCreateWithImageInRect(tmp.CGImage, fromRect);
			UIImage *newImage = [UIImage imageWithCGImage:drawImage];
			[letterImages addObject:newImage];
			CGImageRelease(drawImage);
		}
    self.selector = [UIImage imageNamed:@"selector.png"];
    self.darkGreen = [[UIColor alloc] initWithRed:0 green:0.7 blue:0 alpha:1.0];
}

-(void)drawRect:(CGRect)rect
{
    drawingLock = TRUE;
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if ([metadata hasSelectedWord])
    {
        CGContextSetStrokeColorWithColor(context, [UIColor blueColor].CGColor);
        CGContextSetRGBFillColor(context, 0, 0, 1.0, 0.25);
        
        CGContextSetLineWidth(context, selectionLineThickness);
        CGMutablePathRef pathRef;
        
//        int numSegments = [metadata getSelectionPath:workPoints];
        int numSegments = [metadata getMultipleSelectionPath:workPoints];
        int i=0;
        for (int j=0;j<numSegments;j++)
        {
            pathRef = CGPathCreateMutable();
            CGPathMoveToPoint(pathRef, NULL, workPoints[i].x,workPoints[i].y); //start at this point
            i++;
            while (workPoints[i].x >= 0)
            {
                CGPathAddLineToPoint(pathRef, NULL, workPoints[i].x, workPoints[i].y);
                i++;
            }
            CGPathCloseSubpath(pathRef);
        
            CGContextAddPath(context, pathRef);
            CGContextFillPath(context);
            CGPathRelease(pathRef);
            i++;
        }
        
/*        if ([metadata hasSelection])
        {
            [selector drawInRect:[metadata getSelectedBoxCoordinates]];
        }*/
        
        i=0;
        for (int j=0;j<numSegments;j++)
        {
            pathRef = CGPathCreateMutable();
            CGPathMoveToPoint(pathRef, NULL, workPoints[i].x,workPoints[i].y); //start at this point
            i++;
            while (workPoints[i].x >= 0)
            {
                CGPathAddLineToPoint(pathRef, NULL, workPoints[i].x, workPoints[i].y);
                i++;
            }
            CGPathCloseSubpath(pathRef);
            
            CGContextAddPath(context, pathRef);
            CGContextStrokePath(context);
            CGPathRelease(pathRef);
            i++;
        }
        
    }
    
    // Filled-in characters
    int h = [metadata getHorizontalSize];
    int v = [metadata getVerticalSize];
    CGContextSetLineWidth(context, helpLineThickness);
    if (shouldShowSolution)
    {
        CGContextSetStrokeColorWithColor(context, darkGreen.CGColor);
        for (int i=0;i<v;i++)
            for (int j=0;j<h;j++)
            {
                int c = [self charToPic:[metadata getSolutionAtH:j andV:i]];
                if (c >= 0)
                {
                
                    CGRect charBox = [metadata getBoxCoordinatesAtH:j andV:i];
                    [((UIImage*)[letterImages objectAtIndex:c]) drawInRect:charBox];
                    if ([metadata isRightAtH:j andV:i])
                    {
                        CGContextAddEllipseInRect(context, CGRectMake(charBox.origin.x+0.1*charBox.size.width, charBox.origin.y+0.1*charBox.size.height, charBox.size.width*0.8, charBox.size.height*0.8));
                        CGContextStrokePath(context);
                    }
                }
            }
    }
    else
    {
        for (int i=0;i<v;i++)
            for (int j=0;j<h;j++)
            {
                int c = [self charToPic:[metadata getCharacterAtH:j andV:i]];
                if (c >= 0)
                {
                    CGRect charBox = [metadata getBoxCoordinatesAtH:j andV:i];
                    if (CGRectIntersectsRect(rect, charBox))
                    {
                        [((UIImage*)[letterImages objectAtIndex:c]) drawInRect:charBox];
                        if ([metadata shouldShowRightAndWrong])
                        {
                            if ([metadata isWrongAtH:j andV:i])
                            {
                                CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
                                CGContextMoveToPoint(context, charBox.origin.x+charBox.size.width*0.9, charBox.origin.y+charBox.size.height*0.1);
                                CGContextAddLineToPoint(context, charBox.origin.x+charBox.size.width*0.1, charBox.origin.y+charBox.size.height*0.9);
                                CGContextStrokePath(context);
                            }
                            else if ([metadata isRightAtH:j andV:i])
                            {
                                CGContextSetStrokeColorWithColor(context, darkGreen.CGColor);
                                CGContextAddEllipseInRect(context, CGRectMake(charBox.origin.x+0.1*charBox.size.width, charBox.origin.y+0.1*charBox.size.height, charBox.size.width*0.8, charBox.size.height*0.8));
                                CGContextStrokePath(context);
                            }
                        }
                    }
                }
            }
    }
    drawingLock = FALSE;
    shouldShowSolution = FALSE;
    [metadata finishedShowingRightAndWrong];
}

-(int)charToPic:(int)c
{
    int l = -1;
    if (c >= 'a' && c <= 'z')
    {
        l = c - 'a';
    }
    else if (c >= 'A' && c <= 'Z')
    {
        l = c - 'A';
    }
    else if (c == 0x00c5 || c == 0x00e5)
        l = 26;
    else if (c == 0x00c4 || c == 0x00e4)
        l = 27;
    else if (c == 0x00d6 || c == 0x00f6)
        l = 28;
    return l;
}

-(void)keyTyped:(int)key
{
    if (key>=65)
        [metadata typeCharacter:key];
    else if (key==8)
        [metadata typeBackspace];

    [self askForRedraw];
}

-(void)askForRedraw
{
    if (!drawingLock)
        [self setNeedsDisplayInRect:[metadata getRefreshRect]];
}

-(void)markWordAsCorrect:(BOOL)c
{
    markWordCorrect = c;
    markCharacterCorrect = c;
    [self askForRedraw];
}

-(void)markCharacterAsCorrect:(BOOL)c
{
    markCharacterCorrect = c;
    [self askForRedraw];
}

-(void)showSolution
{
    shouldShowSolution = TRUE;
    [self askForRedraw];
}

-(void)setLineThicknessScale:(float)sc
{
    selectionLineThickness = 5.0 * sc;
    helpLineThickness = 6.0 * sc;
}

- (void)dealloc {
    [super dealloc];
	[letterImages release];
    [metadata release];
    [selector release];
//    [selectorGreen release];
    [darkGreen release];
}

@end
