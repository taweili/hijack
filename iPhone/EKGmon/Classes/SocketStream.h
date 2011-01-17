//
//  SocketStream.h
//  EKGmon
//
//  Created by Jordan Schneider on 7/13/10.
//  Copyright 2010 Copyleft. All rights reserved.
//

#import "EKGData.h"

#define BUFFER_SIZE 262144

@interface SocketStream : NSObject <NSStreamDelegate> {
    
    // A container class for an input stream and output stream designed for socket programming.
    
    // Input stream and its buffer
    uint8_t buf[BUFFER_SIZE];
    NSInputStream *inputStream;
    
    // Message to write to the host
    NSString *message;
    NSOutputStream *outputStream;
    
    // Pointer to an EKGData object, owned by the delegate
    EKGData *waveform;
}

@property (copy) NSString *message;
@property (assign) NSInputStream *inputStream;
@property (assign) NSOutputStream *outputStream;
@property (assign) EKGData *waveform;

- (id)initWithURL:(NSURL *)url atPort:(UInt32)port;
// Pairs a socket to a host, sets its delegate, and schedules the event in a loop.

- (void)open;
// Starts the stream.

- (void)close;
// Stops the stream.

- (void)writeMessage;
// writes message to the host. outputStream will close upon completion.

//- (void)setDelegate:(id)delegate;
// sets the delegate for SocketStream

@end

