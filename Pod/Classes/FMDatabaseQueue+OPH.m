//
//  FMDatabaseQueue+OPH.m
//  AtWork2
//
//  Created by lingen on 16/3/26.
//  Copyright © 2016年 Foreveross. All rights reserved.
//

#import "FMDatabaseQueue+OPH.h"
#import <FMDatabase.h>


@implementation FMDatabaseQueue (OPH)


/**
 *  当前是否在事务中
 *
 *  @return 返回是否在事务中
 */
-(BOOL)isInTransaction{
     return [_db inTransaction];
}

- (void)inWrtite:(void (^)(FMDatabase *db, BOOL *rollback))block{
     BOOL shouldRollback = NO;
     block(_db,&shouldRollback);
}

- (void)inReader:(void (^)(FMDatabase *db))block{
     block(_db);
}
@end
