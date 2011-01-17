//
//  EKGData.m
//  EKGmon
//
//  Created by Jordan Schneider on 7/13/10.
//  Copyright 2010 Copyleft. All rights reserved.
//

#import "EKGData.h"

#include "time.h"

int samplesPerMessage = 360;

@implementation EKGData

@synthesize dataPoints;
@synthesize graphData;
@synthesize qrsCandidates;
@synthesize heartRate;
@synthesize exclusionRange;
@synthesize samplesPerSecond;

- (id)initWithCapacity:(NSInteger)seconds samples:(NSInteger)_samplesPerSecond {
    if (self = [super init]) {
        samplesPerSecond = _samplesPerSecond;
        samplesPerMessage = samplesPerSecond;
        capacity = seconds * samplesPerSecond;
        graphData = [[NSMutableArray alloc] initWithCapacity:capacity];
        
        // for CP to work, every expected value needs to be initialized
        for (int index = 0; index < capacity; ++index) {
            [graphData addObject:[EKGDataPoint dataPointWithInteger:0 atTime:0]];
        }
        
        nextMessageRange.location = 0;
        nextMessageRange.length = samplesPerSecond;
        exclusionRange.length = 180;
        
        dataPoints = [[NSMutableArray alloc] initWithCapacity:capacity];
        qrsCandidates = [[NSMutableArray alloc] initWithCapacity:capacity];
        qrsNotDetectedIndex = 1;
        heartRate = [[NSNumber alloc] initWithInteger:0];
    }
    return self;
}

- (void)appendWithRawData:(uint8_t *)buf length:(NSInteger)bytes {
    
    // full string of unparsed characters
    NSMutableString *fullString = [NSMutableString stringWithUTF8String:(char*)buf];
    
    NSLog(@"%@", fullString);
    
    // on first run, remove junk
    if ([dataPoints count] == 0) {
        NSRange rangeToDelete = [fullString rangeOfString:@"application/x-dom-event-stream"];
        if (rangeToDelete.location != NSNotFound) {
            return;
        }
    }
    
    // extract decimals from the string
    NSArray *decimalArray = [EKGData getAllDecimals:fullString];
    
    // try to remove this object by changing where CP gets its data from
    NSMutableArray *lastMessage = [NSMutableArray arrayWithCapacity:samplesPerSecond];
    
    // create datapoint and add to dataPoints array
    for (id item in decimalArray) {
        double time = [dataPoints count] / (double)samplesPerSecond;
        EKGDataPoint *dataPoint = [EKGDataPoint dataPointWithDecimalNumber:item atTime:time];
        [dataPoints addObject:dataPoint];
        [lastMessage addObject:dataPoint];
    }
    
    // Convert dataObject to EKGDataPoints
    /*
    NSMutableArray *dataPointArrayObject = [NSMutableArray arrayWithCapacity:360];
    for (id item in dataObject) {
        
        double time = [dataPoints count] / 360.0;
        NSInteger value = [item integerValue];
        if (value != 0) {
            EKGDataPoint *dataPoint = [EKGDataPoint dataPointWithInteger:value atTime:time];
            [dataPointArrayObject addObject:dataPoint];
            
            [dataPoints addObject:dataPoint];
            
            NSLog(@"%@\n", dataPoint.value);
        }
    }*/
    
    // Add dataObject to graphData array
    [self willChangeValueForKey:@"graphData"];
    for (int i = 0; (i < [lastMessage count]) && (nextMessageRange.location + i < [graphData count]); ++i) {
        [graphData replaceObjectAtIndex:(nextMessageRange.location + i) withObject:[lastMessage objectAtIndex:i]];
    }
    //[graphData replaceObjectsInRange:nextMessageRange withObjectsFromArray:lastMessage];
    
    nextMessageRange.location = (nextMessageRange.location + [lastMessage count]);
    if (nextMessageRange.location >= capacity) {
        nextMessageRange.location = 0;
    }
    exclusionRange.location = nextMessageRange.location;

    /* Uncomment block to add bad blip between signals */
    /*
    for (NSInteger index = nextMessageRange.location; (index < nextMessageRange.location + 90) && (index != 0); ++index) {
        if (index < capacity) {
            [[graphData objectAtIndex:index] setExcluded:YES];
        }
    }*/
        
    [self didChangeValueForKey:@"graphData"];

}
/*
- (void)appendWithPhysioBankCSV:(NSString *)path {
    
    // Incomplete, just for testing purposes
    
    
    // Remove Header
    NSMutableString *dataString = [NSString stringWithContentsOfFile:path];
    NSRange *header = [path rangeOfString:@"'Elapsed time','ECG'\n'seconds','mV'\n"];
    [dataString deleteCharactersInRange:header];
    
    // Add items to dataPoints dictionary
    NSArray *dataLines = [dataString componentsSeparatedByString:@"\n"];
    for (id item in dataLines) {
        NSArray *dataPoint = [item componentsSeparatedByString:@","];
        EKGDataPoint *dataPoint = [EKGDataPoint dataPointWithDouble:[[item objectAtIndex:1] doubleValue]];
        NSNumber *time = [NSNumber numberWithDouble:[[item objectAtIndex:0] doubleValue]];
        [dataPoints setObject:dataPoint forKey:time];
    }
}
*/

- (void)appendWithSInt32Array:(SInt32 *)array withLength:(NSUInteger)bytes {
    
    // try to remove this object by changing where CP gets its data from
    NSMutableArray *lastMessage = [NSMutableArray arrayWithCapacity:samplesPerSecond];
    
    //NSArray *toAdd = [NSArray arrayWithObjects:array count:bytes];
    for (NSUInteger i = 0; i < bytes; ++i) {
        EKGDataPoint *dataPoint = [EKGDataPoint dataPointWithInteger:(NSInteger)array[i] atTime:0];
        [dataPoints addObject:dataPoint];
        [lastMessage addObject:dataPoint];
    }
    
    // Add dataObject to graphData array
    [self willChangeValueForKey:@"graphData"];
    for (int i = 0; (i < [lastMessage count]) && (nextMessageRange.location + i < [graphData count]); ++i) {
        [graphData replaceObjectAtIndex:(nextMessageRange.location + i) withObject:[lastMessage objectAtIndex:i]];
    }
    //[graphData replaceObjectsInRange:nextMessageRange withObjectsFromArray:lastMessage];
    
    nextMessageRange.location = (nextMessageRange.location + [lastMessage count]);
    if (nextMessageRange.location >= capacity) {
        nextMessageRange.location = 0;
    }
    exclusionRange.location = nextMessageRange.location;
    
    /* Uncomment block to add bad blip between signals */
    /*
     for (NSInteger index = nextMessageRange.location; (index < nextMessageRange.location + 90) && (index != 0); ++index) {
     if (index < capacity) {
     [[graphData objectAtIndex:index] setExcluded:YES];
     }
     }*/
    
    [self didChangeValueForKey:@"graphData"];
}

- (void)appendWithUInt8:(NSNumber *)byte {
    NSAutoreleasePool *autoReleasePool = [[NSAutoreleasePool alloc] init];
    time_t seconds = time(NULL);
    
    EKGDataPoint *dataPoint = [EKGDataPoint dataPointWithNumber:byte atTime:(double)seconds];
    [dataPoints addObject:dataPoint];
    [self willChangeValueForKey:@"graphData"];
    [graphData replaceObjectAtIndex:(nextMessageRange.location) withObject:dataPoint];
    
    nextMessageRange.location++;
    if(nextMessageRange.location >= capacity) {
        nextMessageRange.location = 0;
    }
    exclusionRange.location = nextMessageRange.location;
    
    [self didChangeValueForKey:@"graphData"];
    
    //NSLog(@"%@", byte);
    
    [autoReleasePool release];
}

- (BOOL)hasAnomaly {
    NSInteger tooLow = 0;
    NSInteger tooHigh = 0;
    for (id item in graphData) {
        
        // heart rate greater than 100 bpm
        if ([item integerValue] >= 1000) {
            tooHigh++;
            tooLow = 0;
        } 
        
        // heart rate less than 60 bpm
        else if ([item integerValue] <= 600) {
            tooLow++;
            tooHigh = 0;
        } else {
            tooLow = 0;
            tooHigh = 0;
        }
        if (tooLow == 5 || tooHigh == 5) {
            return YES;
        }
    }
    
    return NO;
}

#pragma mark CPScatterPlotDataSource

- (NSUInteger)numberOfRecordsForPlot:(CPPlot *)plot {
    return capacity;
}

- (NSNumber *)numberForPlot:(CPPlot *)plot 
                      field:(NSUInteger)fieldEnum 
                recordIndex:(NSUInteger)index {
    
    if (fieldEnum == CPScatterPlotFieldX) {
        return [NSNumber numberWithInteger:index];
    } 
    
    else /* fieldEnum == CPScatterPlotFieldY */ {        
        
        if (index >= [graphData count]) {
            return [NSNumber numberWithInteger:0];
        }
        
        NSNumber *result = [[graphData objectAtIndex:index] valueForKey:@"value"];
        return result;
    }
    
}


- (CPPlotSymbol *) symbolForScatterPlot:(CPScatterPlot *)plot recordIndex:(NSUInteger) index {
    
    if (index >= [graphData count]) {
        return [CPPlotSymbol plotSymbol];
    }
    
    if ([[graphData objectAtIndex:index] isQRS] == YES) {
        CPPlotSymbol *plotSymbol = [CPPlotSymbol crossPlotSymbol];
        plotSymbol.size = CGSizeMake(10, 10);
        CPMutableLineStyle *lineStyle = [CPLineStyle lineStyle];
        lineStyle.lineColor = [CPColor magentaColor];
        lineStyle.lineWidth = 3;
        plotSymbol.lineStyle = lineStyle;
        
        //plotSymbol.fill = [CPFill fillWithColor:[CPColor magentaColor]];
        return plotSymbol;
    }
    /*
    if ([[graphData objectAtIndex:index] excluded] == YES) {
        CPPlotSymbol *plotSymbol = [CPPlotSymbol plusPlotSymbol];
        plotSymbol.size = CGSizeMake(10, 10);
        CPLineStyle *lineStyle = [CPLineStyle lineStyle];
        lineStyle.lineColor = [CPColor magentaColor];
        lineStyle.lineWidth = 3;
        plotSymbol.lineStyle = lineStyle;
        return plotSymbol;
    }*/
    
    return [CPPlotSymbol plotSymbol];
}

- (NSMutableArray *)detectQRSwithTuning:(float)amplitudeThreshold positiveSlope:(float)pSlopeThreshold negativeSlope:(float)nSlopeThreshold {
    // See algorithm paper for details
    //float amplitudeThreshold = 0.8 * [[dataPoints valueForKeyPath:@"@max.value"] floatValue];
        
    // X(n)
    double X;
    // Y(n) = X(n+1) - X(n-1)
    double Y;
    
    // increments everytime the pSlopeThreshold is met
    int pSlopeCounter = 0;
    
    // make sure datapoints has content
    if ([dataPoints count] == 0) {
        return nil;
    }
    
    [self willChangeValueForKey:@"graphData"];
    for (int index = qrsNotDetectedIndex; index < [dataPoints count] - 1; ++index) {
        
        // X(n)
        X = [[[dataPoints objectAtIndex:index] value] doubleValue];
        
        if (X >= amplitudeThreshold) {
            
            // Y(n) = X(n+1) - X(n-1)
            Y = [[[dataPoints objectAtIndex:(index + 1)] value] doubleValue] -
                [[[dataPoints objectAtIndex:(index - 1)] value] doubleValue];
            
            if (Y > pSlopeThreshold) {
                
                if (++pSlopeCounter >= 3) {
                    // Positive slope candidate has been found, must find declining slope candidate within next 100ms
                    
                    // increments everytime the nSlopeThreshold is met
                    int nSlopeCounter = 0; 
                    
                    // iterate over the next 100ms
                    double startTime = [[[dataPoints objectAtIndex:index] timeStamp] doubleValue];
                    double scanTime = 0.1;
                    double endTime = startTime + scanTime;
                    
                    double time = startTime;
                    for (int ms = index;  (time < endTime) && ms < [dataPoints count] - 1; ++ms, time = [[[dataPoints objectAtIndex:ms] timeStamp] doubleValue]) {
                        
                        // Y = X(n+1) - X(n-1)
                        Y = [[[dataPoints objectAtIndex:(ms + 1)] value] doubleValue] -
                        [[[dataPoints objectAtIndex:(ms - 1)] value] doubleValue];
                        
                        if (Y < nSlopeThreshold) {
                            if (++nSlopeCounter == 3) {
                                
                                int qrsCandidateIndex = ((ms + index) / 2);
                                
                                [qrsCandidates addObject:[NSNumber numberWithInt:qrsCandidateIndex]];
                                [[dataPoints objectAtIndex:qrsCandidateIndex] setIsQRS:YES];
                                NSLog(@"QRS Candidate at:%d", qrsCandidateIndex);
                                
                                index = ms + 1;
                                nSlopeCounter = 0;
                                break;
                            }
                        }
                        else {
                            nSlopeCounter = 0;
                        }
                        
                        
                    }
                }
                
            }
            else {
                pSlopeCounter = 0;
            }
            
        }
    }
    [self didChangeValueForKey:@"graphData"];
    
    // update heartRate
    if ([qrsCandidates count] >= 2) {
        
        // up to the last 5 heart rates
        NSMutableArray *lastFiveHR = [NSMutableArray arrayWithCapacity:5];
        NSEnumerator *reverseEnumerator = [qrsCandidates reverseObjectEnumerator];
        
        id leftQRSindex;
        id rightQRSindex = [reverseEnumerator nextObject];
        EKGDataPoint *rightQRS;
        EKGDataPoint *leftQRS;
        int counter = 0;
        while ((leftQRSindex = [reverseEnumerator nextObject]) && (counter++ < 5)) {
            
            rightQRS = [dataPoints objectAtIndex:[rightQRSindex integerValue]];
            leftQRS = [dataPoints objectAtIndex:[leftQRSindex integerValue]];
            
            // seconds per beat
            float hr = [[rightQRS timeStamp] floatValue] - [[leftQRS timeStamp] floatValue];
            // beats per second
            hr = 1/hr;
            // beats per minute
            hr *= 60;
            
            NSLog(@"hr %d: %f", counter + 1, hr);
            
            [lastFiveHR addObject:[NSNumber numberWithFloat:hr]];
            
            rightQRSindex = leftQRSindex;
        }
        
        /*
        id lastObject = [qrsCandidates lastObject];
        id thirdLastObject = [qrsCandidates objectAtIndex:([qrsCandidates count] - 3)];
        
        int lastInt = [lastObject intValue];
        int thirdLastInt = [thirdLastObject intValue];
        
        // 360th samples per second
        float hr = (lastInt - thirdLastInt) / 2.0;
        // seconds per sample
        hr /= 360;
        //sample per second;
        hr = 1/hr;
        // beats per minute
        hr *= 60;
        */
        
        [self willChangeValueForKey:@"heartRate"];
        
        // heartRate = median of last five heart rates
        heartRate = [NSNumber numberWithInt: [[[lastFiveHR sortedArrayUsingSelector:@selector(compare:)] objectAtIndex:[lastFiveHR count] / 2] intValue]];
        
        [self didChangeValueForKey:@"heartRate"];
        
        NSLog(@"Heart Rate: %@", heartRate);
    }
    
    qrsNotDetectedIndex = [dataPoints count];
    
    return qrsCandidates;
}

+ (NSArray *)getAllDecimals:(NSString *)string {
    
    NSScanner *scanner = [NSScanner scannerWithString:string];
    NSCharacterSet *nonDigit = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    [scanner setCharactersToBeSkipped:nonDigit];
    NSDecimal decimal;
    NSMutableArray *decimalArray = [NSMutableArray arrayWithCapacity:samplesPerMessage];
    
    while (![scanner isAtEnd]) {
        if ([scanner scanDecimal:&decimal]) {
            [decimalArray addObject:[NSDecimalNumber decimalNumberWithDecimal:decimal]];
        }
    }
    
    NSArray *result = [NSArray arrayWithArray:decimalArray];
    return result;
}

- (void)clearData {
    
    [graphData release];
    [dataPoints release];
    [qrsCandidates release];
    [heartRate release];
}

- (void)dealloc {
    [dataPoints release];
    [graphData release];
    [qrsCandidates release];
    [heartRate release];
    [super dealloc];
}

@end

@implementation EKGDataPoint

@synthesize value;
@synthesize timeStamp;
@synthesize isQRS;
@synthesize excluded;

+ (id)dataPointWithInteger:(NSInteger)integer atTime:(double)time {    
    return [[[EKGDataPoint alloc] initWithInteger:integer atTime:time] autorelease];
}

- (id)initWithInteger:(NSInteger)integer atTime:(double)time {
    if (self = [super init]) {
        value = [[NSDecimalNumber alloc] initWithInteger:integer];
        timeStamp = [[NSDecimalNumber alloc] initWithDouble:time];
        isQRS = NO;
        excluded = NO;
    }
    
    return self;
}

+ (id)dataPointWithUInt8:(uint8_t)integer atTime:(double)time {    
    return [[[EKGDataPoint alloc] initWithUInt8:integer atTime:time] autorelease];
}

- (id)initWithUInt8:(uint8_t)integer atTime:(double)time {
    if (self = [super init]) {
        value = [[NSDecimalNumber alloc] initWithUnsignedInt:(unsigned int)integer];
        timeStamp = [[NSDecimalNumber alloc] initWithDouble:time];
        isQRS = NO;
        excluded = NO;
    }
    
    return self;
}
                               
                               
- (id)initWithDouble:(double)decimal atTime:(double)time {
    if (self = [super init]) {
        value = [[NSDecimalNumber alloc] initWithDouble:decimal];
        timeStamp = [[NSDecimalNumber alloc] initWithDouble:time];
        isQRS = NO;
        excluded = NO;
    }
    
    return self;
}

+ (id)dataPointWithDouble:(double)decimal atTime:(double)time {
    return [[[EKGDataPoint alloc] initWithDouble:decimal atTime:time] autorelease];
}

- (id)initWithDecimalNumber:(NSDecimalNumber *)decimalNumber atTime:(double)time {
    if (self = [super init]) {
        value = [decimalNumber retain];
        timeStamp = [[NSDecimalNumber alloc] initWithDouble:time];
        isQRS = NO;
        excluded = NO;
    }
    
    return self;
}

+ (id)dataPointWithDecimalNumber:(NSDecimalNumber *)decimalNumber atTime:(double)time {
    return [[[EKGDataPoint alloc] initWithDecimalNumber:decimalNumber atTime:time] autorelease];
}

- (id)initWithNumber:(NSNumber *)number atTime:(double)time {
    if (self = [super init]) {
        value = [number retain];
        timeStamp = [[NSDecimalNumber alloc] initWithDouble:time];
        isQRS = NO;
        excluded = NO;
    }
    
    return self;
}

+ (id)dataPointWithNumber:(NSNumber *)number atTime:(double)time {
    return [[[EKGDataPoint alloc] initWithNumber:number atTime:time] autorelease];
}

- (NSComparisonResult)compare:(EKGDataPoint *)aDataPoint {
    return [value compare:aDataPoint.value];
}

- (void)dealloc {
    [value release];
    [timeStamp release];
    [super dealloc];
}

@end

