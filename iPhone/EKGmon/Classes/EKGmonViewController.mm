//
//  EKGmonViewController.m
//  EKGmon
//
//  Created by Jordan Schneider on 7/13/10.
//  Copyright Copyleft 2010. All rights reserved.
//

#import "EKGmonViewController.h"
#import "CorePlot-CocoaTouch.h"

@implementation EKGmonViewController

@synthesize stream;
@synthesize graph;
@synthesize heartRateLabel;
@synthesize hostAddress;
@synthesize yMin;
@synthesize yMax;
@synthesize hijackSwitch;
@synthesize graphView;
@synthesize isGraphing;

- (IBAction)dismissKeyboard:(id)sender {
    [sender resignFirstResponder];
    [self toggleStream];
}

- (IBAction) toggleStream {
    if (start.titleLabel.text == @"Stop") {
        [self stopStream];
    } else {
        [self startStream];
    }
} 

- (IBAction)startStream {
    
    // TODO: make an id sender version of this, customized for the keyboard

    // Setup plot space;
    CPXYPlotSpace *plotSpace = (CPXYPlotSpace *)graph.defaultPlotSpace;
    float seconds = 3;
    NSDecimal loc = [[NSDecimalNumber numberWithFloat:[yMin.text floatValue]] decimalValue];
    NSDecimal length = [[NSDecimalNumber numberWithFloat:([yMax.text floatValue] - [yMin.text floatValue])] decimalValue];
    plotSpace.yRange = [CPPlotRange plotRangeWithLocation:loc length:length];
    
    if (hijackSwitch.on) {
        if (!hijack) {
            hijack = [[Hijack alloc] initWithHostObject:waveform];
        }
        loc = [[NSDecimalNumber numberWithFloat:0] decimalValue];
        length = [[NSDecimalNumber numberWithFloat:(seconds * 20.0)] decimalValue];
        plotSpace.xRange = [CPPlotRange plotRangeWithLocation:loc length:length];
        [hijack start];
    } else {
        
        [waveform initWithCapacity:(NSInteger)seconds samples:360];
        
        NSDecimal loc = [[NSDecimalNumber numberWithFloat:0] decimalValue];
        NSDecimal length = [[NSDecimalNumber numberWithFloat:(seconds * 360.0)] decimalValue];
        plotSpace.xRange = [CPPlotRange plotRangeWithLocation:loc length:length];
        
        // Parse URL
        NSScanner *scanner = [NSScanner scannerWithString:hostAddress.text];
        NSCharacterSet *colon = [NSCharacterSet characterSetWithCharactersInString:@":"];
        NSString *hostString1 = [NSString stringWithString:@""];
        NSString *hostString2 = [NSString stringWithString:@""];
        NSString *hostString3 = [NSString stringWithString:@""];
        NSMutableString *hostString = [NSMutableString stringWithString:@""];
        NSInteger port;
        if (![scanner scanUpToCharactersFromSet:colon intoString:&hostString1]
            || ![scanner scanCharactersFromSet:colon intoString:&hostString2]
            || ![scanner scanUpToCharactersFromSet:colon intoString:&hostString3]
            || ![scanner scanCharactersFromSet:colon intoString:NULL]
            || ![scanner scanInteger:&port])
         {
            NSLog(@"URL Parsing failed");
            return;
         }
        [hostString appendString:hostString1];
        [hostString appendString:hostString2];
        [hostString appendString:hostString3];
        
        // Set up and initialize the stream (consider moving to initWithNibName)
        NSURL *host = [NSURL URLWithString:hostString];
        //[stream initWithURL:host atPort:80];
        [stream initWithURL:host atPort:port];
        
        // set HTTP request
        stream.message = @"GET /ekg/stream.php HTTP/1.0\r\n\r\n";
        //stream.message = @"GET /ekg/stream.php\r\n";
        
        [stream open];
    }
    [start setTitle: @"Stop" forState: UIControlStateNormal];
}

- (IBAction)stopStream {
    
    if (hijackSwitch.on) {
        [hijack stop];
    } else {
        [stream close];
    
        //[waveform clearData];
    }
    [start setTitle: @"Start" forState: UIControlStateNormal];
}

- (IBAction)flashScreenRed {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationDelegate:self];
    flash.alpha = 1.0;
    flash.alpha = 0.0;
    [UIView commitAnimations];
}

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    stream = [SocketStream alloc];
    
    // Allocate the data contianers - should probably defer this
    waveform = [EKGData alloc];
    stream.waveform = waveform;
    
    [waveform addObserver:self forKeyPath:@"heartRate" options:NSKeyValueObservingOptionNew context:nil];
    [waveform addObserver:self forKeyPath:@"graphData" options:NSKeyValueObservingOptionNew context:nil];
    [hijack addObserver:self forKeyPath:@"audioValues" options:NSKeyValueObservingOptionNew context:nil];
    
    heartRateLabel.text = @"0";
    
    // Set up the EKG Graph
    
    // Create graph from theme
    graph = [[CPXYGraph alloc] initWithFrame:graphView.bounds];
	CPTheme *theme = [CPTheme themeNamed:kCPDarkGradientTheme];
    [graph applyTheme:theme];
    graph.paddingLeft = 1.0;
    graph.paddingTop = 1.0;
    graph.paddingRight = 1.0;
    graph.paddingBottom = 1.0;
    graphView.collapsesLayers = NO;
    graphView.hostedGraph = graph;
    
    // Setup plot space;
    CPXYPlotSpace *plotSpace = (CPXYPlotSpace *)graph.defaultPlotSpace;
    float seconds = 3;
    NSDecimal loc = [[NSDecimalNumber numberWithFloat:0] decimalValue];
    NSDecimal length = [[NSDecimalNumber numberWithFloat:(seconds * 20.0)] decimalValue];
    plotSpace.xRange = [CPPlotRange plotRangeWithLocation:loc length:length];
    loc = [[NSDecimalNumber numberWithFloat:[yMin.text floatValue]] decimalValue];
    length = [[NSDecimalNumber numberWithFloat:([yMax.text floatValue] - [yMin.text floatValue])] decimalValue];
    plotSpace.yRange = [CPPlotRange plotRangeWithLocation:loc length:length];
    
    // Populate plot
    CPScatterPlot *ekgPlot = [[CPScatterPlot alloc] init];
    ekgPlot.identifier = @"EKG Plot";
    CPMutableLineStyle *lineStyle = [CPMutableLineStyle lineStyle];
    lineStyle.miterLimit = 1.0f;
    lineStyle.lineWidth = 1.5f;
    lineStyle.lineColor = [CPColor greenColor];
    ekgPlot.dataLineStyle = lineStyle;
    //ekgPlot.plotSymbol = [CPPlotSymbol plusPlotSymbol];
    ekgPlot.dataSource = waveform;
    [graph addPlot:ekgPlot];
    
    // initialize "lock"
    isGraphing = NO;
    
    [waveform initWithCapacity:seconds samples:20];
    
//    // Populate plot space (might have to do this later...)
//    CPXYPlotSpace *plotSpace = (CPXYPlotSpace *)graph.defaultPlotSpace;
//    float seconds = 3;
//    plotSpace.xRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromFloat(0.0) length:CPDecimalFromFloat(seconds * 360.0)];
//    plotSpace.yRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromFloat([yMin.text floatValue]) length:CPDecimalFromFloat([yMax.text floatValue] - [yMin.text floatValue])];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqual:@"heartRate"]) {
        NSNumber *heartRate = [object valueForKey:@"heartRate"];
        heartRateLabel.text = [heartRate stringValue];
        if ([heartRate intValue] < 55) {
            self.view.backgroundColor = [UIColor redColor];
            heartRateLabel.textColor = [UIColor blackColor];
        } else {
            self.view.backgroundColor = [UIColor blackColor];
            heartRateLabel.textColor = [UIColor whiteColor];
        }

    }
    
    if ([keyPath isEqual:@"graphData"]) {
        
        if (!self.isGraphing) {
            self.isGraphing = YES;
            [graph reloadData];
            self.isGraphing = NO;
        }
            
    }
    /*
    if ([keyPath isEqual:@"audioValues"]) {
        NSMutableArray *audioValues = [object valueForKey:@"audioValues"];
        NSRange range;
        range.location = [waveform.dataPoints count];
        range.length = [audioValues count] - range.location;
        [waveform appendWithArray:audioValues withRange:range];
    }*/
    
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    NSLog(@"Memory Warning");

	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

@end
