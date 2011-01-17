//
//  LogicTests.m
//  EKGmon
//
//  Created by Jordan Schneider on 8/16/10.
//  Copyright 2010 Copyleft. All rights reserved.
//

#import "LogicTests.h"


@implementation LogicTests

#if USE_APPLICATION_UNIT_TEST     // all code under test is in the iPhone Application

- (void) testEKGDataDetectQRS {
    
    id ekgData = [[EKGData alloc] initWithCapacity:360];
    STAssertNotNil(ekgData, @"Error initializing EKGData object");
    NSString *fileString = [NSString stringWithContentsOfFile:@"sample.csv"];
    NSArray *dataPoints = [fileString componentsSeparatedByString:@","];
    
    
}

#else                           // all code under test must be linked into the Unit Test bundle

- (void) testMath {
    
    STAssertTrue((1+1)==2, @"Compiler isn't feeling well today :-(" );
    
}


#endif


@end
