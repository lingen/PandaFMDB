//
//  OPRepository.h
//  Pods
//
//  Created by lingen on 16/3/21.
//
//

#import <Foundation/Foundation.h>
#import "OPFTableProtocol.h"


@interface OPFRepository : NSObject

/**
 *  OPRepository初始化方法
 *
 *  @param dbPath  数据库路径
 *  @param tables  数据库表格定义
 *  @param version 数据库初始版本
 *
 *  @return OPRepository的实例
 */
-(instancetype)initWith:(NSString*) dbPath tables:(NSArray*)tables version:(int)version;


#pragma 同步更新方法，单个SQL
/**
 *  同步执行一个是更新操作
 *
 *  @param sql SQL语句
 *
 *  @return 返回是否执行成功
 */
-(BOOL)syncExecuteUpdate:(NSString*)sql;

/**
 *  同步执行一个是更新操作
 *
 *  @param sql  SQL语句
 *  @param args 参数列表
 *
 *  @return 返回是否执行成功
 */
-(BOOL)syncExecuteUpdate:(NSString*)sql withDictionaryArgs:(NSDictionary*)args;

/**
 *  同步执行一个是更新操作
 *
 *  @param sql  SQL语句
 *  @param args 参数列表
 *
 *  @return 返回是否执行成功
 */
-(BOOL)syncExecuteUpdate:(NSString*)sql withArrayArgs:(NSArray*)args;

#pragma 异步更新方法，单个SQL
/**
 *  异步执行一个更新操作
 *
 *  @param sql         SQL语句
 *  @param resultBlock 异步回调值
 */
-(void)asyncExecuteUpdate:(NSString*)sql resultBlock:(void(^)(BOOL result))resultBlock;

/**
 *  异步执行一个更新操作
 *
 *  @param sql         SQL语句
 *  @param args        参数列表
 *  @param resultBlock 异步回调值
 */
-(void)asyncExecuteUpdate:(NSString*)sql withDictionaryArgs:(NSDictionary*)args resultBlock:(void(^)(BOOL result))resultBlock;

/**
 *  异步执行一个更新操作
 *
 *  @param sql         SQL语句
 *  @param args        参数列表
 *  @param resultBlock 异步回调值
 */
-(void)asyncExecuteUpdate:(NSString*)sql withArrayArgs:(NSArray*)args resultBlock:(void(^)(BOOL result))resultBlock;

#pragma 同步更新方法，多个SQL
/**
 *  执行一系列的SQL操作
 *
 *  @param sqls SQL语句集合
 *
 *  @return 返回成功或失败，只有所有的成功才会成功
 */
-(BOOL)syncExecuteUpdates:(NSArray *)sqls;

/**
 *  执行一系列的SQL操作
 *
 *  @param sqls SQL语句集合
 *  @param args 对应的参数列表，有多少个SQL，就必须有多少个参数列表
 *
 *  @return 返回成功或失败，只有所有的成功才会成功
 */
-(BOOL)syncExecuteUpdates:(NSArray *)sqls withDictionaryArgs:(NSArray*)args;

/**
 *  执行一系列的SQL操作
 *
 *  @param sqls SQL语句集合
 *  @param args 对应的参数列表，有多少个SQL，就必须有多少个参数列表
 *
 *  @return 返回成功或失败，只有所有的成功才会成功
 */
-(BOOL)syncExecuteUpdates:(NSArray *)sqls withArrayArgs:(NSArray*)args;


#pragma 异步更新方法，多个SQL
/**
 *  异步执行一系列的SQL语句
 *
 *  @param sqls        SQL语句集合
 *  @param resultBlock 执行结果回调，只有所有的语句全部执行成功才会返回成功
 */
-(void)asyncExecuteUpdates:(NSArray *)sqls resultBlock:(void(^)(BOOL result))resultBlock;

/**
 *  异步执行一系列的SQL语句
 *
 *  @param sqls        SQL语句集合
 *  @param args        参数列表集合
 *  @param resultBlock 执行结果回调，只有所有的语句全部执行成功才会返回成功
 */
-(void)asyncExecuteUpdates:(NSArray *)sqls withDictionaryArgs:(NSArray*)args resultBlock:(void(^)(BOOL result))resultBlock;

/**
 *  异步执行一系列的SQL语句
 *
 *  @param sqls        SQL语句集合
 *  @param args        参数列表集合
 *  @param resultBlock 执行结果回调，只有所有的语句全部执行成功才会返回成功
 */
-(void)asyncExecuteUpdates:(NSArray *)sqls withArrayArgs:(NSArray*)args resultBlock:(void(^)(BOOL result))resultBlock;

#pragma 同步查询
/**
 *  同步执行一个查询
 *
 *  @param sql 查询SQL
 *
 *  @return 返回查询结果，结果为NSArray，Array里面为NSDictionary
 */
-(NSArray*)syncExecuteQuery:(NSString*)sql;

/**
 *  同步执行一个查询
 *
 *  @param sql  查询SQL
 *  @param args 参数列表
 *
 *  @return 返回查询结果 ，结果为NSArray，Array里面为NSDictionary，是数据库的键值对
 */
-(NSArray*)syncExecuteQuery:(NSString*)sql withDictionaryArgs:(NSDictionary*)args;

/**
 *  同步执行一个查询
 *
 *  @param sql  查询SQL
 *  @param args 参数列表
 *
 *  @return 返回查询结果 ，结果为NSArray,Array里面为NSDictionary，是数据库的键值对
 */
-(NSArray*)syncExecuteQuery:(NSString*)sql withArrayArgs:(NSArray*)args;


#pragma 同步查询，单例
/**
 *  单例查询，当SQL语句仅返回一条数据时使用此方法
 *
 *  @param sql 查询SQL
 *
 *  @return 返回NSDictionary
 */
-(NSDictionary*)syncSingleExecuteQuery:(NSString*)sql;

/**
 *  单例查询，当SQL语句仅返回一条数据时使用此方法
 *
 *  @param sql  SQL语句
 *  @param args 参数列表
 *
 *  @return 返回一个NSDictionary
 */
-(NSDictionary*)syncSingleExecuteQuery:(NSString*)sql withDictionaryArgs:(NSDictionary*)args;

/**
 *  同步单例查询，当SQL语句仅返回一条数据时使用此方法
 *
 *  @param sql  SQL语句
 *  @param args 参数列表
 *
 *  @return 返回查询结果 ，结果为NSDictionary
 */
-(NSDictionary*)syncSingleExecuteQuery:(NSString*)sql withArrayArgs:(NSArray*)args;

#pragma 同步查询，返回对象
/**
 *  同步查询，返回Model集合
 *
 *  @param sql            SQL语句
 *  @param convertBlock 用户提供NSDictionary到对象的整合block
 *
 *  @return 返回一个数组，数组中为对象
 */
-(NSArray*)syncExecuteQuery:(NSString*)sql convertBlock:(id(^)(NSDictionary * result))convertBlock;


/**
 *  同步查询，返回Model集合
 *
 *  @param sql          SQL语句
 *  @param args         参数列表
 *  @param convertBlock 用户提供NSDictionary到对象的整合block
 *
 *  @return 返回一个数组，数组中为对象
 */
-(NSArray*)syncExecuteQuery:(NSString *)sql withDictionaryArgs:(NSDictionary*)args convertBlock:(id (^)(NSDictionary* result))convertBlock;

/**
 *  同步查询，返回Model集合
 *
 *  @param sql          SQL语句
 *  @param args         参数列表
 *  @param convertBlock 用户提供NSDictionary到对象的整合block
 *
 *  @return 返回一个数组，数组中为对象
 */
-(NSArray*)syncExecuteQuery:(NSString *)sql withArraysArgs:(NSArray*)args convertBlock:(id (^)(NSDictionary* result))convertBlock;


#pragma 同步查询，对象且单例
/**
 *  同步查询，返回Model集合
 *
 *  @param sql            SQL语句
 *  @param convertBlock 用户提供NSDictionary到对象的整合block
 *
 *  @return 返回一个对象
 */
-(id)syncSingleExecuteQuery:(NSString*)sql convertBlock:(id(^)(NSDictionary * result))convertBlock;


/**
 *  同步查询，返回Model集合
 *
 *  @param sql          SQL语句
 *  @param args         参数列表
 *  @param convertBlock 用户提供NSDictionary到对象的整合block
 *
 *  @return 返返回一个对象
 */
-(id)syncSingleExecuteQuery:(NSString *)sql withDictionaryArgs:(NSDictionary*)args convertBlock:(id (^)(NSDictionary* result))convertBlock;

/**
 *  同步查询，返回Model集合
 *
 *  @param sql          SQL语句
 *  @param args         参数列表
 *  @param convertBlock 用户提供NSDictionary到对象的整合block
 *
 *  @return 返回一个对象
 */
-(id)syncSingleExecuteQuery:(NSString *)sql withArraysArgs:(NSArray*)args convertBlock:(id (^)(NSDictionary* result))convertBlock;


#pragma 异步查询,Dictionary
/**
 *  异步执行查询
 *
 *  @param sql         语句SQL
 *  @param resultBlock result回调，回调返回NSArray，NSArray中为NSDictionary
 */
-(void)asyncExecuteQuery:(NSString*)sql resultBlock:(void(^)(NSArray*))resultBlock;

/**
 *  异步执行查询
 *
 *  @param sql         语句SQL
 *  @param args        参数列表
 *  @param resultBlock result回调，回调返回NSArray，NSArray中为NSDictionary
 */
-(void)asyncExecuteQuery:(NSString *)sql withDictionaryArgs:(NSDictionary*)args resultBlock:(void (^)(NSArray* result))resultBlock;

/**
 *  异步执行查询
 *
 *  @param sql         语句SQL
 *  @param args        参数列表
 *  @param resultBlock result回调，回调返回NSArray，NSArray中为NSDictionary
 */
-(void)asyncExecuteQuery:(NSString *)sql withArrayArgs:(NSArray*)args resultBlock:(void (^)(NSArray* result))resultBlock;

#pragma 异步查询，单例

/**
 *  异步执行查询
 *
 *  @param sql         语句SQL
 *  @param resultBlock result回调，回调返回NSDictionary
 */
-(void)asyncSingleExecuteQuery:(NSString*)sql resultBlock:(void(^)(NSDictionary* result))resultBlock;

/**
 *  异步执行查询
 *
 *  @param sql         语句SQL
 *  @param args        参数列表
 *  @param resultBlock result回调，回调返回NSDictionary
 */
-(void)asyncSingleExecuteQuery:(NSString *)sql withDictionaryArgs:(NSDictionary*)args resultBlock:(void (^)(NSDictionary* result))resultBlock;

/**
 *  异步执行查询
 *
 *  @param sql         语句SQL
 *  @param args        参数列表
 *  @param resultBlock result回调，回调返回NSDictionary
 */
-(void)asyncSingleExecuteQuery:(NSString *)sql withArrayArgs:(NSArray*)args resultBlock:(void (^)(NSDictionary* result))resultBlock;

#pragma 异步查询，NSDictionary
/**
 *  异步查询，返回对象集合
 *
 *  @param sql          SQL语句
 *  @param convertBlock NSDictionary转成id对象的Block
 *  @param resultBlock  返回Block,结果为NSArray的ID对象集合
 */
-(void)asyncExecuteQuery:(NSString*)sql convertBlock:(id(^)(NSDictionary*))convertBlock resultBlock:(void(^)(NSArray*))resultBlock;

/**
 *  异步查询，返回对象集合
 *
 *  @param sql          SQL语句
 *  @param args         参数列表
 *  @param convertBlock NSDictionary转成id对象的Block
 *  @param resultBlock  返回Block,结果为NSArray的ID对象集合
 */
-(void)asyncExecuteQuery:(NSString*)sql withDictionaryArgs:(NSDictionary*)args convertBlock:(id(^)(NSDictionary*))convertBlock resultBlock:(void(^)(NSArray*))resultBlock;
/**
 *  异步查询，返回对象集合
 *
 *  @param sql          SQL语句
 *  @param args         参数列表
 *  @param convertBlock NSDictionary转成id对象的Block
 *  @param resultBlock  返回Block,结果为NSArray的ID对象集合
 */
-(void)asyncExecuteQuery:(NSString*)sql withArrayArgs:(NSArray*)args convertBlock:(id(^)(NSDictionary*))convertBlock resultBlock:(void(^)(NSArray*))resultBlock;

#pragma 异步查询，单例
/**
 *  异步单例查询
 *
 *  @param sql          SQL语句
 *  @param convertBlock NSDictionary转成id对象的Block
 *  @param resultBlock  返回Block,结果为ID
 */
-(void)asyncSingleExecuteQuery:(NSString*)sql convertBlock:(id(^)(NSDictionary*))convertBlock resultBlock:(void(^)(id))resultBlock;

/**
 *  异步单例查询
 *
 *  @param sql          SQL语句
 *  @param args         参数列表
 *  @param convertBlock NSDictionary转成id对象的Block
 *  @param resultBlock  返回Block,结果为ID
 */
-(void)asyncSingleExecuteQuery:(NSString*)sql withDictionaryArgs:(NSDictionary*)args convertBlock:(id(^)(NSDictionary*))convertBlock resultBlock:(void(^)(id))resultBlock;
/**
 *  异步单例查询
 *
 *  @param sql          SQL语句
 *  @param args         参数列表
 *  @param convertBlock NSDictionary转成id对象的Block
 *  @param resultBlock  返回Block,结果为ID
 */
-(void)asyncSingleExecuteQuery:(NSString*)sql withArrayArgs:(NSArray*)args convertBlock:(id(^)(NSDictionary*))convertBlock resultBlock:(void(^)(id))resultBlock;

/**
 *  同步查询数据库中某个表是否存在
 *
 *  @param tableName 表名
 *
 *  @return 返回结果
 */
-(BOOL)syncQueryTableExists:(NSString*)tableName;

/**
 *  异步查询表是否存在
 *
 *  @param tableName   表名
 *  @param resultBlock 回调
 *
 */
-(void)syncQueryTableExists:(NSString*)tableName resultBlock:(void(^)(BOOL success))resultBlock;


@end
