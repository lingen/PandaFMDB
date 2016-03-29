//
//  OPRepository.m
//  Pods
//
//  Created by lingen on 16/3/21.
//
//

#import "OPFRepository.h"
#import "FMDB.h"
#import "OPFTableProtocol.h"
#import "OPFTable.h"
#import "FMDatabaseQueue+OPH.h"

@interface OPFRepository()

/*
 *数据库路径
 */
@property (nonatomic,strong) NSString* dbPath;

/*
 * 表格定义模型
 */
@property (nonatomic,strong) NSArray* tables;

/*
 *数据库FMDB
 */
@property (nonatomic,strong) FMDatabaseQueue* dbQueue;

/*
 *数据库队列
 */
@property (nonatomic,strong) dispatch_queue_t threadQueue;

/*
 *数据库TAG
 */
@property (nonatomic,strong) NSString* tag;

/*
 *版本号
 */
@property (nonatomic,assign) int version;

@end

//创建版本控制的语句
static NSString* CREATE_VERSION_TABLE = @"CREATE TABLE PANDA_VERSION_ (VALUE_ INT NOT NULL)";

//初始化版本控制的语句
static NSString* INIT_VERSION_TABLE_CONTENT = @"INSERT INTO PANDA_VERSION_ (VALUE_) values (%@)";

//查询当前的版本号
static NSString* QUERY_CURRENT_VERSION = @"SELECT VALUE_ FROM PANDA_VERSION_ LIMIT 1";

//默认的数据库名称
static NSString* DEFAULT_TAG = @"DEFAULT";

@implementation OPFRepository

/*
 *初始化数据库路径以及表格对象
 */
-(instancetype)initWith:(NSString*) dbPath tables:(NSArray*)tables version:(int)version{
    if (self = [super init]) {
        _dbPath = dbPath;
        _tables = tables;
        _version = version;
        _tag = DEFAULT_TAG;
        
        NSString *threadName = [NSString stringWithFormat:@"db.panda.%@",_tag];
        _threadQueue = dispatch_queue_create([threadName UTF8String], NULL);
        [self p_initRepository];
        return self;
    }
    return nil;
}

/*
 *此方法用于初始化数据库及表格
 */
-(void)p_initRepository{
    
    BOOL dbFileExists = [[NSFileManager defaultManager] fileExistsAtPath:_dbPath];
    _dbQueue = [FMDatabaseQueue databaseQueueWithPath:_dbPath];
    
    if (dbFileExists) {
        [self p_updateDB];
        //如果路径都不存在，则表明表格不存在，需要重新创建表格
    }else{
        [self p_initDB];
    }
}

/*
 *数据库初始化操作
 */
-(void)p_initDB{
     dispatch_async(_threadQueue, ^{

         [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
              //创建版本号相关的表
              BOOL success = [db executeStatements:CREATE_VERSION_TABLE];
              if (success) {
                   NSLog(@"Panda Success：初始化数据库，创建版本号表成功");
              }else{
                   NSLog(@"Panda Error：初始化数据库，创建版本号表失败");
                   *rollback = YES;
              }
              //初始化版本号
              success = [db executeStatements:[NSString stringWithFormat:INIT_VERSION_TABLE_CONTENT,@(_version)]];
              
              if (success) {
                   NSLog(@"Panda Success：初始化版本号表成功");
              }else{
                   NSLog(@"Panda Error：初始化版本号表失败");
                   *rollback = YES;
              }
              NSMutableArray *sqls = [[NSMutableArray alloc] init];
              //初始化所有的表
              for (Class tableProtocolClass in _tables) {
                   //进行数据库层的初始化操作
                   if ([tableProtocolClass conformsToProtocol:@protocol(OPFTableProtocol)]) {
                        OPFTable* opfTable = [tableProtocolClass performSelector:@selector(createTable)];
                        //获取建表语句
                        [sqls addObject:[opfTable createTableSQL]];
                        //获取创建索引的语句
                        [sqls addObject:[opfTable createIndexSQL]];
                   }
              }
              
              for (NSString* sql in sqls) {
                   BOOL success =  [db executeStatements:sql];
                   if (success) {
                        NSLog(@"Panda Success:表初始化成功:%@",sql);
                   }else{
                        [self p_strictMode:[db lastError]];
                        NSLog(@"Panda Error:表初始化失败%@",sql);
                        *rollback = YES;
                   }
              }
         }];
          });
}

/*
 *数据库更新操作
 */
-(void)p_updateDB{
    __block int dbVersion = 0;
    dispatch_async(_threadQueue, ^{
        
        [_dbQueue inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:QUERY_CURRENT_VERSION];
            dbVersion = [rs intForColumn:@"VALUE_"];
            if (rs) {
                [rs close];
            }
        }];
        
        NSMutableArray *sqls = [[NSMutableArray alloc] init];
        
        //对于更新，也需要创建不存在的表
        for (Class tableProtocolClass in _tables) {
            //进行数据库层的初始化操作
            if ([tableProtocolClass conformsToProtocol:@protocol(OPFTableProtocol)]) {
                OPFTable* opfTable = [tableProtocolClass performSelector:@selector(createTable)];
                BOOL tableExist = [self p_queryTableExists:opfTable.tableName];
                if (!tableExist) {
                    //获取建表语句
                    [sqls addObject:[opfTable createTableSQL]];
                    //获取创建索引的语句
                    [sqls addObject:[opfTable createIndexSQL]];
                }
            }
        }
        
        //数据库升级行为
        for (int begin = dbVersion; dbVersion <= _version - 1 ; dbVersion++) {
            int end = begin + 1;
            
            //进行表更新操作
            for (Class tableProtocolClass in _tables) {
                //进行数据库层的初始化操作
                if ([tableProtocolClass conformsToProtocol:@protocol(OPFTableProtocol)]) {
                    NSArray* tableSQLs = [tableProtocolClass  performSelector:@selector(updateTable:toVersion:) withObject:@(begin) withObject:@(end)];
                    [sqls addObjectsFromArray:tableSQLs];
                }
            }
            
             [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                  for (NSString* sql in sqls) {
                       BOOL update =   [db executeUpdate:sql];
                       if (!update) {
                            [self p_strictMode:[db lastError]];
                            *rollback = YES;
                            break;
                       }
                  }
             }];
        }
    });
}

#pragma 同步更新方法，单个SQL
/**
 *  同步执行一个是更新操作
 *
 *  @param sql SQL语句
 *
 *  @return 返回是否执行成功
 */
-(BOOL)syncExecuteUpdate:(NSString*)sql{
    
    [self p_checkMainThread];
    

    __block BOOL success = NO;
         [self p_dbWrite:^(FMDatabase *db, BOOL *rollback) {
              [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                   success = [db executeUpdate:sql];

                   if (!success) {
                        [self p_strictMode:[db lastError]];
                        *rollback = YES;
                   }
              }];
         }];
    return success;
}

/**
 *  同步执行一个是更新操作
 *
 *  @param sql  SQL语句
 *  @param args 参数列表
 *
 *  @return 返回是否执行成功
 */
-(BOOL)syncExecuteUpdate:(NSString*)sql withDictionaryArgs:(NSDictionary*)args{
    [self p_checkMainThread];
    
    __block BOOL success = NO;
         [self p_dbWrite:^(FMDatabase *db, BOOL *rollback) {
              success = [db executeUpdate:sql withParameterDictionary:args];
              if (!success) {
                   [self p_strictMode:[db lastError]];
                   *rollback = YES;
              }
         }];
    return success;
}

/**
 *  同步执行一个是更新操作
 *
 *  @param sql  SQL语句
 *  @param args 参数列表
 *
 *  @return 返回是否执行成功
 */
-(BOOL)syncExecuteUpdate:(NSString*)sql withArrayArgs:(NSArray*)args{
    [self p_checkMainThread];
    
    __block BOOL success = NO;
         [self p_dbWrite:^(FMDatabase *db, BOOL *rollback) {
              success = [db executeUpdate:sql withArgumentsInArray:args];
              if (!success) {
                   [self p_strictMode:[db lastError]];
                   *rollback = YES;
              }
         }];
    return success;
}

#pragma 异步更新方法，单个SQL
/**
 *  异步执行一个更新操作
 *
 *  @param sql         SQL语句
 *  @param resultBlock 异步回调值
 */
-(void)asyncExecuteUpdate:(NSString*)sql resultBlock:(void(^)(BOOL result))resultBlock{
    dispatch_async(_threadQueue, ^{
         [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
              BOOL success = [db executeUpdate:sql];
              if (!success) {
                   [self p_strictMode:[db lastError]];
                   *rollback = YES;
              }
              if (resultBlock) {
                   resultBlock(success);
              }

         }];
    });
}

/**
 *  异步执行一个更新操作
 *
 *  @param sql         SQL语句
 *  @param args        参数列表
 *  @param resultBlock 异步回调值
 */
-(void)asyncExecuteUpdate:(NSString*)sql withDictionaryArgs:(NSDictionary*)args resultBlock:(void(^)(BOOL result))resultBlock{
    dispatch_async(_threadQueue, ^{
         [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
              BOOL success = [db executeUpdate:sql withParameterDictionary:args];
              if (!success) {
                   [self p_strictMode:[db lastError]];
                   *rollback = YES;
              }
              if (resultBlock) {
                   resultBlock(success);
              }
         }];
    });
}

/**
 *  异步执行一个更新操作
 *
 *  @param sql         SQL语句
 *  @param args        参数列表
 *  @param resultBlock 异步回调值
 */
-(void)asyncExecuteUpdate:(NSString*)sql withArrayArgs:(NSArray*)args resultBlock:(void(^)(BOOL result))resultBlock{
    dispatch_async(_threadQueue, ^{
         [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
              BOOL success = [db executeUpdate:sql withArgumentsInArray:args];
              if (!success) {
                   [self p_strictMode:[db lastError]];
                   *rollback = YES;
              }
              if (resultBlock) {
                   resultBlock(success);
              }
         }];
    });
}

#pragma 同步更新方法，多个SQL
/**
 *  执行一系列的SQL操作
 *
 *  @param sqls SQL语句集合
 *
 *  @return 返回成功或失败，只有所有的成功才会成功
 */
-(BOOL)syncExecuteUpdates:(NSArray *)sqls{
    [self p_checkMainThread];
    
    __block BOOL success = NO;
         [self p_dbWrite:^(FMDatabase *db, BOOL *rollback) {
              for (NSString* sql in sqls) {
                   BOOL success = [db executeUpdate:sql];
                   if (!success) {
                        [self p_strictMode:[db lastError]];
                        success = NO;
                        *rollback = YES;
                        return ;
                   }
              }
              success = YES;
         }];
    return success;
}

/**
 *  执行一系列的SQL操作
 *
 *  @param sqls SQL语句集合
 *  @param args 对应的参数列表，有多少个SQL，就必须有多少个参数列表
 *
 *  @return 返回成功或失败，只有所有的成功才会成功
 */
-(BOOL)syncExecuteUpdates:(NSArray *)sqls withDictionaryArgs:(NSArray*)args{
    [self p_checkMainThread];
    
    __block BOOL success = NO;
         [self p_dbWrite:^(FMDatabase *db, BOOL *rollback) {
              for (int i =0;i<sqls.count;i++) {
                   NSString* sql  = sqls[i];
                   NSDictionary* params = args[i];
                   BOOL success = [db executeUpdate:sql withParameterDictionary:params];
                   if (!success) {
                        [self p_strictMode:[db lastError]];
                        success = NO;
                        *rollback = YES;
                        return ;
                   }
              }
              success = YES;
         }];
    return success;
}

/**
 *  将BLOCK里的数据库操作，全部归纳到一个事务中去
 *
 *  @param dbBlock BLOC行为
 *
 *  @return 返回是否成功
 */
-(void)syncInTransaction:(void(^)(BOOL *rollback))dbBlock{
     NSDate* tmpStartData = [NSDate date];
     
     BOOL inTransaction = [_dbQueue isInTransaction];
     if (!inTransaction) {
          dispatch_sync(_threadQueue, ^{
               [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                    dbBlock(&*rollback);
               }];
          });
     }else{
          [_dbQueue inWrtite:^(FMDatabase *db, BOOL *rollback) {
               dbBlock(&*rollback);
          }];
     }
     double deltaTime = [[NSDate date] timeIntervalSinceDate:tmpStartData];
     NSLog(@"数据库耗时 %f", deltaTime);


}

/**
 *  执行一系列的SQL操作
 *
 *  @param sqls SQL语句集合
 *  @param args 对应的参数列表，有多少个SQL，就必须有多少个参数列表
 *
 *  @return 返回成功或失败，只有所有的成功才会成功
 */
-(BOOL)syncExecuteUpdates:(NSArray *)sqls withArrayArgs:(NSArray*)args{
    [self p_checkMainThread];
    
    __block BOOL success = NO;
     
     
         [self p_dbWrite:^(FMDatabase *db, BOOL *rollback) {
              for (int i =0;i<sqls.count;i++) {
                   NSString* sql  = sqls[i];
                   NSArray* params = args[i];
                   BOOL success = [db executeUpdate:sql withArgumentsInArray:params];
                   if (!success) {
                        [self p_strictMode:[db lastError]];
                        success = NO;
                        *rollback = YES;
                        return ;
                   }
              }
              success = YES;
         }];

    return success;
}

#pragma 异步更新方法，多个SQL
/**
 *  异步执行一系列的SQL语句
 *
 *  @param sqls        SQL语句集合
 *  @param resultBlock 执行结果回调，只有所有的语句全部执行成功才会返回成功
 */
-(void)asyncExecuteUpdates:(NSArray *)sqls resultBlock:(void(^)(BOOL result))resultBlock{
    [self p_checkMainThread];
    
    dispatch_async(_threadQueue, ^{
         [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
              BOOL success = NO;
              for (NSString* sql in sqls) {
                   BOOL success = [db executeUpdate:sql];
                   if (!success) {
                        [self p_strictMode:[db lastError]];
                        success = NO;
                        *rollback = YES;
                        return ;
                   }
              }
              success = YES;
              
              if (resultBlock) {
                   resultBlock(success);
              }
         }];
    });
}


/**
 *  异步执行一系列的SQL语句
 *
 *  @param sqls        SQL语句集合
 *  @param args        参数列表集合
 *  @param resultBlock 执行结果回调，只有所有的语句全部执行成功才会返回成功
 */
-(void)asyncExecuteUpdates:(NSArray *)sqls withDictionaryArgs:(NSArray*)args resultBlock:(void(^)(BOOL result))resultBlock{
    
    dispatch_async(_threadQueue, ^{
         [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
              BOOL success = NO;
              for (int i =0;i<sqls.count;i++) {
                   NSString* sql  = sqls[i];
                   NSDictionary* params = args[i];
                   BOOL success = [db executeUpdate:sql withParameterDictionary:params];
                   if (!success) {
                        [self p_strictMode:[db lastError]];
                        success = NO;
                        *rollback = YES;
                        return ;
                   }
              }
              success = YES;
              if (resultBlock) {
                   resultBlock(success);
              }
         }];
    });
    
}

/**
 *  异步执行一系列的SQL语句
 *
 *  @param sqls        SQL语句集合
 *  @param args        参数列表集合
 *  @param resultBlock 执行结果回调，只有所有的语句全部执行成功才会返回成功
 */
-(void)asyncExecuteUpdates:(NSArray *)sqls withArrayArgs:(NSArray*)args resultBlock:(void(^)(BOOL result))resultBlock{
    
    dispatch_async(_threadQueue, ^{
         [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
              BOOL success = NO;
              for (int i =0;i<sqls.count;i++) {
                   NSString* sql  = sqls[i];
                   NSArray* params = args[i];
                   BOOL success = [db executeUpdate:sql withArgumentsInArray:params];
                   if (!success) {
                        [self p_strictMode:[db lastError]];
                        success = NO;
                        return ;
                   }
              }
              success = YES;
              if (resultBlock) {
                   resultBlock(success);
              }
         }];
    });
    
}
#pragma 同步查询
/**
 *  同步执行一个查询
 *
 *  @param sql 查询SQL
 *
 *  @return 返回查询结果，结果为NSArray，Array里面为NSDictionary
 */
-(NSArray*)syncExecuteQuery:(NSString*)sql{
    [self p_checkMainThread];
    
    __block NSMutableArray *results = [[NSMutableArray alloc] init];
     [self p_dbRead:^(FMDatabase *db) {
          FMResultSet * rs = [db executeQuery:sql];
          while (rs.next) {
               NSDictionary* data = [self p_rsToNSDictionary:rs];
               if (data) {
                    [results addObject:data];
               }
          }
          if ([db lastError]) {
               [self p_strictMode:[db lastError]];
          }
          if (rs) {
               [rs close];
          }
     }];
    return results;
}

/**
 *  同步执行一个查询
 *
 *  @param sql  查询SQL
 *  @param args 参数列表
 *
 *  @return 返回查询结果 ，结果为NSArray，Array里面为NSDictionary，是数据库的键值对
 */
-(NSArray*)syncExecuteQuery:(NSString*)sql withDictionaryArgs:(NSDictionary*)args{
    
    [self p_checkMainThread];
    
    __block NSMutableArray *results = [[NSMutableArray alloc] init];
     [self p_dbRead:^(FMDatabase *db) {
               FMResultSet * rs = [db executeQuery:sql withParameterDictionary:args];
               while (rs.next) {
                    NSDictionary* data = [self p_rsToNSDictionary:rs];
                    if (data) {
                         [results addObject:data];
                    }
               }
          if ([db lastError]) {
               [self p_strictMode:[db lastError]];
          }
               if (rs) {
                    [rs close];
               }
     }];
    return results;
}

/**
 *  同步执行一个查询
 *
 *  @param sql  查询SQL
 *  @param args 参数列表
 *
 *  @return 返回查询结果 ，结果为NSArray,Array里面为NSDictionary，是数据库的键值对
 */
-(NSArray*)syncExecuteQuery:(NSString*)sql withArrayArgs:(NSArray*)args{
    [self p_checkMainThread];
    
    __block NSMutableArray *results = [[NSMutableArray alloc] init];
     [self p_dbRead:^(FMDatabase *db) {
               FMResultSet * rs = [db executeQuery:sql withArgumentsInArray:args];
               while (rs.next) {
                    NSDictionary* data = [self p_rsToNSDictionary:rs];
                    if (data) {
                         [results addObject:data];
                    }
               }
          [self p_strictMode:[db lastError]];
               if (rs) {
                    [rs close];
               }
     }];
    return results;
}


#pragma 同步查询，单例
/**
 *  单例查询，当SQL语句仅返回一条数据时使用此方法
 *
 *  @param sql 查询SQL
 *
 *  @return 返回NSDictionary
 */
-(NSDictionary*)syncSingleExecuteQuery:(NSString*)sql{
    [self p_checkMainThread];
    
    __block NSDictionary* result = nil;
     [self p_dbRead:^(FMDatabase *db) {
               FMResultSet * rs = [db executeQuery:sql];
               if (rs.next) {
                    result = [self p_rsToNSDictionary:rs];
               }
         [self p_strictMode:[db lastError]];
               if (rs) {
                    [rs close];
               }
     }];
    return result;
}

/**
 *  单例查询，当SQL语句仅返回一条数据时使用此方法
 *
 *  @param sql  SQL语句
 *  @param args 参数列表
 *
 *  @return 返回一个NSDictionary
 */
-(NSDictionary*)syncSingleExecuteQuery:(NSString*)sql withDictionaryArgs:(NSDictionary*)args{
    [self p_checkMainThread];
    
    __block NSDictionary* result = nil;
     [self p_dbRead:^(FMDatabase *db) {
               FMResultSet * rs = [db executeQuery:sql withParameterDictionary:args];
               if (rs.next) {
                    result = [self p_rsToNSDictionary:rs];
               }
          [self p_strictMode:[db lastError]];
               if (rs) {
                    [rs close];
               }
     }];
    return result;
}

/**
 *  同步单例查询，当SQL语句仅返回一条数据时使用此方法
 *
 *  @param sql  SQL语句
 *  @param args 参数列表
 *
 *  @return 返回查询结果 ，结果为NSDictionary
 */
-(NSDictionary*)syncSingleExecuteQuery:(NSString*)sql withArrayArgs:(NSArray*)args{
    [self p_checkMainThread];
    
    __block NSDictionary* result = nil;
     [self p_dbRead:^(FMDatabase *db) {
               FMResultSet * rs = [db executeQuery:sql withArgumentsInArray:args];
               if (rs.next) {
                    result = [self p_rsToNSDictionary:rs];
               }
          [self p_strictMode:[db lastError]];
               if (rs) {
                    [rs close];
               }
     }];
    return result;
}

#pragma 同步查询，返回对象
/**
 *  同步查询，返回Model集合
 *
 *  @param sql            SQL语句
 *  @param convertBlock 用户提供NSDictionary到对象的整合block
 *
 *  @return 返回一个数组，数组中为对象
 */
-(NSArray*)syncExecuteQuery:(NSString*)sql convertBlock:(id(^)(NSDictionary * result))convertBlock{
    [self p_checkMainThread];
    
    NSMutableArray* results = [[NSMutableArray alloc] init];
     [self p_dbRead:^(FMDatabase *db) {
               FMResultSet * rs = [db executeQuery:sql];
               while (rs.next) {
                    NSDictionary* data = [self p_rsToNSDictionary:rs];
                    if (data) {
                         [results addObject:convertBlock(data)];
                    }
               }
          [self p_strictMode:[db lastError]];
               if (rs) {
                    [rs close];
               }
     }];
    return results;
}


/**
 *  同步查询，返回Model集合
 *
 *  @param sql          SQL语句
 *  @param args         参数列表
 *  @param convertBlock 用户提供NSDictionary到对象的整合block
 *
 *  @return 返回一个数组，数组中为对象
 */
-(NSArray*)syncExecuteQuery:(NSString *)sql withDictionaryArgs:(NSDictionary*)args convertBlock:(id (^)(NSDictionary* result))convertBlock{
    [self p_checkMainThread];
    
    NSMutableArray* results = [[NSMutableArray alloc] init];
     [self p_dbRead:^(FMDatabase *db) {
               FMResultSet * rs = [db executeQuery:sql withParameterDictionary:args];
               while (rs.next) {
                    NSDictionary* data = [self p_rsToNSDictionary:rs];
                    if (data) {
                         [results addObject:convertBlock(data)];
                    }
               }
          [self p_strictMode:[db lastError]];
               if (rs) {
                    [rs close];
               }
     }];
    return results;
    
}

/**
 *  同步查询，返回Model集合
 *
 *  @param sql          SQL语句
 *  @param args         参数列表
 *  @param convertBlock 用户提供NSDictionary到对象的整合block
 *
 *  @return 返回一个数组，数组中为对象
 */
-(NSArray*)syncExecuteQuery:(NSString *)sql withArraysArgs:(NSArray*)args convertBlock:(id (^)(NSDictionary* result))convertBlock{
    NSMutableArray* results = [[NSMutableArray alloc] init];
    [self p_checkMainThread];
    
     [self p_dbRead:^(FMDatabase *db) {
               FMResultSet * rs = [db executeQuery:sql withArgumentsInArray:args];
               while (rs.next) {
                    NSDictionary* data = [self p_rsToNSDictionary:rs];
                    if (data) {
                         [results addObject:convertBlock(data)];
                    }
               }
          [self p_strictMode:[db lastError]];
               if (rs) {
                    [rs close];
               }
     }];
    return results;
}


#pragma 同步查询，对象且单例
/**
 *  同步查询，返回Model集合
 *
 *  @param sql            SQL语句
 *  @param convertBlock 用户提供NSDictionary到对象的整合block
 *
 *  @return 返回一个对象
 */
-(id)syncSingleExecuteQuery:(NSString*)sql convertBlock:(id(^)(NSDictionary * result))convertBlock{
    [self p_checkMainThread];
    
   __block id result = nil;
     [self p_dbRead:^(FMDatabase *db) {
               FMResultSet * rs = [db executeQuery:sql];
               if (rs.next) {
                    NSDictionary* data = [self p_rsToNSDictionary:rs];
                    result = convertBlock(data);
               }
          [self p_strictMode:[db lastError]];
               if (rs) {
                    [rs close];
               }
     }];
    return result;
}


/**
 *  同步查询，返回Model集合
 *
 *  @param sql          SQL语句
 *  @param args         参数列表
 *  @param convertBlock 用户提供NSDictionary到对象的整合block
 *
 *  @return 返返回一个对象
 */
-(id)syncSingleExecuteQuery:(NSString *)sql withDictionaryArgs:(NSDictionary*)args convertBlock:(id (^)(NSDictionary* result))convertBlock{
    [self p_checkMainThread];
    
    __block id result = nil;
     [self p_dbRead:^(FMDatabase *db) {
               FMResultSet * rs = [db executeQuery:sql withParameterDictionary:args];
               if (rs.next) {
                    NSDictionary* data = [self p_rsToNSDictionary:rs];
                    result = convertBlock(data);
               }
          [self p_strictMode:[db lastError]];
               if (rs) {
                    [rs close];
               }
     }];
    return result;
    
}

/**
 *  同步查询，返回Model集合
 *
 *  @param sql          SQL语句
 *  @param args         参数列表
 *  @param convertBlock 用户提供NSDictionary到对象的整合block
 *
 *  @return 返回一个对象
 */
-(id)syncSingleExecuteQuery:(NSString *)sql withArraysArgs:(NSArray*)args convertBlock:(id (^)(NSDictionary* result))convertBlock{
    [self p_checkMainThread];
    __block id result = nil;
     [self p_dbRead:^(FMDatabase *db) {
               FMResultSet * rs = [db executeQuery:sql withArgumentsInArray:args];
               if (rs.next) {
                    NSDictionary* data = [self p_rsToNSDictionary:rs];
                    result = convertBlock(data);
               }
          [self p_strictMode:[db lastError]];
               if (rs) {
                    [rs close];
               }
     }];
    return result;
    
}


#pragma 异步查询,Dictionary
/**
 *  异步执行查询
 *
 *  @param sql         语句SQL
 *  @param resultBlock result回调，回调返回NSArray，NSArray中为NSDictionary
 */
-(void)asyncExecuteQuery:(NSString*)sql resultBlock:(void(^)(NSArray*))resultBlock{
    dispatch_async(_threadQueue, ^{
        [_dbQueue inDatabase:^(FMDatabase *db) {
            NSMutableArray* results = [[NSMutableArray alloc] init];
            FMResultSet *rs = [db executeQuery:sql];
            while (rs.next) {
                NSDictionary* data = [self p_rsToNSDictionary:rs];
                if (data) {
                    [results addObject:data];
                }
            }
             [self p_strictMode:[db lastError]];
            if (rs) {
                [rs close];
            }
            if (resultBlock) {
                resultBlock(results);
            }
        }];
    });
}

/**
 *  异步执行查询
 *
 *  @param sql         语句SQL
 *  @param args        参数列表
 *  @param resultBlock result回调，回调返回NSArray，NSArray中为NSDictionary
 */
-(void)asyncExecuteQuery:(NSString *)sql withDictionaryArgs:(NSDictionary*)args resultBlock:(void (^)(NSArray* result))resultBlock{
    dispatch_async(_threadQueue, ^{
        [_dbQueue inDatabase:^(FMDatabase *db) {
            NSMutableArray* results = [[NSMutableArray alloc] init];
            FMResultSet *rs = [db executeQuery:sql withParameterDictionary:args];
            while (rs.next) {
                NSDictionary* data = [self p_rsToNSDictionary:rs];
                if (data) {
                    [results addObject:data];
                }
            }
             [self p_strictMode:[db lastError]];
            if (rs) {
                [rs close];
            }
            if (resultBlock) {
                resultBlock(results);
            }
        }];
    });
}

/**
 *  异步执行查询
 *
 *  @param sql         语句SQL
 *  @param args        参数列表
 *  @param resultBlock result回调，回调返回NSArray，NSArray中为NSDictionary
 */
-(void)asyncExecuteQuery:(NSString *)sql withArrayArgs:(NSArray*)args resultBlock:(void (^)(NSArray* result))resultBlock{
    dispatch_async(_threadQueue, ^{
        [_dbQueue inDatabase:^(FMDatabase *db) {
            NSMutableArray* results = [[NSMutableArray alloc] init];
            FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
            while (rs.next) {
                NSDictionary* data = [self p_rsToNSDictionary:rs];
                if (data) {
                    [results addObject:data];
                }
            }
             [self p_strictMode:[db lastError]];
            if (rs) {
                [rs close];
            }
            if (resultBlock) {
                resultBlock(results);
            }
        }];
    });
}

#pragma 异步查询，单例

/**
 *  异步执行查询
 *
 *  @param sql         语句SQL
 *  @param resultBlock result回调，回调返回NSDictionary
 */
-(void)asyncSingleExecuteQuery:(NSString*)sql resultBlock:(void(^)(NSDictionary* result))resultBlock{
    dispatch_async(_threadQueue, ^{
        [_dbQueue inDatabase:^(FMDatabase *db) {
            NSDictionary* result = [[NSDictionary alloc] init];
            FMResultSet *rs = [db executeQuery:sql];
            if (rs.next) {
                result = [self p_rsToNSDictionary:rs];
            }
             [self p_strictMode:[db lastError]];
            if (rs) {
                [rs close];
            }
            if (resultBlock) {
                resultBlock(result);
            }
        }];
    });
}

/**
 *  异步执行查询
 *
 *  @param sql         语句SQL
 *  @param args        参数列表
 *  @param resultBlock result回调，回调返回NSDictionary
 */
-(void)asyncSingleExecuteQuery:(NSString *)sql withDictionaryArgs:(NSDictionary*)args resultBlock:(void (^)(NSDictionary* result))resultBlock{
    dispatch_async(_threadQueue, ^{
        [_dbQueue inDatabase:^(FMDatabase *db) {
            NSDictionary* result = nil;
            FMResultSet *rs = [db executeQuery:sql withParameterDictionary:args];
            if (rs.next) {
                result = [self p_rsToNSDictionary:rs];
            }
            [self p_strictMode:[db lastError]];
            if (rs) {
                [rs close];
            }
            if (resultBlock) {
                resultBlock(result);
            }
        }];
    });
}

/**
 *  异步执行查询
 *
 *  @param sql         语句SQL
 *  @param args        参数列表
 *  @param resultBlock result回调，回调返回NSDictionary
 */
-(void)asyncSingleExecuteQuery:(NSString *)sql withArrayArgs:(NSArray*)args resultBlock:(void (^)(NSDictionary* result))resultBlock{
    dispatch_async(_threadQueue, ^{
        [_dbQueue inDatabase:^(FMDatabase *db) {
            NSDictionary* result = nil;
            FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
            if (rs.next) {
                result = [self p_rsToNSDictionary:rs];
            }
             [self p_strictMode:[db lastError]];
            if (rs) {
                [rs close];
            }
            if (resultBlock) {
                resultBlock(result);
            }
        }];
    });
}

#pragma 异步查询，NSDictionary
/**
 *  异步查询，返回对象集合
 *
 *  @param sql          SQL语句
 *  @param convertBlock NSDictionary转成id对象的Block
 *  @param resultBlock  返回Block,结果为NSArray的ID对象集合
 */
-(void)asyncExecuteQuery:(NSString*)sql convertBlock:(id(^)(NSDictionary*))convertBlock resultBlock:(void(^)(NSArray*))resultBlock{
    dispatch_async(_threadQueue, ^{
        [_dbQueue inDatabase:^(FMDatabase *db) {
            NSMutableArray* results = [[NSMutableArray alloc] init];
            FMResultSet *rs = [db executeQuery:sql];
            while (rs.next) {
                NSDictionary* data = [self p_rsToNSDictionary:rs];
                if (data) {
                    [results addObject:data];
                }
            }
             [self p_strictMode:[db lastError]];
            if (rs) {
                [rs close];
            }
            if (resultBlock) {
                resultBlock(results);
            }
        }];
    });
}

/**
 *  异步查询，返回对象集合
 *
 *  @param sql          SQL语句
 *  @param args         参数列表
 *  @param convertBlock NSDictionary转成id对象的Block
 *  @param resultBlock  返回Block,结果为NSArray的ID对象集合
 */
-(void)asyncExecuteQuery:(NSString*)sql withDictionaryArgs:(NSDictionary*)args convertBlock:(id(^)(NSDictionary*))convertBlock resultBlock:(void(^)(NSArray*))resultBlock{
    
    dispatch_async(_threadQueue, ^{
        [_dbQueue inDatabase:^(FMDatabase *db) {
            NSMutableArray* results = [[NSMutableArray alloc] init];
            FMResultSet *rs = [db executeQuery:sql withParameterDictionary:args];
            while (rs.next) {
                NSDictionary* data = [self p_rsToNSDictionary:rs];
                if (data) {
                    [results addObject:data];
                }
            }
             [self p_strictMode:[db lastError]];
            if (rs) {
                [rs close];
            }
            if (resultBlock) {
                resultBlock(results);
            }
        }];
    });
    
}
/**
 *  异步查询，返回对象集合
 *
 *  @param sql          SQL语句
 *  @param args         参数列表
 *  @param convertBlock NSDictionary转成id对象的Block
 *  @param resultBlock  返回Block,结果为NSArray的ID对象集合
 */
-(void)asyncExecuteQuery:(NSString*)sql withArrayArgs:(NSArray*)args convertBlock:(id(^)(NSDictionary*))convertBlock resultBlock:(void(^)(NSArray*))resultBlock{
    
    dispatch_async(_threadQueue, ^{
        [_dbQueue inDatabase:^(FMDatabase *db) {
            NSMutableArray* results = [[NSMutableArray alloc] init];
            FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
            while (rs.next) {
                NSDictionary* data = [self p_rsToNSDictionary:rs];
                if (data) {
                    [results addObject:data];
                }
            }
            [self p_strictMode:[db lastError]];
            if (rs) {
                [rs close];
            }
            if (resultBlock) {
                resultBlock(results);
            }
        }];
    });
    
}

#pragma 异步查询，单例
/**
 *  异步单例查询
 *
 *  @param sql          SQL语句
 *  @param convertBlock NSDictionary转成id对象的Block
 *  @param resultBlock  返回Block,结果为ID
 */
-(void)asyncSingleExecuteQuery:(NSString*)sql convertBlock:(id(^)(NSDictionary*))convertBlock resultBlock:(void(^)(id))resultBlock{
    dispatch_async(_threadQueue, ^{
        [_dbQueue inDatabase:^(FMDatabase *db) {
            id result = nil;
            FMResultSet *rs = [db executeQuery:sql];
            if (rs.next) {
                NSDictionary* data = [self p_rsToNSDictionary:rs];
                result = convertBlock(data);
            }
             [self p_strictMode:[db lastError]];
            if (rs) {
                [rs close];
            }
            if (resultBlock) {
                resultBlock(result);
            }
        }];
    });
}

/**
 *  异步单例查询
 *
 *  @param sql          SQL语句
 *  @param args         参数列表
 *  @param convertBlock NSDictionary转成id对象的Block
 *  @param resultBlock  返回Block,结果为ID
 */
-(void)asyncSingleExecuteQuery:(NSString*)sql withDictionaryArgs:(NSDictionary*)args convertBlock:(id(^)(NSDictionary*))convertBlock resultBlock:(void(^)(id))resultBlock{
    dispatch_async(_threadQueue, ^{
        [_dbQueue inDatabase:^(FMDatabase *db) {
            id result = nil;
            FMResultSet *rs = [db executeQuery:sql withParameterDictionary:args];
            if (rs.next) {
                NSDictionary* data = [self p_rsToNSDictionary:rs];
                result = convertBlock(data);
            }
             [self p_strictMode:[db lastError]];
            if (rs) {
                [rs close];
            }
            if (resultBlock) {
                resultBlock(result);
            }
        }];
    });
}
/**
 *  异步单例查询
 *
 *  @param sql          SQL语句
 *  @param args         参数列表
 *  @param convertBlock NSDictionary转成id对象的Block
 *  @param resultBlock  返回Block,结果为ID
 */
-(void)asyncSingleExecuteQuery:(NSString*)sql withArrayArgs:(NSArray*)args convertBlock:(id(^)(NSDictionary*))convertBlock resultBlock:(void(^)(id))resultBlock{
    
    dispatch_async(_threadQueue, ^{
        [_dbQueue inDatabase:^(FMDatabase *db) {
            id result = nil;
            FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
            if (rs.next) {
                NSDictionary* data = [self p_rsToNSDictionary:rs];
                result = convertBlock(data);
            }
             [self p_strictMode:[db lastError]];
            if (rs) {
                [rs close];
            }
            if (resultBlock) {
                resultBlock(result);
            }
        }];
    });
}


/**
 *  查询数据库中某个表是否存在
 *
 *  @param tableName 表名
 *
 *  @return 返回结果
 */
-(BOOL)syncQueryTableExists:(NSString*)tableName{
    [self p_checkMainThread];
     __block BOOL exists = NO;
     dispatch_sync(_threadQueue, ^{
          exists =[self p_queryTableExists:tableName];
     });
    return [self p_queryTableExists:tableName];
}

-(BOOL)p_queryTableExists:(NSString*)tableName{
     __block BOOL exists = NO;

    NSString* sql = @"SELECT count(*) FROM sqlite_master WHERE type='table' AND name=? ";
        [_dbQueue inDatabase:^(FMDatabase *db) {
            FMResultSet *rs  = [db executeQuery:sql withArgumentsInArray:@[tableName]];
            if (rs.next) {
                exists = YES;
            }
            if (rs) {
                [rs close];
            }
        }];
    return exists;
}

/**
 *  异步查询表是否存在
 *
 *  @param tableName   表名
 *  @param resultBlock 回调
 *
 */
-(void)syncQueryTableExists:(NSString*)tableName resultBlock:(void(^)(BOOL success))resultBlock{
    if (!resultBlock) {
        return;
    }
    
     [self p_dbRead:^(FMDatabase *db) {
          NSString* sql = @"SELECT count(*) FROM sqlite_master WHERE type='table' AND name=? ";
          FMResultSet *rs  = [db executeQuery:sql withArgumentsInArray:@[tableName]];
          if (rs.next) {
               resultBlock(YES);
          }else{
               resultBlock(NO);
          }
          if (rs) {
               [rs close];
          }

     }];
}

#pragma FMResultSet 转 NSDictionary

/**
 *  将RS转为Dictionary
 *
 *  @param rs RS
 *
 *  @return 返回NSDictionary对象
 */
-(NSDictionary*)p_rsToNSDictionary:(FMResultSet*)rs{
    NSMutableDictionary * results = [[NSMutableDictionary alloc] init];
    
    NSMutableDictionary *keys = rs.columnNameToIndexMap;
    for (NSString* name in keys.allKeys) {
        id value = [rs objectForColumnName:name];
        if (value) {
            [results setObject:value forKey:name];
        }
    }
    return results;
}

/**
 *  检查是否在主线程进行操作
 */
-(void)p_checkMainThread{
    BOOL isMainThread = [NSThread isMainThread];
    if (isMainThread) {
        [NSException raise:@"db main thread exception" format:@"DB Actions Not Allow in Main Thread"];
    }
}

-(void)p_dbWrite:(void (^)(FMDatabase *db, BOOL *rollback))block{
     BOOL inTransaction = [_dbQueue isInTransaction];

     if (inTransaction) {
          [_dbQueue inWrtite:^(FMDatabase *db, BOOL *rollback) {
               block(db,&*rollback);
          }];
     }else{
          dispatch_sync(_threadQueue, ^{
               [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                    block(db,&*rollback);
               }];
          });
     }
}

-(void)p_dbRead:(void (^)(FMDatabase *db))block{
     BOOL inTransaction = [_dbQueue isInTransaction];
     
     if (inTransaction) {
          [_dbQueue inReader:^(FMDatabase *db) {
               block(db);
          }];
     }else{
          dispatch_sync(_threadQueue, ^{
               [_dbQueue inDatabase:^(FMDatabase *db) {
                    block(db);
               }];
          });
     }
}

/**
 *  严格模式的行为
 */
-(void)p_strictMode:(NSError*)error{
     if (error.code ==0 ) {
          return;
     }
     NSString* errorString = [NSString stringWithFormat:@"%@:%@",@"StrictMode DB Error:",error.domain];
     if (_strictMode) {
          [NSException raise:@"db Error" format:@"StrictMode DB Error:%@",errorString];
     }
     
#ifdef DEBUG
     [NSException raise:@"db Error" format:@"DeBug DB Error:%@",errorString];
#endif
}

@end
