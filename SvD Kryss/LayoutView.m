//
//  LayoutView.m
//  AutoLayout
//
//  Created by Karl on 2013-06-25.
//  Copyright (c) 2013 Eweguo. All rights reserved.
//

#import "LayoutView.h"

@implementation LayoutView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)determineMargins
{
    originalHeight = self.frame.size.height;
    float currentY = 0.0;
    int i=0;
    for (UIView *tmpV in self.subviews)
    {
        if (tmpV.tag != 0)
        {
            topMargins[i] = tmpV.frame.origin.y - currentY;
            currentY = tmpV.frame.origin.y + tmpV.frame.size.height;
        }
        i++;
    }
    bottomMargin = originalHeight - currentY;
}

-(void)resizeSweep
{
    int i=0;
    combinedHeight = 0.0;
    for (UIView *tmpV in self.subviews)
    {
        if (tmpV.tag != 0 && !tmpV.hidden)
        {
            if ([tmpV isKindOfClass: [UITextView class]])
            {
                CGRect newFrame = tmpV.frame;
                // Incredibly stupid workaround for iOS 7
                NSString *strCopy = [NSString stringWithString:((UITextView*)tmpV).text];
                ((UITextView*)tmpV).text = strCopy;
//                ((UITextView*)tmpV).font = [UIFont fontWithName:@"SuecaWebSlab-Regular" size:tmpV.tag];
                ((UITextView*)tmpV).font = [UIFont fontWithName:@"SuecaSans-Regular" size:tmpV.tag];
                CGSize textSize = [((UITextView*)tmpV) sizeThatFits:CGSizeMake(newFrame.size.width, FLT_MAX)];
                newFrame.size = CGSizeMake(newFrame.size.width, textSize.height);
                tmpV.frame = newFrame;
            }
            if (![tmpV isKindOfClass: [UITableView class]])
                combinedHeight += tmpV.frame.size.height;
            combinedHeight += topMargins[i];
        }
        i++;
    }
    combinedHeight += bottomMargin;
}

-(void)pack
{
    [self resizeSweep];
    float currentY = 0.0;
    int i=0;
    for (UIView *tmpV in self.subviews)
    {
        if (tmpV.tag != 0 && !tmpV.hidden)
        {
            currentY += topMargins[i];
            CGRect newFrame = CGRectMake(tmpV.frame.origin.x, currentY, tmpV.frame.size.width, tmpV.frame.size.height);
            currentY += tmpV.frame.size.height;
            tmpV.frame = newFrame;
        }
        i++;
    }
    currentY += bottomMargin;
    CGRect newFrame = self.frame;
    newFrame.size = CGSizeMake(self.frame.size.width, currentY);
    self.frame = newFrame;
}

-(void)fillUp
{
    [self resizeSweep];
    float tableHeight = originalHeight - combinedHeight;
    float currentY = 0.0;
    int i=0;
    for (UIView *tmpV in self.subviews)
    {
        if (tmpV.tag != 0 && !tmpV.hidden)
        {
            currentY += topMargins[i];
            CGRect newFrame;
            if ([tmpV isKindOfClass: [UITableView class]])
            {
                newFrame = CGRectMake(tmpV.frame.origin.x, currentY, tmpV.frame.size.width, tableHeight);
            }
            else
                newFrame = CGRectMake(tmpV.frame.origin.x, currentY, tmpV.frame.size.width, tmpV.frame.size.height);
            currentY += tmpV.frame.size.height;
            tmpV.frame = newFrame;
        }
        i++;
    }
}

@end
