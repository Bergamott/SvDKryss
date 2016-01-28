//
//  SoundManager.m
//  Speedoku
//
//  Created by Mac Mini on 2012-07-24.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SoundManager.h"
#import "ResourceManager.h"

@implementation SoundManager

@synthesize soundFiles;

static SoundManager* _sharedMySingleton = nil;

// Get the shared instance and create it if necessary.
+(id)sharedInstance {
    @synchronized(self) {
        if (_sharedMySingleton == nil)
            _sharedMySingleton = [[self alloc] init];
    }
    return _sharedMySingleton;
}

-(id)init
{
    if (self = [super init]) {

        [ResourceManager initialize];
        self.soundFiles = [NSArray arrayWithObjects:@"Klick.caf", @"Stopp.caf", @"Blyerts.caf", @"Bläck.caf", @"Hopp_klick.caf", @"Klocka.caf", @"Rutval.caf", @"Radera.caf", @"Rätt_bokstav.caf", @"Rätt_ord.caf", @"Rätt_hela.caf", @"Fel.caf", @"Skriv_över.caf", nil];
   }    
    return self;
}

-(void)playSound:(int)soundEffect
{
    [g_ResManager playSound:[soundFiles objectAtIndex:soundEffect]];
}

-(void)dealloc
{
    [super dealloc];
    [soundFiles release];
}

@end

