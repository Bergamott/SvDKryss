//
//  PDFDisplay.h
//  svdkorsord
//
//  Created by Karl on 2013-04-15.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PDFDisplay : UIView {
    
    float scale;
    float contentX;
    float contentY;
    float contentWidth;
    float contentHeight;
    
    NSString *filenameBase;
    NSURL *pdfUrl;
}

-(void)setScale:(float)sc picX:(float)px picY:(float)py picW:(float)pw picH:(float)ph;

@property(nonatomic,retain) NSString *filenameBase;
@property(nonatomic,retain) NSURL *pdfUrl;

@end
