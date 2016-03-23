//
//  OPFRepositoryTest.m
//  PandaFMDB
//
//  Created by lingen on 16/3/23.
//  Copyright © 2016年 lingen.liu. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Person.h"
#import "OPF.h"

@interface OPFRepositoryTest : XCTestCase

@end

@implementation OPFRepositoryTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    
    NSArray* tables = @[[Person class]];
    
    NSString* dbPath = NULL;
    
    OPFRepository* repository = [[OPFRepository alloc] initWith:dbPath tables:tables version:1];
    
    BOOL tableExists = [repository syncQueryTableExists:@"person_"];
    
    XCTAssertTrue(tableExists);
        
}

- (void)waitForTimeInterval:(NSTimeInterval)delay
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"wait"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:delay + 1 handler:nil];
}

- (void)testPerformanceExample {

}

@end
