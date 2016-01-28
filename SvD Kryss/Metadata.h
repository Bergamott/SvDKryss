//
//  Metadata.h
//  MenuTest
//
//  Created by Karl on 2012-12-28.
//  Copyright (c) 2012 Karl. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MAX_W 100
#define MAX_H 70
#define MAX_CLUES 1000
#define MAX_NUMBERS 20
#define MAX_YELLOW 50

#define SOLUTION_FILLED_IN 0
#define SOLUTION_MISSING_NUMBERS 1
#define SOLUTION_MISSING_LETTERS 2

typedef struct _GridPos {
    int h;
    int v;
} GridPos;

@interface Metadata : NSObject {
    
    int crosswordType;
    int numHorizontal,numVertical;
    int x,y,height,width;
    
    // Character box metadata, ordered in a grid
    int boxX[MAX_H][MAX_W];
    int boxY[MAX_H][MAX_W];
    int boxWidth[MAX_H][MAX_W];
    int boxHeight[MAX_H][MAX_W];
    int boxTurn[MAX_H][MAX_W];
    int solution[MAX_H][MAX_W];
    int barriers[MAX_H][MAX_W];
    int clueDirections[MAX_H][MAX_W];
    
    // Clue box metadata, just a list
    int numClues;
    int clueX[MAX_CLUES];
    int clueY[MAX_CLUES];
    int clueWidth[MAX_CLUES];
    int clueHeight[MAX_CLUES];
    BOOL clueHorizontal[MAX_CLUES];
    int clueWordH[MAX_CLUES];
    int clueWordV[MAX_CLUES];
    
    // Yellow word data
    int numYellow;
    int yellowX[MAX_YELLOW];
    int yellowY[MAX_YELLOW];
    int yellowWidth[MAX_YELLOW];
    int yellowHeight[MAX_YELLOW];
    int yellowNumLetters[MAX_YELLOW];
    GridPos yellowPos[MAX_YELLOW][MAX_W];
    
    BOOL hasSolution;
    
    BOOL selectHorizontally;
    GridPos currentSelection;
    GridPos selectedWord[MAX_W];
    CGPoint selectedPath[MAX_W*2];
    
    // User generated data
    int characters[MAX_H][MAX_W];
    BOOL drawnWithMarker[MAX_H][MAX_W];
    BOOL permanentMarker;
    BOOL clockActive;
    int clockSeconds;
    // Wrong/right character markers
    BOOL markedWrong[MAX_H][MAX_W];
    BOOL markedRight[MAX_H][MAX_W];
    BOOL showRightAndWrong;
    
    // Filled in count
    int numLetterBoxes;
    int numFilledIn;
    
    // Refresh data
    CGRect refreshRect;
    CGRect oldSelectionRect;
    
    // For proper PDF scaling
    float scaleFactor;
    
    // In case of overlapping clues
    int toggleCounter;
    
    GridPos numberPos[MAX_NUMBERS];
    int numberBoxes;
}

-(void)setupWithData:(NSData*)fileData;
-(void)setUserDataFromData:(NSData*)fileData;
-(BOOL)isEqualToUserData:(NSData*)updateData;

-(int)getHorizontalSize;
-(int)getVerticalSize;
-(BOOL)hasSelection;
-(BOOL)hasSelectedWord;
-(GridPos)getSelectionFromX:(float)xPos andY:(float)yPos;
-(int)getCharacterAtH:(int)hPos andV:(int)vPos;
-(int)getSolutionAtH:(int)hPos andV:(int)vPos;
-(void)setCharacter:(int)ch AtH:(int)hPos andV:(int)vPos;
-(void)selectBoxAtH:(int)hPos andV:(int)vPos;
-(BOOL)selectedClueAtX:(float)xPos andY:(float)yPos;
-(int)squaresFromStartAtH:(int)hPos andV:(int)vPos horizontally:(BOOL)hz;
-(GridPos)getCurrentSelection;
-(BOOL)correctSolutionAtH:(int)hPos andV:(int)vPos;
-(BOOL)solutionExists;
-(BOOL)hasNumberCompetition;
//-(int)getSelectionPath:(CGPoint[])pathHolder;
-(int)getMultipleSelectionPath:(CGPoint[])pathHolder;
-(CGRect)getSelectedBoxCoordinates;
-(CGRect)getBoxCoordinatesAtH:(int)hPos andV:(int)vPos;
-(CGRect)getWordBoundingBox;
-(void)typeCharacter:(int)ch;
-(void)typeBackspace;
-(BOOL)isWordCompleteAtH:(int)hPos andV:(int)vPos horizontally:(BOOL)hz;

-(void)saveFilledInCharactersAs:(NSString*)fileName;
-(NSString*)getFilledInCharactersAsBase64String;

-(void)clearWrongAndRightFlags;
-(BOOL)shouldShowRightAndWrong;
-(void)finishedShowingRightAndWrong;
-(BOOL)findWrongCharactersInWord;
-(BOOL)correctCharactersInWord;
-(BOOL)isWrongAtH:(int)hPos andV:(int)vPos;
-(BOOL)isRightAtH:(int)hPos andV:(int)vPos;

-(BOOL)setCorrectCharacterAtSelection;
-(BOOL)helpWithCharacterAtSelection;

-(void)markAllWrongCharacters;
-(void)correctAllWrongCharacters;
-(void)checkIfAllIsCorrect;

-(void)clearAllCharacters;

-(BOOL)isDrawnWithMarkerAtH:(int)hPos andV:(int)vPos;
-(void)activatePermanentMarker:(BOOL)active;
-(BOOL)isPermanentMarkerActive;
-(BOOL)isClockActive;
-(void)activateClock:(BOOL)act;
-(int)getClockSeconds;
-(void)setClockSeconds:(int)s;

-(int)getFilledInPercent;

-(CGRect)getRefreshRect;
-(void)updateRefreshRectangle;
-(void)markAllToRefresh;
-(void)updateRefreshRectangleForTypingFromPos:(GridPos)p1 toPos:(GridPos)p2;

-(CGRect)getContentRect;
-(void)setScaleFactor:(float)sc;

-(NSString*)getCompetitionString;
-(int)checkSolutionStatus;

@end
