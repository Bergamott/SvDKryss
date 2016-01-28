//
//  Metadata.m
//  MenuTest
//
//  Created by Karl on 2012-12-28.
//  Copyright (c) 2012 Karl. All rights reserved.
//

#import "Metadata.h"
#import "SoundManager.h"
#import "DownloadManager.h"

#define CHAR_BITS 1023
#define TOP_BARRIER 1
#define BOTTOM_BARRIER 2
#define LEFT_BARRIER 4
#define RIGHT_BARRIER 8
#define TURN_DOWN 1
#define TURN_RIGHT 2


@implementation Metadata
    
-(id)init
{
    self = [super init];
    if (self) {
        currentSelection.h = -1;
        currentSelection.v = -1;
        scaleFactor = 1.0;
    }
    return self;
}

-(void)setupWithData:(NSData*)fileData
{
    NSLog(@"Setting up with data");
    unsigned char *bytePtr = (unsigned char *)[fileData bytes];
    int i = 0;
    hasSolution = FALSE;
    crosswordType = bytePtr[i++];
    
    numVertical = bytePtr[i++];
    numHorizontal = bytePtr[i++];
    
    for (int j=0;j<MAX_NUMBERS;j++) // Clear solution number positions
    {
        numberPos[j].h = -1;
        numberPos[j].v = -1;
    }
    
    x = bytePtr[i++]*256;
    x += bytePtr[i++];
    y = bytePtr[i++]*256;
    y += bytePtr[i++];
    width = bytePtr[i++]*256;
    width += bytePtr[i++];
    height = bytePtr[i++]*256;
    height += bytePtr[i++];
    
    numLetterBoxes = 0;
    numberBoxes = 0;
    for (int j=0;j<numVertical;j++)
        for (int k=0;k<numHorizontal;k++)
        {
            int bits = bytePtr[i++]*256;
            bits += bytePtr[i++];
            
            if (bits & 1)
            {
                clueDirections[j][k] = (bits/2)&3;
                boxTurn[j][k] = (bits / 8)&3;
                barriers[j][k] = (bits / 32)&15;
                boxX[j][k] = bytePtr[i++]*256;
                boxX[j][k] += bytePtr[i++];
                boxY[j][k] = bytePtr[i++]*256;
                boxY[j][k] += bytePtr[i++];
                boxWidth[j][k] = bytePtr[i++]*256;
                boxWidth[j][k] += bytePtr[i++];
                boxHeight[j][k] = bytePtr[i++]*256;
                boxHeight[j][k] += bytePtr[i++];
                solution[j][k] = bytePtr[i++]*256;
                solution[j][k] += bytePtr[i++];
                if (solution[j][k] > 0)
                    hasSolution = TRUE;
                
                int numBox = (bits >> 9);
                if (numBox > 0)
                {
                    numberPos[numBox-1].h = k;
                    numberPos[numBox-1].v = j;
                    if (numBox > numberBoxes)
                        numberBoxes = numBox;
                }

                numLetterBoxes++;
            }
            
            characters[j][k] = 0;
        }
    
    numClues = 0;
    if (i < fileData.length) // More data? Handle clue boxes
    {
        numClues = bytePtr[i++]*256;
        numClues += bytePtr[i++];
        for (int j=0;j<numClues;j++)
        {
            clueX[j] = bytePtr[i++]*256;
            clueX[j] += bytePtr[i++];
            clueY[j] = bytePtr[i++]*256;
            clueY[j] += bytePtr[i++];
            clueWidth[j] = bytePtr[i++]*256;
            clueWidth[j] += bytePtr[i++];
            clueHeight[j] = bytePtr[i++]*256;
            clueHeight[j] += bytePtr[i++];
            clueWordH[j] = bytePtr[i++];
            clueWordV[j] = bytePtr[i++];
            clueHorizontal[j] = ((clueWordV[j] & 128) > 0);
            clueWordV[j] &= 127;
        }
    }
    
    if (i < fileData.length) // Still more data? Yellow words
    {
        numYellow = bytePtr[i++];
        for (int j=0;j<numYellow;j++)
        {
            yellowX[j] = bytePtr[i++]*256;
            yellowX[j] += bytePtr[i++];
            yellowY[j] = bytePtr[i++]*256;
            yellowY[j] += bytePtr[i++];
            yellowWidth[j] = bytePtr[i++]*256;
            yellowWidth[j] += bytePtr[i++];
            yellowHeight[j] = bytePtr[i++]*256;
            yellowHeight[j] += bytePtr[i++];
            yellowNumLetters[j] = bytePtr[i++];
             for (int k=0;k<yellowNumLetters[j];k++)
            {
                yellowPos[j][k].v = bytePtr[i++];
                yellowPos[j][k].h = bytePtr[i++];
            }
        }
    }
    
    currentSelection.h = -1;
    currentSelection.v = -1;
    selectedWord[0].h = -1;
    selectedWord[0].v = -1;
    
    permanentMarker = TRUE;

    numFilledIn = 0;
    [self clearWrongAndRightFlags];
    
    [self markAllToRefresh];
}

/*
 Stored character data is 16 bits Unicode, except that bit 14 is set
 when a character should be drawn in ink. This information is
 extracted and stored in a separate BOOL array.
 */
-(void)setUserDataFromData:(NSData*)fileData
{
    unsigned char *bytePtr = (unsigned char *)[fileData bytes];
    int i = 0;
    // Filled-in characters
    numFilledIn = 0;
    int c;
    for (int j=0;j<numVertical;j++)
        for (int k=0;k<numHorizontal;k++)
        {
            c = bytePtr[i++]*256;
            c += bytePtr[i++];
            characters[j][k] = c;
            if (c > 0)
                numFilledIn++;
        }
    clockActive = (BOOL)bytePtr[i++];
    clockSeconds = (((((bytePtr[i]<<8) + bytePtr[i+1])<<8) + bytePtr[i+2])<<8) + bytePtr[i+3];
}

-(BOOL)isEqualToUserData:(NSData*)updateData
{
    unsigned char *bytePtr = (unsigned char *)[updateData bytes];
    if ([updateData length] == 0)
        return FALSE;
    BOOL equal = TRUE;
    int i = 0;
    int c;
    for (int j=0;j<numVertical;j++)
        for (int k=0;k<numHorizontal;k++)
        {
            c = bytePtr[i++]*256;
            c += bytePtr[i++];
            equal &= (c == characters[j][k]);
        }
    return equal;
}


-(BOOL)hasSelection
{
    return (currentSelection.h >= 0);
}

-(BOOL)hasSelectedWord
{
    return (selectedWord[0].h >= 0);
}

-(int)getHorizontalSize
{
    return numHorizontal;
}

-(int)getVerticalSize
{
    return numVertical;
}

// Find which box position a set of screen coordinates points to
-(GridPos)getSelectionFromX:(float)xPos andY:(float)yPos
{
    float scaledX = xPos / scaleFactor;
    float scaledY = yPos / scaleFactor;
    GridPos sel;
    sel.h = -1;
    sel.v = -1;
    if (scaledX >= 0 && scaledX < x + width && yPos >= 0 && yPos < y + height)
    {
        int h = (int)(numHorizontal * scaledX/width);
        int v = (int)(numVertical * scaledY/height);
        if (scaledX >= boxX[v][h] && scaledX < boxX[v][h]+boxWidth[v][h] && scaledY >= boxY[v][h] && scaledY < boxY[v][h]+boxHeight[v][h])
        {
            sel.h = h;
            sel.v = v;
        }
    }
    return sel;
}

-(int)getCharacterAtH:(int)hPos andV:(int)vPos
{
    return characters[vPos][hPos];
}

-(int)getSolutionAtH:(int)hPos andV:(int)vPos
{
    return solution[vPos][hPos];
}

-(void)setCharacter:(int)ch AtH:(int)hPos andV:(int)vPos
{
    characters[vPos][hPos] = ch;
}
    
-(void)selectBoxAtH:(int)hPos andV:(int)vPos
{
    [[SoundManager sharedInstance] playSound:SELECTION_SOUND];
        
    int wordPos = -1;
    // See if selection is inside current word
    for (int i=0;selectedWord[i].h>=0;i++)
        if (selectedWord[i].h == hPos && selectedWord[i].v == vPos)
            wordPos = i;
    
    if (wordPos < 0) // New word selected
    {
        // Maybe do something here later
    }
    
    if (currentSelection.h == hPos && currentSelection.v == vPos) // Same as current?
        selectHorizontally = !selectHorizontally;
    else if (wordPos >= 0) // Inside already selected word? Just move cursor
    {
        currentSelection = selectedWord[wordPos];
        refreshRect = oldSelectionRect;
        return;
    }
    else // Standard case. Figure out selection direction
    {
        currentSelection.h = hPos;
        currentSelection.v = vPos;
        // Determine which word has the closest beginning
        int hDist = [self squaresFromStartAtH:hPos andV:vPos horizontally:TRUE];
        int vDist = [self squaresFromStartAtH:hPos andV:vPos horizontally:FALSE];
        selectHorizontally = (hDist <= vDist);
        
        // Avoid unnecessary single-box selection here
        if (selectHorizontally && hDist==1 && (barriers[vPos][hPos] & RIGHT_BARRIER) &&
            !(clueDirections[vPos][hPos]&3))
            selectHorizontally = FALSE;
        else if (!selectHorizontally && vDist==1 && (barriers[vPos][hPos] & BOTTOM_BARRIER) &&
                 !(clueDirections[vPos][hPos]&3))
            selectHorizontally = TRUE;
    }
    
    // Find initial box
    BOOL keepGoing = TRUE;
    BOOL horizontalDir = selectHorizontally;
    
    while (keepGoing)
    {
        if (horizontalDir)
        {
            if (!(barriers[vPos][hPos] & LEFT_BARRIER))
            {
                hPos--;
            }
            else
            {
                if ((boxTurn[vPos][hPos] & TURN_RIGHT) && !(barriers[vPos][hPos] & TOP_BARRIER))
                {
                    horizontalDir = FALSE;
                    vPos--;
                }
                else
                    keepGoing = FALSE;
            }
        }
        else
        {
            if (!(barriers[vPos][hPos] & TOP_BARRIER))
            {
                vPos--;
            }
            else
            {
                if ((boxTurn[vPos][hPos] & TURN_DOWN) && !(barriers[vPos][hPos] & LEFT_BARRIER))
                {
                    horizontalDir = TRUE;
                    hPos--;
                }
                else
                    keepGoing = FALSE;
            }
        }
    }
    
    // Traverse entire word and store character positions
    keepGoing = TRUE;
    int i = 0;
    while (keepGoing)
    {
        selectedWord[i].h = hPos;
        selectedWord[i++].v = vPos;
        if (horizontalDir)
        {
            if ((barriers[vPos][hPos] & RIGHT_BARRIER) && boxTurn[vPos][hPos] != TURN_DOWN)
                keepGoing = FALSE;
            else
            {
                if (boxTurn[vPos][hPos] == TURN_DOWN && (barriers[vPos][hPos] & RIGHT_BARRIER))
                {
                    horizontalDir = FALSE;
                    vPos++;
                }
                else
                {
                    hPos++;
                }
            }
        }
        else
        {
            if ((barriers[vPos][hPos] & BOTTOM_BARRIER) && boxTurn[vPos][hPos] != TURN_RIGHT)
                keepGoing = FALSE;
            else
            {
                if (boxTurn[vPos][hPos] == TURN_RIGHT && (barriers[vPos][hPos] & BOTTOM_BARRIER))
                {
                    horizontalDir = TRUE;
                    hPos++;
                }
                else
                {
                    vPos++;
                }
            }
        }
    }
    selectedWord[i].h = -1;
    selectedWord[i].v = -1;
    
    [self updateRefreshRectangle];
}

-(BOOL)selectedClueAtX:(float)xPos andY:(float)yPos
{
    float scaledX = xPos / scaleFactor;
    float scaledY = yPos / scaleFactor;
    
    int foundList[10];
    int foundCount = 0;
    for (int i=0;i<numClues && foundCount < 10;i++)
    {
        if (scaledX > clueX[i] && scaledX < clueX[i]+clueWidth[i] && scaledY > clueY[i] && scaledY < clueY[i]+clueHeight[i])
        {
            foundList[foundCount++] = i;
        }
    }
    
    if (foundCount > 0)
    {
        int i = toggleCounter % foundCount; // In case of multiple overlapping clues
        toggleCounter++;
        
        int hPos = clueWordH[foundList[i]];
        int vPos = clueWordV[foundList[i]];
        currentSelection.h = hPos;
        currentSelection.v = vPos;
        BOOL horizontalDir = clueHorizontal[foundList[i]];
        BOOL keepGoing = TRUE;
        
        i = 0;
        while (keepGoing)
        {
            selectedWord[i].h = hPos;
            selectedWord[i++].v = vPos;
            if (horizontalDir)
            {
                if ((barriers[vPos][hPos] & RIGHT_BARRIER) && boxTurn[vPos][hPos] != TURN_DOWN)
                    keepGoing = FALSE;
                else
                {
                    if (boxTurn[vPos][hPos] == TURN_DOWN && (barriers[vPos][hPos] & RIGHT_BARRIER))
                    {
                        horizontalDir = FALSE;
                        vPos++;
                    }
                    else
                    {
                        hPos++;
                    }
                }
            }
            else
            {
                if ((barriers[vPos][hPos] & BOTTOM_BARRIER) && boxTurn[vPos][hPos] != TURN_RIGHT)
                    keepGoing = FALSE;
                else
                {
                    if (boxTurn[vPos][hPos] == TURN_RIGHT && (barriers[vPos][hPos] & BOTTOM_BARRIER))
                    {
                        horizontalDir = TRUE;
                        hPos++;
                    }
                    else
                    {
                        vPos++;
                    }
                }
            }
        }
        selectedWord[i].h = -1;
        selectedWord[i].v = -1;
        
        [self updateRefreshRectangle];
        
        return TRUE;
    }
    
    // Now check for yellow clue boxes
    for (int i=0;i<numYellow && foundCount < 10;i++)
    {
        if (scaledX > yellowX[i] && scaledX < yellowX[i]+yellowWidth[i] && scaledY > yellowY[i] && scaledY < yellowY[i]+yellowHeight[i])
        {
            foundList[foundCount++] = i;
        }
    }
    if (foundCount > 0)
    {
        int i = foundList[toggleCounter % foundCount]; // In case of multiple overlapping clues
        toggleCounter++;
        int n = yellowNumLetters[i];
        int m;
        currentSelection = yellowPos[i][0];
        for (m=0;m<n;m++)
        {
            selectedWord[m] = yellowPos[i][m];
            // Temporarily stop when there is a discontinuity
//            if (m < n-1 && (selectedWord[m].h != yellowPos[i][m+1].h && selectedWord[m].v != yellowPos[i][m+1].v))
//                break;
        }
        selectedWord[m].h = -1;
        selectedWord[m].v = -1;
        
        [self updateRefreshRectangle];
        
        return TRUE;
    }
    else
        return FALSE;
}

// Measure how far from the initial box the user has selected
// (used for determining which selection direction is more relevant)
-(int)squaresFromStartAtH:(int)hPos andV:(int)vPos horizontally:(BOOL)hz
{
    int counter = 0;
    BOOL horizontalDir = hz;
    BOOL keepGoing = TRUE;
    while (keepGoing)
    {
        counter++;
        if (horizontalDir)
        {
            if ((barriers[vPos][hPos] & LEFT_BARRIER) && boxTurn[vPos][hPos] != TURN_RIGHT)
                keepGoing = FALSE;
            else
            {
                if (boxTurn[vPos][hPos] == TURN_RIGHT && (barriers[vPos][hPos] & LEFT_BARRIER))
                {
                    horizontalDir = FALSE;
                    vPos--;
                }
                else
                {
                    hPos--;
                }
            }
        }
        else
        {
            if ((barriers[vPos][hPos] & TOP_BARRIER) && boxTurn[vPos][hPos] != TURN_DOWN)
                keepGoing = FALSE;
            else
            {
                if (boxTurn[vPos][hPos] == TURN_DOWN && (barriers[vPos][hPos] & TOP_BARRIER))
                {
                    horizontalDir = TRUE;
                    hPos--;
                }
                else
                {
                    vPos--;
                }
            }
        }
    }
    return counter;
}

-(GridPos)getCurrentSelection
{
    return currentSelection;
}

-(BOOL)correctSolutionAtH:(int)hPos andV:(int)vPos
{
    if (hasSolution)
        return (characters[vPos][hPos] & CHAR_BITS) == solution[vPos][hPos];
    else
        return TRUE;
}

-(BOOL)solutionExists
{
    return hasSolution;
}

-(BOOL)hasNumberCompetition
{
    return numberBoxes > 0;
}

/*
// Computer the coordinates for a path that tightly encloses the selected word
// and store them in the supplied array
-(int)getSelectionPath:(CGPoint[])pathHolder
{
    // Compute selected path
    int i = 0;
    int hPos,vPos;
    int hLast,vLast;
    hPos = selectedWord[0].h;
    vPos = selectedWord[0].v;
    float xPos,yPos;
    float lastX,lastY;
    selectedPath[i].x = boxX[vPos][hPos];
    selectedPath[i++].y = boxY[vPos][hPos];
    
    xPos = boxX[vPos][hPos] + boxWidth[vPos][hPos];
    yPos  = boxY[vPos][hPos];
    selectedPath[i].x = xPos;
    selectedPath[i++].y = yPos;
    lastX = xPos;
    lastY = yPos;
    int j = 1;
    vLast = vPos;
    hLast = hPos;
    // First sweep
    while (selectedWord[j].h >= 0)
    {
        hPos = selectedWord[j].h;
        vPos = selectedWord[j].v;
        xPos = boxX[vPos][hPos] + boxWidth[vPos][hPos];
        yPos  = boxY[vPos][hPos];
        if (vPos == vLast) // Moving horizontally
        {
            if (yPos < lastY - 1.0 || yPos > lastY + 1.0) // Height adjustment
            {
                selectedPath[i].x = lastX;
                selectedPath[i++].y = yPos;
            }
        }
        else // Moving vertically
        {
            if (xPos < lastX - 1.0 || xPos > lastX + 1.0) // Width adjustment
            {
                selectedPath[i].x = lastX;
                selectedPath[i++].y = yPos;
            }
        }
        selectedPath[i].x = xPos;
        selectedPath[i++].y = yPos;
        hLast = hPos;
        vLast = vPos;
        lastX = xPos;
        lastY = yPos;
        j++;
    }
    
    yPos = boxY[vPos][hPos] + boxHeight[vPos][hPos];
    selectedPath[i].x = xPos;
    selectedPath[i++].y = yPos;
    xPos = boxX[vPos][hPos];
    selectedPath[i].x = xPos;
    selectedPath[i++].y = yPos;
    lastX = xPos;
    lastY = yPos;
    j-=2;
    // Second sweep
    while (j>=0)
    {
        hPos = selectedWord[j].h;
        vPos = selectedWord[j].v;
        xPos = boxX[vPos][hPos];
        yPos  = boxY[vPos][hPos] + boxHeight[vPos][hPos];
        if (vPos == vLast) // Moving horizontally
        {
            if (yPos < lastY - 1.0 || yPos > lastY + 1.0) // Height adjustment
            {
                selectedPath[i].x = lastX;
                selectedPath[i++].y = yPos;
            }
        }
        else // Moving vertically
        {
            if (xPos < lastX - 1.0 || xPos > lastX + 1.0) // Width adjustment
            {
                selectedPath[i].x = lastX;
                selectedPath[i++].y = yPos;
            }
        }        
        
        selectedPath[i].x = xPos;
        selectedPath[i++].y = yPos;
        hLast = hPos;
        vLast = vPos;
        lastX = xPos;
        lastY = yPos;
        j--;
    }
    
    selectedPath[i].x = -1;
    selectedPath[i].y = -1;
    
    i = 0;
    while (selectedPath[i].x > 0)
    {
        pathHolder[i] = CGPointMake(selectedPath[i].x * scaleFactor, selectedPath[i].y * scaleFactor);
        i++;
    }
    pathHolder[i] = selectedPath[i];
    
    return 1; // Return number of separate segments
}
*/

// Computer the coordinates for a group of paths that tightly encloses the selected word
// groups and store them in the supplied array
-(int)getMultipleSelectionPath:(CGPoint[])pathHolder
{
    // Compute selected path
    int numSegments = 0;
    int k=0;
    int endBox;
    int i = 0;
    int hPos,vPos;
    int hLast,vLast;
    float xPos,yPos;
    float lastX,lastY;
    while (selectedWord[k].h >= 0)
    {
        hPos = selectedWord[k].h;
        vPos = selectedWord[k].v;
        selectedPath[i].x = boxX[vPos][hPos];
        selectedPath[i++].y = boxY[vPos][hPos];
        
        xPos = boxX[vPos][hPos] + boxWidth[vPos][hPos];
        yPos  = boxY[vPos][hPos];
        selectedPath[i].x = xPos;
        selectedPath[i++].y = yPos;
        lastX = xPos;
        lastY = yPos;
        int j = k+1;
        vLast = vPos;
        hLast = hPos;
        // First sweep
        while (selectedWord[j].h >= 0 &&
               ((selectedWord[j].h == selectedWord[j-1].h+1 &&
                 selectedWord[j].v == selectedWord[j-1].v) ||
                (selectedWord[j].v == selectedWord[j-1].v+1 &&
                 selectedWord[j].h == selectedWord[j-1].h)))
        {
            hPos = selectedWord[j].h;
            vPos = selectedWord[j].v;
            xPos = boxX[vPos][hPos] + boxWidth[vPos][hPos];
            yPos  = boxY[vPos][hPos];
            if (vPos == vLast) // Moving horizontally
            {
                if (yPos < lastY - 1.0 || yPos > lastY + 1.0) // Height adjustment
                {
                    selectedPath[i].x = lastX;
                    selectedPath[i++].y = yPos;
                }
            }
            else // Moving vertically
            {
                if (xPos < lastX - 1.0 || xPos > lastX + 1.0) // Width adjustment
                {
                    selectedPath[i].x = lastX;
                    selectedPath[i++].y = yPos;
                }
            }
            selectedPath[i].x = xPos;
            selectedPath[i++].y = yPos;
            hLast = hPos;
            vLast = vPos;
            lastX = xPos;
            lastY = yPos;
            j++;
        }
        endBox = j;
        
        yPos = boxY[vPos][hPos] + boxHeight[vPos][hPos];
        selectedPath[i].x = xPos;
        selectedPath[i++].y = yPos;
        xPos = boxX[vPos][hPos];
        selectedPath[i].x = xPos;
        selectedPath[i++].y = yPos;
        lastX = xPos;
        lastY = yPos;
        j-=2;
        // Second sweep
        while (j>=k)
        {
            hPos = selectedWord[j].h;
            vPos = selectedWord[j].v;
            xPos = boxX[vPos][hPos];
            yPos  = boxY[vPos][hPos] + boxHeight[vPos][hPos];
            if (vPos == vLast) // Moving horizontally
            {
                if (yPos < lastY - 1.0 || yPos > lastY + 1.0) // Height adjustment
                {
                    selectedPath[i].x = lastX;
                    selectedPath[i++].y = yPos;
                }
            }
            else // Moving vertically
            {
                if (xPos < lastX - 1.0 || xPos > lastX + 1.0) // Width adjustment
                {
                    selectedPath[i].x = lastX;
                    selectedPath[i++].y = yPos;
                }
            }
            
            selectedPath[i].x = xPos;
            selectedPath[i++].y = yPos;
            hLast = hPos;
            vLast = vPos;
            lastX = xPos;
            lastY = yPos;
            j--;
        }
        
        selectedPath[i].x = -1;
        selectedPath[i].y = -1;
        k = endBox;
        i++;
        numSegments++;
   }
    
    // Scale it
    for (int j=0;j<i;j++)
        pathHolder[j] = CGPointMake(selectedPath[j].x * scaleFactor, selectedPath[j].y * scaleFactor);

    return numSegments;
}

-(CGRect)getSelectedBoxCoordinates
{
    if (currentSelection.h >= 0)
        return [self getBoxCoordinatesAtH:currentSelection.h andV:currentSelection.v];
    else
        return CGRectNull;
}

-(CGRect)getBoxCoordinatesAtH:(int)hPos andV:(int)vPos
{
    return CGRectMake(boxX[vPos][hPos] * scaleFactor, boxY[vPos][hPos] * scaleFactor, boxWidth[vPos][hPos] * scaleFactor, boxHeight[vPos][hPos] * scaleFactor);
}

// Find a rectangle (approximate) that encloses the whole selected word
// and also includes the clue boxes to the left and above, plus some margin below and to the right
-(CGRect)getWordBoundingBox
{
    int hPos = selectedWord[0].h;
    int vPos = selectedWord[0].v;
    float x0 = boxX[vPos][hPos];
    float y0 = boxY[vPos][hPos];
    int i=0;
    while (selectedWord[i+1].h > 0)
        i++;
    hPos = selectedWord[i].h;
    vPos = selectedWord[i].v;
    float x1 = boxX[vPos][hPos]+boxWidth[vPos][hPos];
    float y1 = boxY[vPos][hPos]+boxHeight[vPos][hPos];
    
    // Include clue boxes
    x0 -= width/numHorizontal;
    y0 -= height/numVertical;
    // Add some margin
    x1 += 0.25*width/numHorizontal;
    y1 += 0.25*height/numVertical;
    
    return CGRectMake(x0 * scaleFactor, y0 * scaleFactor, (x1-x0) * scaleFactor, (y1-y0) * scaleFactor);
}

-(void)typeCharacter:(int)ch
{
    if (currentSelection.h >= 0)
    {
        GridPos oldSelection = currentSelection;
        // Go through words and find selected position
        int i=0;
        while (selectedWord[i].h != currentSelection.h || selectedWord[i].v != currentSelection.v)
            i++;
        
//        if (permanentMarker)
        if (TRUE) // Skip pencil behavior for now, always overwrite
        {
            // Always write on top of everything
            [[SoundManager sharedInstance] playSound:CLICK_SOUND];
            if (characters[currentSelection.v][currentSelection.h] == 0)
                numFilledIn++;
            else
            {
                if (characters[currentSelection.v][currentSelection.h] != ch)
                    [[SoundManager sharedInstance] playSound:OVERWRITE_SOUND];
            }

            characters[currentSelection.v][currentSelection.h] = ch;
            markedWrong[currentSelection.v][currentSelection.h] = FALSE; // Remove possible wrong marking
            drawnWithMarker[currentSelection.v][currentSelection.h] = permanentMarker;
            if (selectedWord[i+1].h >= 0) // Can move cursor
            {
                currentSelection = selectedWord[i+1];
            }
//            else // Come to end of word, remove cursor
//            {
//                currentSelection.h = -1;
//                currentSelection.v = -1;
//            }
        }
        else // Pencil
        {
            if (characters[currentSelection.v][currentSelection.h] > 0 && drawnWithMarker[currentSelection.v][currentSelection.h]) // Don't overwrite pen
            {
                [[SoundManager sharedInstance] playSound:STOP_SOUND];
            }
            else // Normal case
            {
                if (characters[currentSelection.v][currentSelection.h] == 0)
                    numFilledIn++;
                else
                    [[SoundManager sharedInstance] playSound:OVERWRITE_SOUND];
                characters[currentSelection.v][currentSelection.h] = ch;
                markedWrong[currentSelection.v][currentSelection.h] = FALSE; // Remove possible wrong marking
                drawnWithMarker[currentSelection.v][currentSelection.h] = FALSE;

                if (selectedWord[i+1].h >= 0)
                    currentSelection = selectedWord[i+1];
                BOOL didJump = FALSE;
                i++;
                while (currentSelection.h >= 0 && characters[currentSelection.v][currentSelection.h] > 0 && drawnWithMarker[currentSelection.v][currentSelection.h] &&
                       selectedWord[i+1].h >= 0) // Skip marker characters
                {
                    currentSelection = selectedWord[i+1];
                    i++;
                    didJump = TRUE;
                }
                if (didJump)
                {
                    if (currentSelection.h >= 0)
                        [[SoundManager sharedInstance] playSound:JUMP_CLICK_SOUND];
                    else
                        [[SoundManager sharedInstance] playSound:STOP_SOUND];
                }
                else
                    [[SoundManager sharedInstance] playSound:CLICK_SOUND];
            }
        }
/*        [[SoundManager sharedInstance] playSound:CLICK_SOUND];
        // Keep count of filled in
        if (characters[currentSelection.v][currentSelection.h] == 0)
            numFilledIn++;
        
        int i=0;
        while (selectedWord[i].h != currentSelection.h || selectedWord[i].v != currentSelection.v)
            i++;
        characters[currentSelection.v][currentSelection.h] = ch;
        markedWrong[currentSelection.v][currentSelection.h] = FALSE; // Remove possible wrong marking
        drawnWithMarker[currentSelection.v][currentSelection.h] = permanentMarker;
        if (selectedWord[i+1].h >= 0) // Can move cursor
        {
            currentSelection = selectedWord[i+1];
            BOOL didJump = FALSE;
            if (!overwriteCharacters) // Skip over already filled in characters
            {
                i++;
                
                while (characters[currentSelection.v][currentSelection.h] > 0 && selectedWord[i+1].h >= 0 && // Don't skip if it is drawn in pencil and we are currently using a marker
                       !(permanentMarker && !drawnWithMarker[currentSelection.v][currentSelection.h]))
                {
                    currentSelection = selectedWord[i+1];
                    i++;
                    didJump = TRUE;
                }
            }
            if (didJump)
                [[SoundManager sharedInstance] playSound:JUMP_SOUND];
        }
        else // Come to end of word, remove cursor
        {
            currentSelection.h = -1;
            currentSelection.v = -1;
        }*/
        
        [self updateRefreshRectangleForTypingFromPos:oldSelection toPos:currentSelection];
    }
    else
        [[SoundManager sharedInstance] playSound:STOP_SOUND];
    
}

-(void)typeBackspace
{
    if (currentSelection.h >= 0)
    {
        GridPos oldSelection = currentSelection;
        BOOL madeDeletion = FALSE;
        
        // Keep count of filled in
        if (characters[currentSelection.v][currentSelection.h] > 0)
        {
            numFilledIn--;
            madeDeletion = TRUE;
        }
        
        int i=0;
        while (selectedWord[i].h != currentSelection.h || selectedWord[i].v != currentSelection.v)
            i++;
        characters[currentSelection.v][currentSelection.h] = 0;
        markedWrong[currentSelection.v][currentSelection.h] = FALSE; // Remove possible wrong marking
        
        if (i>0)
        {
            currentSelection = selectedWord[i-1];
            madeDeletion = TRUE;
        }
        if (madeDeletion)
            [[SoundManager sharedInstance] playSound:DELETE_SOUND];
        else
            [[SoundManager sharedInstance] playSound:STOP_SOUND];
        [self updateRefreshRectangleForTypingFromPos:oldSelection toPos:currentSelection];
    }
    else
        [[SoundManager sharedInstance] playSound:STOP_SOUND];
    
}

-(BOOL)isWordCompleteAtH:(int)hPos andV:(int)vPos horizontally:(BOOL)hz
{
    // No crossing word? Return FALSE
    if (hz && (barriers[vPos][hPos] & LEFT_BARRIER) && (barriers[vPos][hPos] & RIGHT_BARRIER))
        return FALSE;
    else if (!hz && (barriers[vPos][hPos] & TOP_BARRIER) && (barriers[vPos][hPos] & BOTTOM_BARRIER))
        return FALSE;
    
    BOOL completeWord = TRUE;
    // Track backwards
    BOOL horizontalDir = hz;
    BOOL keepGoing = TRUE;
    int v = vPos;
    int h = hPos;
    while (keepGoing)
    {
        completeWord &= (characters[v][h] > 0);
        if (horizontalDir)
        {
            if ((barriers[v][h] & LEFT_BARRIER) && boxTurn[v][h] != TURN_RIGHT)
                keepGoing = FALSE;
            else
            {
                if (boxTurn[v][h] == TURN_RIGHT && (barriers[vPos][hPos] & LEFT_BARRIER))
                {
                    horizontalDir = FALSE;
                    v--;
                }
                else
                {
                    h--;
                }
            }
        }
        else
        {
            if ((barriers[v][h] & TOP_BARRIER) && boxTurn[v][h] != TURN_DOWN)
                keepGoing = FALSE;
            else
            {
                if (boxTurn[v][h] == TURN_DOWN && (barriers[vPos][hPos] & TOP_BARRIER))
                {
                    horizontalDir = TRUE;
                    h--;
                }
                else
                {
                    v--;
                }
            }
        }
    }
    // Track forward
    horizontalDir = hz;
    keepGoing = TRUE;
    v = vPos;
    h = hPos;
    while (keepGoing)
    {
        completeWord &= (characters[v][h] > 0);
        if (horizontalDir)
        {
            if ((barriers[v][h] & RIGHT_BARRIER) && boxTurn[v][h] != TURN_DOWN)
                keepGoing = FALSE;
            else
            {
                if (boxTurn[v][h] == TURN_DOWN)
                {
                    horizontalDir = FALSE;
                    v++;
                }
                else
                {
                    h++;
                }
            }
        }
        else
        {
            if ((barriers[v][h] & BOTTOM_BARRIER) && boxTurn[v][h] != TURN_RIGHT)
                keepGoing = FALSE;
            else
            {
                if (boxTurn[v][h] == TURN_RIGHT)
                {
                    horizontalDir = TRUE;
                    h++;
                }
                else
                {
                    v++;
                }
            }
        }
    }
    return completeWord;
}

// Store the filled-in characters locally
-(void)saveFilledInCharactersAs:(NSString*)fileName
{
    int totalLength = numVertical*numHorizontal*2+1+4;
    Byte tempBytes[totalLength];
    int k=0;
    for (int i=0;i<numVertical;i++)
        for (int j=0;j<numHorizontal;j++)
        {
            tempBytes[k++] = (characters[i][j] >> 8) & 0xff;
            tempBytes[k++] = characters[i][j] & 0xff;
        }

    tempBytes[k++] = (Byte)clockActive;
    tempBytes[k++] = (clockSeconds >> 24) & 0xff;
    tempBytes[k++] = (clockSeconds >> 16) & 0xff;
    tempBytes[k++] = (clockSeconds >> 8) & 0xff;
    tempBytes[k++] = clockSeconds & 0xff;
        
    [[DownloadManager sharedDownloadManager] saveUserData:[NSData dataWithBytes:tempBytes length:totalLength] forCrossword:fileName];
    
/*    NSData *tempD = [NSData dataWithBytes:tempBytes length:totalLength];
    NSString *applicationDocumentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *storePath = [applicationDocumentsDir stringByAppendingPathComponent:fileName];
    NSError* error = nil;
    [tempD writeToFile:storePath atomically:TRUE];
    if (error != nil)
        NSLog(@"File save error %@",error);*/
}

-(NSString*)getFilledInCharactersAsBase64String
{
    int length = numVertical*numHorizontal*2+1+4;
    uint8_t input[length];
    int k=0;
    for (int i=0;i<numVertical;i++)
        for (int j=0;j<numHorizontal;j++)
        {
            input[k++] = (characters[i][j] >> 8) & 0xff;
            input[k++] = characters[i][j] & 0xff;
        }
    input[k++] = (uint8_t)clockActive;
    input[k++] = (clockSeconds >> 24) & 0xff;
    input[k++] = (clockSeconds >> 16) & 0xff;
    input[k++] = (clockSeconds >> 8) & 0xff;
    input[k++] = clockSeconds & 0xff;
    
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    
    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)data.mutableBytes;
    
    NSInteger i;
    for (i=0; i < length; i += 3) {
        NSInteger value = 0;
        NSInteger j;
        for (j = i; j < (i + 3); j++) {
            value <<= 8;
            
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        NSInteger theIndex = (i / 3) * 4;
        output[theIndex + 0] =                    table[(value >> 18) & 0x3F];
        output[theIndex + 1] =                    table[(value >> 12) & 0x3F];
        output[theIndex + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[theIndex + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
}

-(void)clearWrongAndRightFlags
{
    for (int i=0;i<numVertical;i++)
        for (int j=0;j<numHorizontal;j++)
        {
            markedRight[i][j] = FALSE;
            markedWrong[i][j] = FALSE;
        }
    showRightAndWrong = FALSE;
}

-(BOOL)shouldShowRightAndWrong
{
    return showRightAndWrong;
}

-(void)finishedShowingRightAndWrong
{
    showRightAndWrong = FALSE;
}

-(BOOL)findWrongCharactersInWord
{
    [self clearWrongAndRightFlags];
    BOOL hasMistakes = FALSE;
    BOOL anythingFilledIn = FALSE;
    if (selectedWord[0].h >= 0)
    {
        int i=0;
        while (selectedWord[i].h >= 0)
        {
            int h = selectedWord[i].h;
            int v = selectedWord[i].v;

            if (characters[v][h] > 0)
                anythingFilledIn = TRUE;
            
            if (solution[v][h] > 0 && characters[v][h] > 0)
            {
                if (solution[v][h] == characters[v][h])
                    markedRight[v][h] = TRUE;
                else
                {
                    markedWrong[v][h] = TRUE;
                    hasMistakes = TRUE;
                }
            }
            i++;
        }
    }
    showRightAndWrong = TRUE;
    [self updateRefreshRectangle];
    
    if (hasMistakes)
        [[SoundManager sharedInstance] playSound:WRONG_SOUND];
    else if (anythingFilledIn)
        [[SoundManager sharedInstance] playSound:CORRECT_WORD_SOUND];
    else
        [[SoundManager sharedInstance] playSound:STOP_SOUND];
    return anythingFilledIn && !hasMistakes;
}

-(BOOL)correctCharactersInWord
{
    [self clearWrongAndRightFlags];
    BOOL hasMistakes = FALSE;
    BOOL hasMissing = FALSE;
    if (selectedWord[0].h >= 0)
    {
        int i=0;
        while (selectedWord[i].h >= 0)
        {
            
            int h = selectedWord[i].h;
            int v = selectedWord[i].v;
            markedWrong[v][h] = FALSE;
            
            if (solution[v][h] > 0) 
            {
                if (characters[v][h] == 0)
                {
                    numFilledIn++;
                    hasMissing = TRUE;
                }
                if (solution[v][h] != characters[v][h])
                {
                    if (characters[v][h] > 0)
                        hasMistakes = TRUE;
                }
                else
                    markedRight[v][h] = TRUE;
                characters[v][h] = solution[v][h];
                drawnWithMarker[v][h] = TRUE;
            }
            i++;
        }
    }
    showRightAndWrong = TRUE;
    [self updateRefreshRectangle];
    
    if (hasMistakes)
        [[SoundManager sharedInstance] playSound:WRONG_SOUND];
    else if (!hasMissing)
        [[SoundManager sharedInstance] playSound:CORRECT_WORD_SOUND];
    return !hasMistakes;
}


-(BOOL)isWrongAtH:(int)hPos andV:(int)vPos
{
    return markedWrong[vPos][hPos];
}

-(BOOL)isRightAtH:(int)hPos andV:(int)vPos
{
    return markedRight[vPos][hPos];
}

-(BOOL)setCorrectCharacterAtSelection
{
    [self clearWrongAndRightFlags];
    BOOL correct = FALSE;
    int h = -1;
    int v = -1;
    if (currentSelection.h >= 0)
    {
        h = currentSelection.h;
        v = currentSelection.v;
    }
    else if (selectedWord[0].h >= 0 && selectedWord[1].h < 0)
    {
        h = selectedWord[0].h;
        v = selectedWord[0].v;
    }
    if (h >= 0)
    {
        if (solution[v][h] > 0)
        {
            if (characters[v][h] == 0)
                numFilledIn++;
            if (characters[v][h] != solution[v][h])
                [[SoundManager sharedInstance] playSound:WRONG_SOUND];
            else
            {
                [[SoundManager sharedInstance] playSound:CORRECT_LETTER_SOUND];
                markedRight[v][h] = TRUE;
                correct = TRUE;
            }
            characters[v][h] = solution[v][h];
            drawnWithMarker[v][h] = TRUE;
            markedWrong[v][h] = FALSE;
        }
    }
    else
        [[SoundManager sharedInstance] playSound:STOP_SOUND];
    showRightAndWrong = TRUE;
    return correct;
}

-(BOOL)helpWithCharacterAtSelection
{
    [self clearWrongAndRightFlags];
    BOOL correct = FALSE;
    int h = -1;
    int v = -1;
    if (currentSelection.h >= 0)
    {
        h = currentSelection.h;
        v = currentSelection.v;
    }
    else if (selectedWord[0].h >= 0 && selectedWord[1].h < 0)
    {
        h = selectedWord[0].h;
        v = selectedWord[0].v;
    }
    if (h >= 0)
    {
        if (solution[v][h] > 0 && characters[v][h] > 0)
        {
            if (characters[v][h] != solution[v][h])
            {
                markedWrong[v][h] = TRUE;
                [[SoundManager sharedInstance] playSound:WRONG_SOUND];
            }
            else
            {
                markedRight[v][h] = TRUE;
                [[SoundManager sharedInstance] playSound:CORRECT_LETTER_SOUND];
                correct = TRUE;
            }
        }
        else
           [[SoundManager sharedInstance] playSound:STOP_SOUND];
    }
    else
        [[SoundManager sharedInstance] playSound:STOP_SOUND];
    showRightAndWrong = TRUE;
    return correct;
}


-(void)markAllWrongCharacters
{
    [self clearWrongAndRightFlags];
    BOOL anythingFilledIn = FALSE;
    for (int i=0;i<numVertical;i++)
        for (int j=0;j<numHorizontal;j++)
            if (characters[i][j] > 0)
                anythingFilledIn = TRUE;
    BOOL blankSpaces = FALSE;
    if (anythingFilledIn)
    {
        BOOL hasMistakes = FALSE;
        for (int i=0;i<numVertical;i++)
            for (int j=0;j<numHorizontal;j++)
                if (solution[i][j] > 0 && characters[i][j] > 0)
                {
                    if (characters[i][j] == solution[i][j])
                        markedRight[i][j] = TRUE;
                    else
                    {
                        markedWrong[i][j] = TRUE;
                        hasMistakes = TRUE;
                    }
                }
                else if (solution[i][j] > 0)
                    blankSpaces = TRUE;
        if (hasMistakes)
            [[SoundManager sharedInstance] playSound:WRONG_SOUND];
        else if (blankSpaces)
            [[SoundManager sharedInstance] playSound:CORRECT_WORD_SOUND];
        else // Everything filled in and correct
            [[SoundManager sharedInstance] playSound:CORRECT_ALL_SOUND];
    }
    else
        [[SoundManager sharedInstance] playSound:STOP_SOUND];
    showRightAndWrong = TRUE;
    [self markAllToRefresh];
}

-(void)correctAllWrongCharacters
{
    [self clearWrongAndRightFlags];
    for (int i=0;i<numVertical;i++)
        for (int j=0;j<numHorizontal;j++)
            if (solution[i][j] > 0)
            {
                if (characters[i][j] == 0)
                    numFilledIn++;
                markedWrong[i][j] = FALSE;
                if (characters[i][j] == solution[i][j])
                    markedRight[i][j] = TRUE;
                characters[i][j] = solution[i][j];
                drawnWithMarker[i][j] = TRUE;
            }
    showRightAndWrong = TRUE;
    [self markAllToRefresh];
}

-(void)checkIfAllIsCorrect
{
    [self clearWrongAndRightFlags];
    BOOL allCorrect = TRUE;
    for (int i=0;i<numVertical;i++)
        for (int j=0;j<numHorizontal;j++)
            if (solution[i][j] > 0)
            {
                if (characters[i][j] != solution[i][j])
                    allCorrect = FALSE;
                else
                    markedRight[i][j] = TRUE;
            }
    if (allCorrect)
        [[SoundManager sharedInstance] playSound:CORRECT_ALL_SOUND];
    else
        [[SoundManager sharedInstance] playSound:WRONG_SOUND];
}

-(void)clearAllCharacters
{
    for (int i=0;i<numVertical;i++)
        for (int j=0;j<numHorizontal;j++)
        {
            markedWrong[i][j] = FALSE;
            characters[i][j] = 0;
        }
    numFilledIn = 0;
    [self markAllToRefresh];
}

-(BOOL)isDrawnWithMarkerAtH:(int)hPos andV:(int)vPos
{
    return drawnWithMarker[vPos][hPos];
}

-(void)activatePermanentMarker:(BOOL)active
{
    permanentMarker = active;
}

-(BOOL)isPermanentMarkerActive
{
    return permanentMarker;
}

-(BOOL)isClockActive
{
    return clockActive;
}

-(void)activateClock:(BOOL)act
{
    clockActive = act;
}

-(int)getClockSeconds
{
    return clockSeconds;
}

-(void)setClockSeconds:(int)s
{
    clockSeconds = s;
}

-(int)getFilledInPercent
{
    if (numFilledIn == 0)
        return 0;
    if ((100*numFilledIn)/numLetterBoxes < 1)
        return 1;
    return (100*numFilledIn)/numLetterBoxes;
}

#pragma mark -
#pragma mark Refresh methods

-(CGRect)getRefreshRect
{
    return refreshRect;
}

-(void)updateRefreshRectangle
{
    if (selectedWord[0].h >= 0)
    {
        float x0 = 10000.0;
        float y0 = 10000.0;
        float x1 = 0;
        float y1 = 0;
        int i=0;
        while (selectedWord[i].h >= 0)
        {
            if (boxX[selectedWord[i].v][selectedWord[i].h] < x0)
                x0 = boxX[selectedWord[i].v][selectedWord[i].h];
            if (boxY[selectedWord[i].v][selectedWord[i].h] < y0)
                y0 = boxY[selectedWord[i].v][selectedWord[i].h];
            if (boxX[selectedWord[i].v][selectedWord[i].h] + boxWidth[selectedWord[i].v][selectedWord[i].h] > x1)
                x1 = boxX[selectedWord[i].v][selectedWord[i].h] + boxWidth[selectedWord[i].v][selectedWord[i].h];
            if (boxY[selectedWord[i].v][selectedWord[i].h] + boxHeight[selectedWord[i].v][selectedWord[i].h] > y1)
                y1 = boxY[selectedWord[i].v][selectedWord[i].h] + boxHeight[selectedWord[i].v][selectedWord[i].h];
            i++;
        }
        // Throw in some margins
        CGRect newSelection = CGRectMake(x0 * scaleFactor - 4.0, y0 * scaleFactor - 4.0, (x1-x0) * scaleFactor + 8.0, (y1-y0) * scaleFactor + 8.0);
        refreshRect = CGRectUnion(newSelection, oldSelectionRect);
        oldSelectionRect = newSelection;
    }
}

-(void)markAllToRefresh
{
    refreshRect = CGRectMake(0, 0, width * scaleFactor, height * scaleFactor);
    oldSelectionRect = refreshRect;
}

-(void)updateRefreshRectangleForTypingFromPos:(GridPos)p1 toPos:(GridPos)p2
{
    float x0 = boxX[p1.v][p1.h];
    float y0 = boxY[p1.v][p1.h];
    float x1 = boxX[p1.v][p1.h] + boxWidth[p1.v][p1.h];
    float y1 = boxY[p1.v][p1.h] + boxHeight[p1.v][p1.h];
    if (boxX[p2.v][p2.h] < x0)
        x0 = boxX[p2.v][p2.h];
    if (boxY[p2.v][p2.h] < y0)
        y0 = boxY[p2.v][p2.h];
    if (boxX[p2.v][p2.h]+boxWidth[p2.v][p2.h] > x1)
        x1 = boxX[p2.v][p2.h]+boxWidth[p2.v][p2.h];
    if (boxY[p2.v][p2.h]+boxHeight[p2.v][p2.h] > y1)
        y1 = boxY[p2.v][p2.h]+boxHeight[p2.v][p2.h];
    refreshRect = CGRectMake(x0 * scaleFactor - 4.0, y0 * scaleFactor - 4.0, (x1-x0) * scaleFactor + 8.0, (y1-y0) * scaleFactor + 8.0);
}

-(CGRect)getContentRect
{
    return CGRectMake(x, y, width, height);
}

-(void)setScaleFactor:(float)sc
{
    scaleFactor = sc;
}

#pragma mark -
#pragma mark Competition

-(NSString*)getCompetitionString
{
    if (numberBoxes > 0)
    {
        unichar cArray[numberBoxes];
        for (int i=0;i<numberBoxes;i++)
            cArray[i] = characters[numberPos[i].v][numberPos[i].h];
        return [NSString stringWithCharacters:cArray length:numberBoxes];
    }
    else
    {
        unichar cArray[numLetterBoxes];
        int l=0;
        for (int i=0;i<numVertical;i++)
            for (int j=0;j<numHorizontal;j++)
                if (boxWidth[i][j] > 0)
                    cArray[l++] = characters[i][j];
        return [NSString stringWithCharacters:cArray length:numLetterBoxes];
    }
}

-(int)checkSolutionStatus
{
    int status = SOLUTION_FILLED_IN;
    if (numberBoxes > 0)
    {
        for (int i=0;i<numberBoxes;i++)
        {
            if (characters[numberPos[i].v][numberPos[i].h] == 0)
                status = SOLUTION_MISSING_NUMBERS;
        }
    }
    else
    {
        for (int i=0;i<numVertical;i++)
            for (int j=0;j<numHorizontal;j++)
                if (boxWidth[i][j] > 0)
                {
                    if (characters[i][j] == 0)
                        status = SOLUTION_MISSING_LETTERS;
                }
    }
    return status;
}

#pragma mark -

- (void)dealloc {
    [super dealloc];
}

@end
