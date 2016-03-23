//
//  OPFTableTest.m
//  PandaFMDB
//
//  Created by lingen on 16/3/23.
//  Copyright © 2016年 lingen.liu. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Person.h"
#import "OPFTable.h"
#import "OPFColumn.h"

@interface OPFTableTest : XCTestCase

@end

@implementation OPFTableTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}


-(void)testCreateTable{
    OPFColumn *name = [[OPFColumn alloc] initNotNullColumn:@"name_" type:OPFColumnText];
    OPFColumn *age = [[OPFColumn alloc] initWith:@"age_" type:OPFColumnInteger];
    NSArray* columns = @[name,age];
    OPFTable *table = [[OPFTable alloc] initWith:@"person_" columns:columns];
    NSLog(@"建表语句为：%@",[table createTableSQL]);
}

-(void)testCreateTalbeWithPrimaryKey{
    OPFColumn *idColumn = [[OPFColumn alloc] initWith:@"id_" type:OPFColumnInteger];
    OPFColumn *name = [[OPFColumn alloc] initNotNullColumn:@"name_" type:OPFColumnText];
    OPFColumn *age = [[OPFColumn alloc] initWith:@"age_" type:OPFColumnInteger];
    NSArray* columns = @[name,age,idColumn];
    NSArray* primaryKey = @[idColumn];
    OPFTable *table = [[OPFTable alloc] initWith:@"person2_" columns:columns prmairyColumns:primaryKey];
    NSLog(@"建表语句为：%@",[table createTableSQL]);
}

-(void)testCreateTalbeWithMultiPrimaryKey{
    OPFColumn *idColumn = [[OPFColumn alloc] initWith:@"id_" type:OPFColumnInteger];
    OPFColumn *name = [[OPFColumn alloc] initNotNullColumn:@"name_" type:OPFColumnText];
    OPFColumn *age = [[OPFColumn alloc] initWith:@"age_" type:OPFColumnInteger];
    NSArray* columns = @[name,age,idColumn];
    NSArray* primaryKey = @[idColumn,age];
    OPFTable *table = [[OPFTable alloc] initWith:@"person3_" columns:columns prmairyColumns:primaryKey];
    NSLog(@"建表语句为：%@",[table createTableSQL]);
}

-(void)testCreateTalbeWithIndex{
    OPFColumn *idColumn = [[OPFColumn alloc] initWith:@"id_" type:OPFColumnInteger];
    OPFColumn *name = [[OPFColumn alloc] initNotNullColumn:@"name_" type:OPFColumnText];
    OPFColumn *age = [[OPFColumn alloc] initWith:@"age_" type:OPFColumnInteger];
    NSArray* columns = @[name,age,idColumn];
    NSArray* primaryKey = @[idColumn];
    NSArray* indexKey = @[age];
    OPFTable *table = [[OPFTable alloc] initWith:@"person4_" columns:columns primaryColumns:primaryKey indexColumns:indexKey];
    NSLog(@"建表语句为：%@",[table createTableSQL]);
    NSLog(@"索引语句：%@",[table createIndexSQL]);
}

-(void)testCreateTalbeWithMultiIndex{
    OPFColumn *idColumn = [[OPFColumn alloc] initWith:@"id_" type:OPFColumnInteger];
    OPFColumn *name = [[OPFColumn alloc] initNotNullColumn:@"name_" type:OPFColumnText];
    OPFColumn *age = [[OPFColumn alloc] initWith:@"age_" type:OPFColumnInteger];
    NSArray* columns = @[name,age,idColumn];
    NSArray* primaryKey = @[idColumn];
    NSArray* indexKey = @[age,name];
    OPFTable *table = [[OPFTable alloc] initWith:@"person5_" columns:columns primaryColumns:primaryKey indexColumns:indexKey];
    NSLog(@"建表语句为：%@",[table createTableSQL]);
    NSLog(@"索引语句：%@",[table createIndexSQL]);
}

@end
