//
//  CustomAlertView.m
//  SvD Kryss
//
//  Created by Karl on 2013-02-12.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import "CustomAlertView.h"

@implementation CustomAlertView

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
    // Got example from http://mobile.tutsplus.com/tutorials/iphone/ios-sdk-uialertview-custom-graphics/
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect activeBounds = self.bounds;
    CGFloat cornerRadius = 10.0f;
    CGFloat inset = 6.5f;
    CGFloat originX = activeBounds.origin.x + inset;
    CGFloat originY = activeBounds.origin.y + inset;
    CGFloat width = activeBounds.size.width - (inset*2.0f);
    CGFloat height = activeBounds.size.height - (inset*2.0f);
    CGRect bPathFrame = CGRectMake(originX, originY, width, height);
    CGPathRef path = [UIBezierPath bezierPathWithRoundedRect:bPathFrame cornerRadius:cornerRadius].CGPath;
    
    CGContextAddPath(context, path);
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:210.0f/255.0f green:210.0f/255.0f blue:210.0f/255.0f alpha:1.0f].CGColor);
    CGContextSetShadowWithColor(context, CGSizeMake(0.0f, 1.0f), 6.0f, [UIColor colorWithRed:0.0f/255.0f green:0.0f/255.0f blue:0.0f/255.0f alpha:1.0f].CGColor);
    CGContextDrawPath(context, kCGPathFill);
    
    CGContextSaveGState(context); //Save Context State Before Clipping To "path"
    CGContextAddPath(context, path);
    CGContextClip(context);
    
    // Draw gradient
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    size_t count = 3;
    CGFloat locations[3] = {0.0f, 0.57f, 1.0f};
    CGFloat components[12] =
    {
        70.0f/255.0f, 70.0f/255.0f, 70.0f/255.0f, 1.0f,     //1
        55.0f/255.0f, 55.0f/255.0f, 55.0f/255.0f, 1.0f,     //2
        40.0f/255.0f, 40.0f/255.0f, 40.0f/255.0f, 1.0f      //3
    };
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, components, locations, count);
    CGPoint startPoint = CGPointMake(activeBounds.size.width * 0.5f, 0.0f);
    CGPoint endPoint = CGPointMake(activeBounds.size.width * 0.5f, activeBounds.size.height);
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    CGColorSpaceRelease(colorSpace);
    CGGradientRelease(gradient);
    
    // Create a hatched background
    CGFloat buttonOffset = 92.5f; //Offset buttonOffset by half point for crisp lines
    CGContextSaveGState(context); //Save Context State Before Clipping "hatchPath"
    CGRect hatchFrame = CGRectMake(0.0f, buttonOffset, activeBounds.size.width, (activeBounds.size.height - buttonOffset+1.0f));
    CGContextClipToRect(context, hatchFrame);
    CGFloat spacer = 4.0f;
    int rows = (activeBounds.size.width + activeBounds.size.height/spacer);
    CGFloat padding = 0.0f;
    CGMutablePathRef hatchPath = CGPathCreateMutable();
    for(int i=1; i<=rows; i++) {
        CGPathMoveToPoint(hatchPath, NULL, spacer * i, padding);
        CGPathAddLineToPoint(hatchPath, NULL, padding, spacer * i);
    }
    CGContextAddPath(context, hatchPath);
    CGPathRelease(hatchPath);
    CGContextSetLineWidth(context, 1.0f);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:0.0f/255.0f green:0.0f/255.0f blue:0.0f/255.0f alpha:0.15f].CGColor);
    CGContextDrawPath(context, kCGPathStroke);
    CGContextRestoreGState(context); //Restore Last Context State Before Clipping "hatchPath"
        
    // Inner shadow
    CGContextAddPath(context, path);
    CGContextSetLineWidth(context, 3.0f);
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:210.0f/255.0f green:210.0f/255.0f blue:210.0f/255.0f alpha:1.0f].CGColor);
    CGContextSetShadowWithColor(context, CGSizeMake(0.0f, 0.0f), 6.0f, [UIColor colorWithRed:0.0f/255.0f green:0.0f/255.0f blue:0.0f/255.0f alpha:1.0f].CGColor);
    CGContextDrawPath(context, kCGPathStroke);
    
    // Redraw path to avoid pixelation
    CGContextRestoreGState(context); //Restore First Context State Before Clipping "path"
    CGContextAddPath(context, path);
    CGContextSetLineWidth(context, 3.0f);
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:210.0f/255.0f green:210.0f/255.0f blue:210.0f/255.0f alpha:1.0f].CGColor);
    CGContextSetShadowWithColor(context, CGSizeMake(0.0f, 0.0f), 0.0f, [UIColor colorWithRed:0.0f/255.0f green:0.0f/255.0f blue:0.0f/255.0f alpha:0.1f].CGColor);
    CGContextDrawPath(context, kCGPathStroke);
}


-(void)layoutSubviews
{
    for (UIView *subview in self.subviews){ //Fast Enumeration
        if ([subview isMemberOfClass:[UIImageView class]]) {
            subview.hidden = YES; //Hide UIImageView Containing Blue Background
        }
        if ([subview isMemberOfClass:[UILabel class]]) { //Point to UILabels To Change Text
            UILabel *label = (UILabel*)subview; //Cast From UIView to UILabel
            label.textColor = [UIColor colorWithRed:210.0f/255.0f green:210.0f/255.0f blue:210.0f/255.0f alpha:1.0f];
            label.shadowColor = [UIColor blackColor];
            label.shadowOffset = CGSizeMake(0.0f, 1.0f);
        }
    }
}

@end
