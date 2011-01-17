//
//  SocketStream.m
//  EKGmon
//
//  Created by Jordan Schneider on 7/13/10.
//  Copyright 2010 Copyleft. All rights reserved.
//

#import "SocketStream.h"
#import "EKGData.h"
#import "EKGmonViewController.h"


@implementation SocketStream
@synthesize message;
@synthesize inputStream;
@synthesize outputStream;
@synthesize waveform;

- (id)initWithURL:(NSURL *)url atPort:(UInt32)port {
    
    // TODO: Add support for reopening outputStream
    if (self = [super init]) {
        // Check for valid URL
        if (!url) {
            NSLog(@"%@ is not a valid URL", url);
            return nil;
        }
        
        // Pair socket with host
        CFReadStreamRef readStream;
        CFWriteStreamRef writeStream;
        CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)[url host], port, &readStream, &writeStream);
        
        // Cast to NSStreams
        inputStream = (NSInputStream *)readStream;
        outputStream = (NSOutputStream *)writeStream;
        
        // Set delegate
        [inputStream setDelegate:self];
        [outputStream setDelegate:self];
        
        // Schedule in loop
        [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
    
    return self;
}

- (void)writeMessage {
    const uint8_t *rawString = (const uint8_t *)[message UTF8String];
    [outputStream write:rawString maxLength:strlen((char*)rawString)];
    [outputStream close];
}

- (void)open {
    [outputStream open];
    [inputStream open];
}

- (void)close {
    
    [inputStream close];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    
    // Ovveride point to handle stream events
    switch (eventCode) {
            // Logging sanity
        case NSStreamEventOpenCompleted:
            NSLog(@"%@ has succesfully opened.", [aStream class]);
            break;
        case NSStreamEventErrorOccurred:
            NSLog(@"%@ has encountered an error.", [aStream class]);
            break;
        case NSStreamEventEndEncountered:
            NSLog(@"%@ has reached its end.", [aStream class]);
            break;
            
            // Actual event handleing
        case NSStreamEventHasSpaceAvailable:
            // Stream is ready to write
            NSLog(@"%@ is ready to write.", [aStream class]);
            if (aStream == outputStream) {
                [self writeMessage];
                NSLog(@"%@ has written to the stream.", [aStream class]);
            }
            break;
            
        case NSStreamEventHasBytesAvailable:
            
            // Stream is ready to read
            NSLog(@"%@ is ready to read.", [aStream class]);
            if (aStream == inputStream) {
                
                // Read stream into buffer
                NSUInteger bytes = [inputStream read:buf maxLength:BUFFER_SIZE];
                
                // NULL terminale stream
                buf[bytes] = (uint8_t)'\0';
                
                // Append data into usable data in EKGData object
                [waveform appendWithRawData:buf length:bytes];
                
                // Calculate heart rate
                [waveform detectQRSwithTuning:0 positiveSlope:20 negativeSlope:-20];
                /*
                 // regraph
                 if (delegate) {
                 // reconsider this whole method... probably do some KVO                   
                 //[[delegate graph] reloadData];
                 //[delegate heartRateLabel].text = [waveform.heartRate stringValue];
                 if ([waveform.heartRate intValue] < 70) {
                 [delegate view].backgroundColor = [UIColor redColor];
                 [delegate heartRateLabel].textColor = [UIColor blackColor];
                 } else {
                 [delegate view].backgroundColor = [UIColor blackColor];
                 [delegate heartRateLabel].textColor = [UIColor whiteColor];
                 }
                 } */
                
                
                NSLog(@"%@ has read from the stream.", [aStream class]);
            }
            break;
            
        default:
            break;
    }
    
}

- (void)dealloc {
    [inputStream release];
    [outputStream release];
    [message release];
    [waveform release];
    [super dealloc];
}

@end
