//
//  Person.m
//  PandaFMDB
//
//  Created by lingen on 16/3/21.
//  Copyright © 2016年 lingen.liu. All rights reserved.
//

#import "Person.h"
#import "OPFTable.h"
#import "OPFColumn.h"

@implementation Person

+(NSArray *)initTable{
    NSMutableArray *arrays = [[NSMutableArray alloc] init];
    
    NSString *createPersonSQL = @"create table person_ ( name text not null,age int not null )";
    
    [arrays addObject:createPersonSQL];
    
    return [arrays copy];
}


+(OPFTable*)createTable{
    OPFColumn *name = [[OPFColumn alloc] initNotNullColumn:@"name_" type:OPFColumnText];
    OPFColumn *age = [[OPFColumn alloc] initWith:@"age_" type:OPFColumnInteger];
    NSArray* columns = @[name,age];
    OPFTable *table = [[OPFTable alloc] initWith:@"person_" columns:columns];
    NSLog(@"建表语句为：%@",[table createTableSQL]);
    return table;
}

+(NSArray *)updateTable:(int)fromVersion toVersion:(int)toVersion{
    //TODO
    return nil;
}

@end
