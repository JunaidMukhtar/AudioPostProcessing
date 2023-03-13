//
//  AudioPostProcessing.m
//  surjX
//
//  Created by Junaid Mukhtar on 03/05/2016.
//  Copyright © 2016 TV2U. All rights reserved.
//

#import "AudioPostProcessing.h"

@implementation AudioPostProcessing

@synthesize reverbValue;
@synthesize distortValue;
@synthesize delayValue;

- (id)init {
    self = [super init];
    
    if (self != nil) {
        
        reverbValue = 0;
        distortValue = 0;
        delayValue = 0;
    }
    return self;
}


-(void) initAUGraph {
    
    graphSampleRate = 44100.0;
    maxSampleTime   = 0.0;
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    NSError *setCategoryError = nil;
    if (![session setCategory:AVAudioSessionCategoryPlayback
                  withOptions:AVAudioSessionCategoryOptionMixWithOthers
                        error:&setCategoryError]) {
        // handle error
    }
    
    [self initializeAUGraph];
}

- (void) setupStereoStream864 {
    
    // The AudioUnitSampleType data type is the recommended type for sample data in audio
    // units. This obtains the byte size of the type for use in filling in the ASBD.
    size_t bytesPerSample = sizeof (AudioUnitSampleType);
    // Fill the application audio format struct's fields to define a linear PCM,
    // stereo, noninterleaved stream at the hardware sample rate.
    stereoStreamFormat864.mFormatID          = kAudioFormatLinearPCM;
    stereoStreamFormat864.mFormatFlags       = kAudioFormatFlagsAudioUnitCanonical;
    stereoStreamFormat864.mBytesPerPacket    = bytesPerSample;
    stereoStreamFormat864.mFramesPerPacket   = 1;
    stereoStreamFormat864.mBytesPerFrame     = bytesPerSample;
    stereoStreamFormat864.mChannelsPerFrame  = 2; // 2 indicates stereo
    stereoStreamFormat864.mBitsPerChannel    = 8 * bytesPerSample;
    stereoStreamFormat864.mSampleRate        = graphSampleRate;
}

- (void)initializeAUGraph {
    
    OSStatus err = NewAUGraph(&myAudioGraph);
    
    // AUNodes represent AudioUnits on the AUGraph and provide an
    // easy means for connecting audioUnits together.
    AUNode filePlayerNode;
    AUNode mixerNode;
    AUNode reverbNode;
    AUNode delayNode;
    AUNode distortNode;
    AUNode toneNode;
    AUNode gOutputNode;
    
    // file player component
    AudioComponentDescription filePlayer_desc;
    filePlayer_desc.componentType = kAudioUnitType_Generator;
    filePlayer_desc.componentSubType = kAudioUnitSubType_AudioFilePlayer;
    filePlayer_desc.componentFlags = 0;
    filePlayer_desc.componentFlagsMask = 0;
    filePlayer_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    
    // Create AudioComponentDescriptions for the AUs we want in the graph
    // mixer component
    AudioComponentDescription mixer_desc;
    mixer_desc.componentType = kAudioUnitType_Mixer;
    mixer_desc.componentSubType = kAudioUnitSubType_MultiChannelMixer;
    mixer_desc.componentFlags = 0;
    mixer_desc.componentFlagsMask = 0;
    mixer_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // Create AudioComponentDescriptions for the AUs we want in the graph
    // Reverb component
    AudioComponentDescription reverb_desc;
    reverb_desc.componentType = kAudioUnitType_Effect;
    reverb_desc.componentSubType = kAudioUnitSubType_Reverb2;
    reverb_desc.componentFlags = 0;
    reverb_desc.componentFlagsMask = 0;
    reverb_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    AudioComponentDescription delay_desc;
    delay_desc.componentType = kAudioUnitType_Effect;
    delay_desc.componentSubType = kAudioUnitSubType_Delay;
    delay_desc.componentFlags = 0;
    delay_desc.componentFlagsMask = 0;
    delay_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    
    //tone component
    AudioComponentDescription tone_desc;
    tone_desc.componentType = kAudioUnitType_FormatConverter;
    tone_desc.componentSubType = kAudioUnitSubType_NewTimePitch;
    //    tone_desc.componentSubType = kAudioUnitSubType_Varispeed;
    tone_desc.componentFlags = 0;
    tone_desc.componentFlagsMask = 0;
    tone_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    
    AudioComponentDescription gOutput_desc;
    gOutput_desc.componentType = kAudioUnitType_Output;
    gOutput_desc.componentSubType = kAudioUnitSubType_GenericOutput;
    gOutput_desc.componentFlags = 0;
    gOutput_desc.componentFlagsMask = 0;
    gOutput_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    //Add nodes to graph
    
    // Add nodes to the graph to hold our AudioUnits,
    // You pass in a reference to the  AudioComponentDescription
    // and get back an  AudioUnit
    
    AUGraphAddNode(myAudioGraph, &filePlayer_desc, &filePlayerNode );
    AUGraphAddNode(myAudioGraph, &mixer_desc, &mixerNode );
    AUGraphAddNode(myAudioGraph, &reverb_desc, &reverbNode );
    AUGraphAddNode(myAudioGraph, &delay_desc, &delayNode);
    AUGraphAddNode(myAudioGraph, &tone_desc, &toneNode );
    AUGraphAddNode(myAudioGraph, &gOutput_desc, &gOutputNode);
    
    //Open the graph early, initialize late
    // open the graph AudioUnits are open but not initialized (no resource allocation occurs here)
    
    err = AUGraphOpen(myAudioGraph);
    
    //Reference to Nodes
    // get the reference to the AudioUnit object for the file player graph node
    AUGraphNodeInfo(myAudioGraph, filePlayerNode, NULL, &filePlayerUnit);
    AUGraphNodeInfo(myAudioGraph, reverbNode, NULL, &reverbUnit);
    AUGraphNodeInfo(myAudioGraph, delayNode, NULL, &delay);
    AUGraphNodeInfo(myAudioGraph, toneNode, NULL, &toneUnit);
    AUGraphNodeInfo(myAudioGraph, mixerNode, NULL, &mixerUnit);
    AUGraphNodeInfo(myAudioGraph, gOutputNode, NULL, &genericOutputUnit);
    
    AUGraphConnectNodeInput(myAudioGraph, filePlayerNode, 0, reverbNode, 0);
    AUGraphConnectNodeInput(myAudioGraph, reverbNode, 0, delayNode, 0);
    
    if (distortValue > 0) {
        
        AudioComponentDescription distort_desc;
        distort_desc.componentType = kAudioUnitType_Effect;
        distort_desc.componentSubType = kAudioUnitSubType_Distortion;
        distort_desc.componentFlags = 0;
        distort_desc.componentFlagsMask = 0;
        distort_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
        
        AUGraphAddNode(myAudioGraph, &distort_desc, &distortNode);
        AUGraphNodeInfo(myAudioGraph, distortNode, NULL, &distort);
        AUGraphConnectNodeInput(myAudioGraph, delayNode, 0, distortNode, 0);
        AUGraphConnectNodeInput(myAudioGraph, distortNode, 0, toneNode, 0);
        AUGraphConnectNodeInput(myAudioGraph, toneNode, 0, mixerNode,0);
        AUGraphConnectNodeInput(myAudioGraph, mixerNode, 0, gOutputNode, 0);
    }
    else {
        
        AUGraphConnectNodeInput(myAudioGraph, delayNode, 0, toneNode, 0);
        AUGraphConnectNodeInput(myAudioGraph, toneNode, 0, mixerNode,0);
        AUGraphConnectNodeInput(myAudioGraph, mixerNode, 0, gOutputNode, 0);
    }
    
    UInt32 busCount   = 2;    // bus count for mixer unit input
    
    //Setup mixer unit bus count
    err = AudioUnitSetProperty (
                                mixerUnit,
                                kAudioUnitProperty_ElementCount,
                                kAudioUnitScope_Input,
                                0,
                                &busCount,
                                sizeof (busCount)
                                );
    
    //Enable metering mode to view levels input and output levels of mixer
    UInt32 onValue = 1;
    err = AudioUnitSetProperty(mixerUnit,
                               kAudioUnitProperty_MeteringMode,
                               kAudioUnitScope_Input,
                               0,
                               &onValue,
                               sizeof(onValue));
    
    // Increase the maximum frames per slice allows the mixer unit to accommodate the
    //    larger slice size used when the screen is locked.
    UInt32 maximumFramesPerSlice = 4096;
    
    err = AudioUnitSetProperty (
                                mixerUnit,
                                kAudioUnitProperty_MaximumFramesPerSlice,
                                kAudioUnitScope_Global,
                                0,
                                &maximumFramesPerSlice,
                                sizeof (maximumFramesPerSlice)
                                );
    
    // set the audio data format of tone Unit
    AudioUnitSetProperty(toneUnit,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Global,
                         0,
                         &stereoStreamFormat864,
                         sizeof(AudioStreamBasicDescription));
    
    // set the audio data format of reverb Unit
    AudioUnitSetProperty(reverbUnit,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Global,
                         0,
                         &stereoStreamFormat864,
                         sizeof(AudioStreamBasicDescription));
    
    AudioUnitSetParameter(reverbUnit,kAudioUnitScope_Global,0,kReverb2Param_DryWetMix,reverbValue,0);
    
    AudioUnitSetParameter(delay,kAudioUnitScope_Input,0,kDelayParam_WetDryMix,delayValue,0);
    
    AudioUnitSetParameter(distort,kAudioUnitScope_Global,0,kDistortionParam_RingModMix,distortValue,0);
    
    
    AudioStreamBasicDescription     auEffectStreamFormat;
    UInt32 asbdSize = sizeof (auEffectStreamFormat);
    memset (&auEffectStreamFormat, 0, sizeof (auEffectStreamFormat ));
    
    // get the audio data format from reverb
    err = AudioUnitGetProperty(reverbUnit,
                               kAudioUnitProperty_StreamFormat,
                               kAudioUnitScope_Input,
                               0,
                               &auEffectStreamFormat,
                               &asbdSize);
    
    
    auEffectStreamFormat.mSampleRate = graphSampleRate;
    
    // set the audio data format of mixer Unit
    err = AudioUnitSetProperty(mixerUnit,
                               kAudioUnitProperty_StreamFormat,
                               kAudioUnitScope_Output,
                               0,
                               &auEffectStreamFormat, sizeof(auEffectStreamFormat));
    
    err = AUGraphInitialize(myAudioGraph);
    
    if ([self setUpAUFilePlayer] == noErr) {
        
        [self startRecordingAAC];
    }
}

-(OSStatus) setUpAUFilePlayer {
    
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *songPath = [[NSString alloc] initWithFormat: @"%@/Karaoke/AudioRecording.m4a", documentsDirectory];
    
    CFURLRef songURL = (__bridge  CFURLRef) [NSURL fileURLWithPath:songPath];
    
    // open the input audio file
    OSStatus err = AudioFileOpenURL(songURL, kAudioFileReadPermission, 0, &inputFile);
    
    AudioStreamBasicDescription fileASBD;
    // get the audio data format from the file
    UInt32 propSize = sizeof(fileASBD);
    
    err = AudioFileGetProperty(inputFile, kAudioFilePropertyDataFormat,
                               &propSize, &fileASBD);
    
    // tell the file player unit to load the file we want to play
    err = AudioUnitSetProperty(filePlayerUnit, kAudioUnitProperty_ScheduledFileIDs,
                               kAudioUnitScope_Global, 0, &inputFile, sizeof(inputFile));
    
    UInt64 nPackets;
    UInt32 propsize = sizeof(nPackets);
    err = AudioFileGetProperty(inputFile, kAudioFilePropertyAudioDataPacketCount,
                               &propsize, &nPackets);
    
    // tell the file player AU to play the entire file
    ScheduledAudioFileRegion rgn;
    memset (&rgn.mTimeStamp, 0, sizeof(rgn.mTimeStamp));
    rgn.mTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
    rgn.mTimeStamp.mSampleTime = 0;
    rgn.mCompletionProc = NULL;
    rgn.mCompletionProcUserData = NULL;
    rgn.mAudioFile = inputFile;
    rgn.mLoopCount = -1;
    rgn.mStartFrame = 0;
    rgn.mFramesToPlay = nPackets * fileASBD.mFramesPerPacket;
    
    if (maxSampleTime < rgn.mFramesToPlay)
    {
        maxSampleTime = rgn.mFramesToPlay;
    }
    
    err = AudioUnitSetProperty(filePlayerUnit, kAudioUnitProperty_ScheduledFileRegion,
                               kAudioUnitScope_Global, 0,&rgn, sizeof(rgn));
    
    // prime the file player AU with default values
    UInt32 defaultVal = 0;
    
    err = AudioUnitSetProperty(filePlayerUnit, kAudioUnitProperty_ScheduledFilePrime,
                               kAudioUnitScope_Global, 0, &defaultVal, sizeof(defaultVal));
    
    
    // tell the file player AU when to start playing (-1 sample time means next render cycle)
    AudioTimeStamp startTime;
    memset (&startTime, 0, sizeof(startTime));
    startTime.mFlags = kAudioTimeStampSampleTimeValid;
    
    startTime.mSampleTime = -1;
    err = AudioUnitSetProperty(filePlayerUnit, kAudioUnitProperty_ScheduleStartTimeStamp,
                               kAudioUnitScope_Global, 0, &startTime, sizeof(startTime));
    
    return noErr;
    
}


- (void)startRecordingAAC{
    
    AudioStreamBasicDescription destinationFormat;
    memset(&destinationFormat, 0, sizeof(destinationFormat));
    destinationFormat.mChannelsPerFrame = 2;
    destinationFormat.mFormatID = kAudioFormatMPEG4AAC;
    UInt32 size = sizeof(destinationFormat);
    OSStatus result = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &size, &destinationFormat);
    if(result) printf("AudioFormatGetProperty %ld \n", result);
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    
    
    NSString *destinationFilePath = [[NSString alloc] initWithFormat: @"%@/Karaoke/AudioRecordingWithEffects.m4a", documentsDirectory];
    CFURLRef destinationURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                                            (CFStringRef)destinationFilePath,
                                                            kCFURLPOSIXPathStyle,
                                                            false);
    //    [destinationFilePath release];
    
    // specify codec Saving the output in .m4a format
    result = ExtAudioFileCreateWithURL(destinationURL,
                                       kAudioFileM4AType,
                                       &destinationFormat,
                                       NULL,
                                       kAudioFileFlags_EraseFile,
                                       &extAudioFile);
    if(result) printf("ExtAudioFileCreateWithURL %ld \n", result);
    CFRelease(destinationURL);
    
    // This is a very important part and easiest way to set the ASBD for the File with correct format.
    AudioStreamBasicDescription clientFormat;
    UInt32 fSize = sizeof (clientFormat);
    memset(&clientFormat, 0, sizeof(clientFormat));
    // get the audio data format from the Output Unit
    
    OSStatus err = AudioUnitGetProperty(genericOutputUnit,
                                        kAudioUnitProperty_StreamFormat,
                                        kAudioUnitScope_Output,
                                        0,
                                        &clientFormat,
                                        &fSize);
    
    // set the audio data format of mixer Unit
    err = ExtAudioFileSetProperty(extAudioFile,
                                  kExtAudioFileProperty_ClientDataFormat,
                                  sizeof(clientFormat),
                                  &clientFormat);
    // specify codec
    UInt32 codec = kAppleHardwareAudioCodecManufacturer;
    err = ExtAudioFileSetProperty(extAudioFile,
                                  kExtAudioFileProperty_CodecManufacturer,
                                  sizeof(codec),
                                  &codec);
    
    err = ExtAudioFileWriteAsync(extAudioFile, 0, NULL);
    
    [self pullGenericOutput];
}

-(void)pullGenericOutput {
    
    AudioUnitRenderActionFlags flags = 0;
    AudioTimeStamp inTimeStamp;
    memset(&inTimeStamp, 0, sizeof(AudioTimeStamp));
    inTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
    UInt32 busNumber = 0;
    UInt32 numberFrames = 512;
    inTimeStamp.mSampleTime = 0;
    int channelCount = 2;
    
    NSLog(@"Final numberFrames :%li",numberFrames);
    int totFrms = maxSampleTime;
    while (totFrms > 0)
    {
        if (totFrms < numberFrames)
        {
            numberFrames = totFrms;
        }
        else
        {
            totFrms -= numberFrames;
        }
        AudioBufferList *bufferList = (AudioBufferList*)malloc(sizeof(AudioBufferList)+sizeof(AudioBuffer)*(channelCount-1));
        bufferList->mNumberBuffers = channelCount;
        for (int j=0; j<channelCount; j++)
        {
            AudioBuffer buffer = {0};
            buffer.mNumberChannels = 1;
            buffer.mDataByteSize = numberFrames*sizeof(AudioUnitSampleType);
            buffer.mData = calloc(numberFrames, sizeof(AudioUnitSampleType));
            
            bufferList->mBuffers[j] = buffer;
        }
        
        OSStatus err = AudioUnitRender(genericOutputUnit,
                                       &flags,
                                       &inTimeStamp,
                                       busNumber,
                                       numberFrames,
                                       bufferList);
        
        inTimeStamp.mSampleTime++;
        
        err = ExtAudioFileWrite(extAudioFile, numberFrames, bufferList);
        
    }
    
    [self FilesSavingCompleted];
}

-(void)FilesSavingCompleted{
    
    OSStatus status = ExtAudioFileDispose(extAudioFile);
    printf("OSStatus(ExtAudioFileDispose): %ld\n", status);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"POSTPROCESSINGCOMPLETED" object:nil];
}

@end
