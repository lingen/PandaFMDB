//
//  Person.h
//  PandaFMDB
//
//  Created by lingen on 16/3/21.
//  Copyright © 2016年 lingen.liu. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OPF.h"

@interface Person : NSObject<OPFTableProtocol>

@property (nonatomic,strong) NSString* name;

@property (nonatomic,assign) int age;

@end
