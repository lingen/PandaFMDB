//
//  OPTableProtocol.h
//  Pods
//
//  Created by lingen on 16/3/21.
//
//

#import <Foundation/Foundation.h>

@protocol OPTableProtocol <NSObject>


@required

/*
 * 实现此方法，用于数据库表的创建
 */
+(NSArray*)initTable;

/*
 *实现此方法，用于数据库表的升级功能
 */
+(NSArray*)updateTable:(int)fromVersion toVersion:(int)toVersion;


@end
