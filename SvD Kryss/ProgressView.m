//
//  ProgressView.m
//  svdkorsord
//
//  Created by Karl on 2013-09-02.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import "ProgressView.h"

@implementation ProgressView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    float w = rect.size.width;
    float h = rect.size.height;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Skip background gradient
//    NSArray *colors = [NSArray arrayWithObjects:(id)[UIColor lightGrayColor].CGColor,
//                       (id)[UIColor whiteColor].CGColor, nil];
    
//    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (CFArrayRef)colors, NULL);
    
    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
    
    CGContextSetLineWidth(context, 0.5);
    
    UIBezierPath *outerPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0.5, 0.5, w-0.5, h-0.5) cornerRadius:(h-1.0)/2.0];
    [outerPath fill];
    
    CGContextSaveGState(context);
    [outerPath addClip];
//    CGContextDrawLinearGradient(context, gradient, CGPointMake(w/2, 0), CGPointMake(w/2, h*0.7), 0);
//    CGContextRestoreGState(context);
//    CGGradientRelease(gradient);
    
    float tempVal = 0;
    float minVisible = 100.0*h/w;
    if (value >= minVisible)
        tempVal = value;
    else if (value > 0)
        tempVal = minVisible;
    
    if (tempVal > 0)
    {
        NSArray *topColors;
        NSArray *bottomColors;
        
        UIBezierPath *aPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0.5, 0.5, w*tempVal/100.0-0.5, h-0.5) cornerRadius:(h-1.0)/2.0];
        CGContextSetStrokeColorWithColor(context, [UIColor darkGrayColor].CGColor);
        [aPath stroke];
        if (tempVal > 99.0f) // Completely solved
        {
/*            topColors = [NSArray arrayWithObjects:(id)[UIColor colorWithRed:0.75 green:0.9 blue:0.9 alpha:1.0].CGColor,
                         (id)[UIColor colorWithRed:0.32 green:0.72 blue:0.70 alpha:1.0].CGColor, nil];
            bottomColors = [NSArray arrayWithObjects:(id)[UIColor colorWithRed:0.055 green:0.66 blue:0.63 alpha:1.0].CGColor,
                            (id)[UIColor colorWithRed:0.21 green:0.68 blue:0.66 alpha:1.0].CGColor, nil];*/
            topColors = [NSArray arrayWithObjects:(id)[UIColor colorWithRed:0.263 green:0.424 blue:0.682 alpha:1.0].CGColor,
                         (id)[UIColor colorWithRed:0.263 green:0.424 blue:0.682 alpha:1.0].CGColor, nil];
            bottomColors = [NSArray arrayWithObjects:(id)[UIColor colorWithRed:0.263 green:0.424 blue:0.682 alpha:1.0].CGColor,
                            (id)[UIColor colorWithRed:0.263 green:0.424 blue:0.682 alpha:1.0].CGColor, nil];
        }
        else // Not completely solved
        {
/*            topColors = [NSArray arrayWithObjects:(id)[UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0].CGColor,
                         (id)[UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0].CGColor, nil];
            bottomColors = [NSArray arrayWithObjects:(id)[UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0].CGColor,
                            (id)[UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0].CGColor, nil];*/
            topColors = [NSArray arrayWithObjects:(id)[UIColor colorWithRed:0.263 green:0.424 blue:0.682 alpha:1.0].CGColor,
                         (id)[UIColor colorWithRed:0.263 green:0.424 blue:0.682 alpha:1.0].CGColor, nil];
            bottomColors = [NSArray arrayWithObjects:(id)[UIColor colorWithRed:0.263 green:0.424 blue:0.682 alpha:1.0].CGColor,
                            (id)[UIColor colorWithRed:0.263 green:0.424 blue:0.682 alpha:1.0].CGColor, nil];
        }
        CGGradientRef topGradient = CGGradientCreateWithColors(colorSpace, (CFArrayRef)topColors, NULL);
        CGGradientRef bottomGradient = CGGradientCreateWithColors(colorSpace, (CFArrayRef)bottomColors, NULL);
        
        CGContextSaveGState(context);
        [aPath addClip];
        CGContextDrawLinearGradient(context, topGradient, CGPointMake(w/2, 0), CGPointMake(w/2, h/2), 0);
        CGContextDrawLinearGradient(context, bottomGradient, CGPointMake(w/2, h/2), CGPointMake(w/2, h), 0);
        CGContextRestoreGState(context);
        CGGradientRelease(topGradient);
        CGGradientRelease(bottomGradient);
    }
    
    CGContextSetStrokeColorWithColor(context, [UIColor grayColor].CGColor);
    [outerPath stroke];
    
    CGColorSpaceRelease(colorSpace);
}

-(void)setValue:(float)v
{
    value = v;
    [self setNeedsDisplay];
}

@end
