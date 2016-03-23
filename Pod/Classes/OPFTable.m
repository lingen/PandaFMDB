//
//  OPFTable.m
//  Pods
//
//  Created by lingen on 16/3/23.
//
//

#import "OPFTable.h"
#import "OPFColumn.h"

@implementation OPFTable

/**
 *  使用列定定义一个表格，主键为默认生成的一个自增长_id;没有任何索引
 *
 *  @param columns 列集合
 *
 *  @return 返回一个表定义
 */
-(instancetype)initWith:(NSString*)tableName columns:(NSArray*)columns{
    return [self initWith:tableName columns:columns primaryColumns:nil indexColumns:nil];
    
}

/**
 *  定义一个表，自定义了列，自定义了主键，未定义任何索引
 *
 *  @param columns        列定论
 *  @param primaryColumns 主键定义
 *
 *  @return 返回一个表定义
 */
-(instancetype)initWith:(NSString*)tableName columns:(NSArray*)columns prmairyColumns:(NSArray*)primaryColumns{
    return [self initWith:tableName columns:columns primaryColumns:primaryColumns indexColumns:nil];
}

/**
 *  定义一个表，自定义了列，自定义主键，自定义索引
 *
 *  @param columns        列定义
 *  @param primaryColumns 主键定义
 *  @param indexColumns   索引定义
 *
 *  @return 返回一个表定义
 */
-(instancetype)initWith:(NSString*)tableName columns:(NSArray*)columns primaryColumns:(NSArray*)primaryColumns indexColumns:(NSArray*)indexColumns{
    if (self = [super init]) {
        _tableName = tableName;
        _columns = columns;
        _primaryColumns = primaryColumns;
        _indexColumns = indexColumns;
        return self;
    }
    return nil;
}

/**
 *  创建表SQL
 *
 *  @return 返回创建表SQL
 */
-(NSString*)createTableSQL{
    
    NSMutableString *createTableSQL = [[NSMutableString alloc] init];
    [createTableSQL appendString:@"create table "];
    //表名
    [createTableSQL appendString:_tableName];
    //左括号
    [createTableSQL appendString:@" ("];
    
    //遍历列定义
    for (int i=0; i< _columns.count; i++) {
        OPFColumn* column  = _columns[i];
        [createTableSQL appendString:[column columnCreateSQL]];
        [createTableSQL appendString:@" ,"];
    }
    
    //主键
    [createTableSQL appendString:[self p_primayKeyString]];
    
    //右括号
    [createTableSQL appendString:@" );"];
    return [createTableSQL copy];
    
}

/**
 *  创建索引语句
 *
 *  @return 返回创建表SQL
 */
-(NSString*)createIndexSQL{
    //CREATE INDEX index_name ON table_name (column_name);
    NSMutableString* indexString = [[NSMutableString alloc] init];

    if (_indexColumns) {
        for (OPFColumn* column in _indexColumns) {
            [indexString appendString:[NSString stringWithFormat:@"CREATE INDEX index_%@ ON %@ (%@);",column.name,_tableName,column.name]];
        }
    }
    return [indexString copy];
}

-(NSString*)p_primayKeyString{
    NSMutableString* primaryKey = [[NSMutableString alloc] init];
    if (_primaryColumns) {
        [primaryKey appendString:@"PRIMARY KEY("];
        for (int i=0; i< _primaryColumns.count; i++) {
            OPFColumn* column  = _primaryColumns[i];
            [primaryKey appendString:column.name];
            if (i!=_primaryColumns.count - 1) {
                [primaryKey appendString:@","];
            }
        }
        [primaryKey appendString:@")"];
    }else{
        [primaryKey appendString:[NSString stringWithFormat:@"OPF_ID_  integer PRIMARY KEY autoincrement"]];
    }
    return [primaryKey copy];
}
@end
