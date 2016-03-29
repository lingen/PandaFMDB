//
//  FMDatabaseQueue+OPH.h
//  AtWork2
//
//  Created by lingen on 16/3/26.
//  Copyright © 2016年 Foreveross. All rights reserved.
//

#import <FMDB/FMDB.h>

@interface FMDatabaseQueue (OPH)
/**
 *  当前是否在事务中
 *
 *  @return 返回是否在事务中
 */
-(BOOL)isInTransaction;

- (void)inWrtite:(void (^)(FMDatabase *db, BOOL *rollback))block;

- (void)inReader:(void (^)(FMDatabase *db))block;


@end
