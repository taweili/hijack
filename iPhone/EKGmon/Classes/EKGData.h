//
//  EKGData.h
//  EKGmon
//
//  Created by Jordan Schneider on 7/13/10.
//  Copyright 2010 Copyleft. All rights reserved.
//

#import "CorePlot-CocoaTouch.h"

@interface EKGData : NSObject <CPScatterPlotDataSource> {
    // Array containg data only for the plot
    NSMutableArray *graphData;
    // Capacity of the graph
    NSInteger capacity;
    // range of the next object to be added to the plot
    NSRange nextMessageRange;
    // range of exclusion area for next plot
    NSRange exclusionRange;
    
    // Array of all data plots recorded. Key is the time in seconds
    NSMutableArray *dataPoints;
    
    // Array of all QRS Candidates
    NSMutableArray *qrsCandidates;
    // the value of the next object whose QRS has not been detected
    NSUInteger qrsNotDetectedIndex;
    
    // The heart rate based off the last three qrsCandidates
    NSNumber *heartRate;
    
    // samples per second, defaults to 360
    int samplesPerSecond;
}

@property (readonly) NSMutableArray *dataPoints;
@property (assign) NSMutableArray *graphData;
@property (readonly) NSMutableArray *qrsCandidates;
@property (readonly, retain) NSNumber *heartRate;
@property (readonly, assign) NSRange exclusionRange;
@property (assign) int samplesPerSecond;

- (id)initWithCapacity:(NSInteger)seconds samples:(NSInteger)samplesPerSecond;
// initializes the graphData object

- (void)appendWithRawData:(uint8_t *)buf length:(NSInteger)bytes;
// Takes raw bytes to parse and clean up, then inputs integers into ints.
// buf MUST be NULL terminated

//- (void)appendWithPhysioBankCSV:(NSString *)path;
// Takes a CSV and appends it to the object

- (void)appendWithSInt32Array:(SInt32 *)array withLength:(NSUInteger)bytes;

- (void)appendWithUInt8:(NSNumber *)byte;

- (BOOL)hasAnomaly;
// returns true if there are 5 or more values below 600 or 5 or more values above 1000
// current flaw: does not cross EKGData items.
// SOLUTION: just use one EKGData object, and keep track of what has been tested 

- (NSMutableArray *)detectQRSwithTuning:(float)amplitudeThreshold positiveSlope:(float)pSlopeThreshold negativeSlope:(float)nSlopeThreshold;
// uses AF1 algorithm to detect QRSs in a set of data. Returns indexes to the QRS as NSNumbers 
// within an NSArray

+ (NSArray *)getAllDecimals:(NSString *)string;
// Returns an array of all decimals in string, as NSDecimalNumbers

- (void)clearData;
// clears all data that needs to be initialized
@end

// TODO: Make an EKGDataPoint object
@interface EKGDataPoint : NSObject {
    NSDecimalNumber *value;
    NSDecimalNumber *timeStamp;
    BOOL isQRS;
    BOOL excluded;
}

@property (retain) NSDecimalNumber *value;
@property (retain) NSDecimalNumber *timeStamp;
@property (assign) BOOL isQRS;
@property (assign) BOOL excluded;

- (id)initWithInteger:(NSInteger)integer atTime:(double)time;
// Initializes dataPoint with integer

+ (id)dataPointWithInteger:(NSInteger)integer atTime:(double)time;
// Returns allocated dataPoint with integer

- (id)initWithUInt8:(uint8_t)integer atTime:(double)time;
// Initializes dataPoint with uint8

+ (id)dataPointWithUInt8:(uint8_t)integer atTime:(double)time;
// Returns allocated dataPoint with uint8

- (id)initWithDouble:(double)decimal atTime:(double)time;
// Initializes dataPoint with double

+ (id)dataPointWithDouble:(double)decimal atTime:(double)time;
// Returns allocated dataPoint with double

- (id)initWithDecimalNumber:(NSDecimalNumber *)decimalNumber atTime:(double)time;
// Initializes dataPoint with NSDecimalNumber

+ (id)dataPointWithDecimalNumber:(NSDecimalNumber *)decimalNumber atTime:(double)time;
// Returns allocated dataPoint with double

- (id)initWithNumber:(NSNumber *)number atTime:(double)time;
// Initializes dataPoint with NSNumber

+ (id)dataPointWithNumber:(NSNumber *)number atTime:(double)time;
// Returns allocated dataPoint with NSNumber

- (NSComparisonResult)compare:(EKGDataPoint *)aDataPoint;
// Retuns NSOrderedAscending if the value of aDataPoint is greater than the receiver’s,
// NSOrderedSame if they’re equal,
// NSOrderedDescending if the value of aDataPoint is less than the receiver’s.

@end



