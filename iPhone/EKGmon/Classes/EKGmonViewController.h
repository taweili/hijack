//
//  EKGmonViewController.h
//  EKGmon
//
//  Created by Jordan Schneider on 7/13/10.
//  Copyright Copyleft 2010. All rights reserved.
//

#import "SocketStream.h"
#import "EKGData.h"
#import "Hijack.h"
#import "CorePlot-CocoaTouch.h"

@interface EKGmonViewController : UIViewController {
    // View
    IBOutlet UIImageView *flash;
    IBOutlet UIButton *start;
    IBOutlet CPGraphHostingView *graphView;
    IBOutlet UILabel *heartRateLabel;
    IBOutlet UITextField *hostAddress;
    IBOutlet UITextField *yMin;
    IBOutlet UITextField *yMax;
    IBOutlet UISwitch *hijackSwitch;
    // Graph for graphView
    CPXYGraph *graph;
    // used as a lock
    BOOL isGraphing;
    
    // Model
    SocketStream *stream;
    EKGData *waveform;
    Hijack *hijack;
}

@property (assign) SocketStream *stream;
@property (assign) CPXYGraph *graph;
@property (nonatomic, retain) IBOutlet UILabel *heartRateLabel;
@property (nonatomic, retain) IBOutlet UITextField *hostAddress;
@property (nonatomic, retain) IBOutlet UITextField *yMin;
@property (nonatomic, retain) IBOutlet UITextField *yMax;
@property (nonatomic, retain) IBOutlet UISwitch *hijackSwitch;
@property (nonatomic, retain) IBOutlet CPGraphHostingView *graphView;
@property (assign) BOOL isGraphing;

- (IBAction)startStream;
// starts the stream

- (IBAction)stopStream;
// stops the stream

- (IBAction)toggleStream;
// toggles the stream

- (IBAction)flashScreenRed;
// flashes the screen red

- (IBAction)dismissKeyboard:(id)sender;
// dismiss the keyboard

@end

