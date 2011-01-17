//
//  Hijack.h
//  EKGmon
//
//  Created by Jordan Schneider on 11/22/10.
//  Copyright 2010 Copyleft. All rights reserved.
//

#import "AudioUnit/AudioUnit.h"
#import "CAXException.h"
#import "CAStreamBasicDescription.h"
#import "aurio_helper.h"
#import "EKGData.h"

#define NUMBUFFERS 3

#define SAMPLE_RATE 44100 // Hertz
 
// A custom AudioUnit wrapper Obj-C class for Hijack
@interface Hijack : NSObject {
    
    // private, audio unit stuff
    AudioUnit rioUnit;
    AURenderCallbackStruct inputProc;
    CAStreamBasicDescription thruFormat;
    Float64 hwSampleRate;
    BOOL mute;
    int unitIsRunning;
    DCRejectionFilter* dcFilter;
    
    // container for extracted values
    NSMutableArray* decodedValues;
    // delegate to send values to
    id hostObject;
}

@property (readonly) NSMutableArray *decodedValues;
@property (retain) id hostObject;

-(id)initWithHostObject:(id)hostObject;

-(void)start;
-(void)stop;

@end
