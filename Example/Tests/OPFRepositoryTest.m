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

@property (nonatomic,strong) OPFRepository* repository;

@end

@implementation OPFRepositoryTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    NSArray* tables = @[[Person class]];
    NSString* dbPath = NULL;
    _repository = [[OPFRepository alloc] initWith:dbPath tables:tables version:1];
}

- (void)tearDown {
    [super tearDown];
    _repository = nil;
}

- (void)testExample {

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        BOOL tableExists = [_repository syncQueryTableExists:@"person_"];
        
        XCTAssertTrue(tableExists);
    });

    [self waitForTimeInterval:4];
        
}

- (void)testThreads {
    
    for(int i=0;i<20;i++){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            BOOL tableExists = [_repository syncQueryTableExists:@"person_"];
            
            XCTAssertTrue(tableExists);
        });
    }

    
    [self waitForTimeInterval:10];
    
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
