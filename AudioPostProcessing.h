//
//  AudioPostProcessing.h
//  SunFly
//
//  Created by Junaid Mukhtar on 03/05/2016.
//  Copyright © 2016 TV2U. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AUGraph.h>
#import <AudioToolbox/AudioFile.h>
#import <AudioToolbox/AudioFormat.h>
#import <AVFoundation/AVAudioSession.h>
#import <AudioToolbox/ExtendedAudioFile.h>

@interface AudioPostProcessing : NSObject
{
    AUGraph myAudioGraph;
    AudioUnit filePlayerUnit;
    AudioUnit reverbUnit;
    AudioUnit delay;
    AudioUnit distort;
    AudioUnit toneUnit;
    AudioUnit mixerUnit;
    AudioUnit genericOutputUnit;
    
    
    AudioFileID inputFile;
    //Audio file refereces for saving
    
    ExtAudioFileRef extAudioFile;
    //Standard sample rate
    Float64 graphSampleRate;
    AudioStreamBasicDescription stereoStreamFormat864;
    
    Float64 maxSampleTime;
}

@property(nonatomic) float reverbValue;
@property(nonatomic) float delayValue;
@property(nonatomic) float distortValue;


-(void) initAUGraph;
@end
