//
//  OPFTable.h
//  Pods
//
//  Created by lingen on 16/3/23.
//
//

#import <Foundation/Foundation.h>
/**
 *  表定义
 */
@interface OPFTable : NSObject

@property (nonatomic,strong) NSString* tableName;

/**
 *  列定义集合
 */
@property (nonatomic,strong) NSArray* columns;

/**
 *  主键定义
 */
@property (nonatomic,strong) NSArray* primaryColumns;

/**
 *  索引列定义
 */
@property (nonatomic,strong) NSArray* indexColumns;

/**
 *  使用列定定义一个表格，主键为默认生成的一个自增长_id;没有任何索引
 *
 *  @param columns 列集合
 *
 *  @return 返回一个表定义
 */
-(instancetype)initWith:(NSString*)tableName columns:(NSArray*)columns;

/**
 *  定义一个表，自定义了列，自定义了主键，未定义任何索引
 *
 *  @param columns        列定论
 *  @param primaryColumns 主键定义
 *
 *  @return 返回一个表定义
 */
-(instancetype)initWith:(NSString*)tableName columns:(NSArray*)columns prmairyColumns:(NSArray*)primaryColumns;

/**
 *  定义一个表，自定义了列，自定义主键，自定义索引
 *
 *  @param columns        列定义
 *  @param primaryColumns 主键定义
 *  @param indexColumns   索引定义
 *
 *  @return 返回一个表定义
 */
-(instancetype)initWith:(NSString*)tableName columns:(NSArray*)columns primaryColumns:(NSArray*)primaryColumns indexColumns:(NSArray*)indexColumns;

/**
 *  创建表SQL
 *
 *  @return 返回创建表SQL
 */
-(NSString*)createTableSQL;

/**
 *  创建索引语句
 *
 *  @return 返回创建表SQL
 */
-(NSString*)createIndexSQL;


@end
