//
//  OPRepository.h
//  Pods
//
//  Created by lingen on 16/3/21.
//
//

#import <Foundation/Foundation.h>
#import "OPTableProtocol.h"

@interface OPRepository : NSObject

/*
 *初始化数据库路径以及表格对象
 */
-(instancetype)initWith:(NSString*) dbPath tables:(NSArray*)tables version:(int)version;

@end
