//
//  SoundManager.h
//  Speedoku
//
//  Created by Mac Mini on 2012-07-24.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

//#import <Foundation/Foundation.h>
//#import <AudioToolbox/AudioToolbox.h>

#define CLICK_SOUND 0
#define STOP_SOUND 1
#define PENCIL_SOUND 2
#define PEN_SOUND 3
#define JUMP_CLICK_SOUND 4
#define CLOCK_SOUND 5
#define SELECTION_SOUND 6
#define DELETE_SOUND 7
#define CORRECT_LETTER_SOUND 8
#define CORRECT_WORD_SOUND 9
#define CORRECT_ALL_SOUND 10
#define WRONG_SOUND 11
#define OVERWRITE_SOUND 12

#define NUM_SOUNDS 13

@interface SoundManager : NSObject {
    
    NSArray *soundFiles;
}

+(id)sharedInstance;
-(void)playSound:(int)soundEffect;

@property (nonatomic,retain) NSArray *soundFiles;

@end
