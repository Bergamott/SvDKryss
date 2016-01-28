//
//  PDFDisplay.m
//  svdkorsord
//
//  Created by Karl on 2013-04-15.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import "PDFDisplay.h"

@implementation PDFDisplay

@synthesize filenameBase;
@synthesize pdfUrl;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)setScale:(float)sc picX:(float)px picY:(float)py picW:(float)pw picH:(float)ph
{
    scale = sc;
    contentX = px;
    contentY = py;
    contentWidth = pw;
    contentHeight = ph;
}

-(void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    CGPDFDocumentRef document;
    document = CGPDFDocumentCreateWithURL((CFURLRef)pdfUrl);
    
    CGPDFPageRef page = CGPDFDocumentGetPage (document, 1);
    CGRect pageRect = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);

    CGContextScaleCTM(context, scale, -scale);
    CGContextTranslateCTM(context, -contentX, contentY-pageRect.size.height);
    
    CGContextDrawPDFPage (context, page);
    
    CGContextRestoreGState(context);
    CGPDFDocumentRelease (document);
}


@end
