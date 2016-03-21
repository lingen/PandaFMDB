//
//  OPRepository.m
//  Pods
//
//  Created by lingen on 16/3/21.
//
//

#import "OPRepository.h"
#import "FMDB.h"
#import "OPTableProtocol.h"

@interface OPRepository()

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
static NSString* INIT_VERSION_TABLE_CONTENT = @"INSERT INTO PANDA_VERSION_ (VALUE_) values (0)";

//查询当前的版本号
static NSString* QUERY_CURRENT_VERSION = @"SELECT VALUE_ FROM PANDA_VERSION_ LIMIT 1";

//默认的数据库名称
static NSString* DEFAULT_TAG = @"DEFAULT";

@implementation OPRepository

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
    //如果路径都不存在，则表明表格不存在，需要重新创建表格
    if ([[NSFileManager defaultManager] fileExistsAtPath:_dbPath]) {
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:_dbPath];
        
        dispatch_sync(_threadQueue, ^{
            [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                //创建版本号相关的表
                [db executeStatements:CREATE_VERSION_TABLE];
                //初始化版本号
                [db executeStatements:INIT_VERSION_TABLE_CONTENT];
                
                //初始化所有的表
                for (Class tableProtocolClass in _tables) {
                    //进行数据库层的初始化操作
                    if ([tableProtocolClass conformsToProtocol:@protocol(OPTableProtocol)]) {
                        [tableProtocolClass  performSelector:@selector(initTable)];
                    }
                    
                }
            }];
        });
        //创建Version表，初始化Vresion表，并获取升级版本记录
    }else{
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:_dbPath];
        
        __block int dbVersion = 0;
        dispatch_sync(_threadQueue, ^{
            
            [_dbQueue inDatabase:^(FMDatabase *db) {
                FMResultSet *rs = [db executeQuery:QUERY_CURRENT_VERSION];
                dbVersion = [rs intForColumn:@"VALUE_"];
                [rs close];
            }];
            
            //数据库升级行为
            for (int begin = dbVersion; dbVersion <= _version - 1 ; dbVersion++) {
                int end = begin + 1;
                
                NSMutableArray *sqls = [[NSMutableArray alloc] init];
                //初始化所有的表
                for (Class tableProtocolClass in _tables) {
                    //进行数据库层的初始化操作
                    if ([tableProtocolClass conformsToProtocol:@protocol(OPTableProtocol)]) {
                        NSArray* tableSQLs = [tableProtocolClass  performSelector:@selector(updateTable:toVersion:) withObject:@(begin) withObject:@(end)];
                        [sqls addObjectsFromArray:tableSQLs];
                    }
                }
                
                dispatch_sync(_threadQueue, ^{
                    [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                        for (NSString* sql in sqls) {
                            [db executeUpdate:sql];
                        }
                    }];
                });
            }
            
        });
    }
}

#pragma 数据库执行操作的主方法

#pragma Version功能
@end
