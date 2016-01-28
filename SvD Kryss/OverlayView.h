//
//  OverlayView.h
//  SvD Kryss
//
//  Created by Karl on 2013-01-11.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Metadata;

@interface OverlayView : UIView {
    
    Metadata *metadata;
	NSMutableArray *letterImages;
    
    CGPoint workPoints[100];
    UIImage *selector;
    
    BOOL drawingLock;
    BOOL markWordCorrect;
    BOOL markCharacterCorrect;
    BOOL shouldShowSolution;
    
    UIColor *darkGreen;
    float selectionLineThickness;
    float helpLineThickness;
}

-(void)setupWithMetadata:(Metadata*)md;
-(int)charToPic:(int)c;
-(void)keyTyped:(int)key;

-(void)askForRedraw;

-(void)markWordAsCorrect:(BOOL)c;
-(void)markCharacterAsCorrect:(BOOL)c;
-(void)showSolution;

-(void)setLineThicknessScale:(float)sc;

@property(nonatomic,retain) Metadata *metadata;
@property(nonatomic,retain) NSMutableArray *letterImages;
@property(nonatomic,retain) UIImage *selector;
//@property(nonatomic,retain) UIImage *selectorGreen;
@property(nonatomic,retain) UIColor *darkGreen;


@end
