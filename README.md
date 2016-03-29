# PandaFMDB

[![CI Status](http://img.shields.io/travis/lingen.liu/PandaFMDB.svg?style=flat)](https://travis-ci.org/lingen.liu/PandaFMDB)
[![Version](https://img.shields.io/cocoapods/v/PandaFMDB.svg?style=flat)](http://cocoapods.org/pods/PandaFMDB)
[![License](https://img.shields.io/cocoapods/l/PandaFMDB.svg?style=flat)](http://cocoapods.org/pods/PandaFMDB)
[![Platform](https://img.shields.io/cocoapods/p/PandaFMDB.svg?style=flat)](http://cocoapods.org/pods/PandaFMDB)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

PandaFMDB is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "PandaFMDB"
```

## Author

lingen.liu, lingen.liu@gmail.com

## License

PandaFMDB is available under the MIT license. See the LICENSE file for more info.

#PandaFMDB简述
##PandaFMDB
本类库为我个人对DB操作的一个简单封装，主要是为了屏蔽DB上的编写过于复杂的代码

PanadaFMDB的特点:

1. 基于FMDB封装，并未重复创造轮子
2. 倡导SQLite及原生SQL编写
3. 对表的创建，升级提供了封装，无须额外编写升级代码，简化表创建
4. 重点对同步数据库操作提供支持
5. 支持自由事务嵌套行为，简化对数据库事务的操作

PandaFMDB一开始设计是是包括异步数据库操作API，但基于项目规范，在WorkPlus中引用中屏蔽了异步数据库操作API，仅开放同步数据库操作行为的API

>PanadaFMDB暂时不以cocoapods依赖进行管理，也不以framework类库包加入项目，而是以源码形势引入，以便后续我在项目中进一步完善，后续经过详细测试比较稳定后，再更换依赖方式

>项目组成员，不允许轻易修改这个类库的源码；

##数据库定义
###数据库定义
定义数据库：

~~~object-c
     NSMutableArray *tables = [[NSMutableArray alloc] init];
     //加入企业表
     [tables addObject:[WOFOrg class]];
     //加入用户表
     [tables addObject:[WOPContact class]];
     //加入关系表
     [tables addObject:[WOPRelation class]];
     //加入讨论组表
     [tables addObject:[WOPDiscussion class]];
     //加入讨论组成员表
     [tables addObject:[WOPDiscussionMember class]];
     
     //指定数据库路径
     NSString* dir = userDirectoryWithAccountName(userId);
     if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
          [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:NO attributes:nil error:nil];
     }
     NSString* dbPath = [NSString stringWithFormat:@"%@/WorkPlus_V3.sqlite",userDirectoryWithAccountName(userId)];
     
     //使用数据库路径，表定义以及当前版本号来初始化一个数据库
     _repository = [[OPFRepository alloc] initWith:dbPath tables:tables version:version];
~~~

PandaFMDB会自动进行表的创建，升级操作；


###表的定义

~~~oc
#import "WOPRelation.h"
#import "OPF.h"

/**
 *  关系模型的数据库逻辑
 */
@interface WOPRelation (DB) (OPFTableProtocol) //(MD不支持<>，以()代替协议)

@end

~~~

WorkPlus中统一以DB扩展名，意味着数据库的创建与升级行为

实现OPFTableProtocol协议

OPFTableProtocol协议中的两个关键方法

~~~object-c
/*
 * 实现此方法，用于数据库表的创建
 */
+(OPFTable*)createTable;

/*
 *实现此方法，用于数据库表的升级功能
 */
+(NSArray*)updateTable:(int)fromVersion toVersion:(int)toVersion
~~~

如上所述，你只需要实现createTable以及updateTable方法，就可以控制表的创建与升级

一个实现样例：

~~~object-c
#import "WOPRelation+DB.h"
#import "OPF.h"
@implementation WOPRelation (DB)


#pragma 表的创建以及升级逻辑
/*
 * 实现此方法，用于数据库表的创建
 */
+(OPFTable*)createTable{
     //定义一个列
     OPFColumn* userIdColumn = [[OPFColumn alloc] initNotNullColumn:@"user_id_" type:OPFColumnText];
     //定义一个列
     OPFColumn* typeColumn = [[OPFColumn alloc] initNotNullColumn:@"type_" type:OPFColumnInteger];
     NSArray* columns = @[userIdColumn,typeColumn];
     NSArray* primaryColumns = @[userIdColumn,typeColumn];
     OPFTable* table = [[OPFTable alloc] initWith:@"relationship_" columns:columns prmairyColumns:primaryColumns];
     return table;
}

/*
 *实现此方法，用于数据库表的升级功能
 */
+(NSArray*)updateTable:(int)fromVersion toVersion:(int)toVersion{
     return nil;
}

@end
~~~


OPFColumn类用于定义表中的一个列

~~~object-c
/**
 *  定义一个列，指定名称与类型
 *
 *  @param name 列名称
 *  @param type 类型
 *
 *  @return 返回列定义
 */
-(instancetype)initWith:(NSString*)name type:(OPFColumnType)type;

/**
 *  定义一个列，指定名称与类型且不允许为空
 *
 *  @param name 列名称
 *  @param type 类型
 *
 *  @return 返回一个列定义
 */
-(instancetype)initNotNullColumn:(NSString*)name type:(OPFColumnType)type;

~~~

一个表是由多个列，主键列以及索引列定义而来

~~~object-c
/**
 *  使用列定定义一个表格，主键为默认生成的一个自增长OPF_ID_;没有任何索引
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

~~~


###Panda API
WorkPlus中仅允许使用其同步操作数据库的API，禁止使用异步API

更新DB操作API

~~~
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
~~~

更新DB操作API （多条SQL）

>多SQL操作API，需要所有SQL全部执行成功，才会返回成功

~~~
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
~~~


查询API

~~~object-c
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
~~~

查询API，返回单例

~~~object-c
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
~~~

同步查询，返回对象

~~~object-c
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
~~~

查询API，返回对象并且单例

~~~
/**
 *  同步查询，返回Model
 *
 *  @param sql            SQL语句
 *  @param convertBlock 用户提供NSDictionary到对象的整合block
 *
 *  @return 返回一个对象
 */
-(id)syncSingleExecuteQuery:(NSString*)sql convertBlock:(id(^)(NSDictionary * result))convertBlock;


/**
 *  同步查询，返回Model
 *
 *  @param sql          SQL语句
 *  @param args         参数列表
 *  @param convertBlock 用户提供NSDictionary到对象的整合block
 *
 *  @return 返返回一个对象
 */
-(id)syncSingleExecuteQuery:(NSString *)sql withDictionaryArgs:(NSDictionary*)args convertBlock:(id (^)(NSDictionary* result))convertBlock;

/**
 *  同步查询，返回Model
 *
 *  @param sql          SQL语句
 *  @param args         参数列表
 *  @param convertBlock 用户提供NSDictionary到对象的整合block
 *
 *  @return 返回一个对象
 */
-(id)syncSingleExecuteQuery:(NSString *)sql withArraysArgs:(NSArray*)args convertBlock:(id (^)(NSDictionary* result))convertBlock;
~~~

查询某个表是否存在

~~~
-(BOOL)syncQueryTableExists:(NSString*)tableName;
~~~

事务API

~~~
/**
 *  将BLOCK里的数据库操作，全部归纳到一个事务中去
 *
 *  @param dbBlock BLOC行为
 *
 *  @return 返回是否成功
 */
-(void)syncInTransaction:(void(^)(BOOL *rollback))dbBlock;
~~~

###StrictMode模式
PandaFMDB提供了针对错误SQL的DEBUG模式下自动崩溃机制，如果你写的SQL有错误，在调试模式下会自动崩溃

~~~
2016-03-28 20:36:02.471 WorkPlusForTest[9469:336501] DB Error: 1 "near "selectaaa": syntax error"
2016-03-28 20:36:02.471 WorkPlusForTest[9469:336501] DB Query: selectaaa user_id_ from contact_
2016-03-28 20:36:02.491 WorkPlusForTest[9469:336501] *** Terminating app due to uncaught exception 'db Error', reason: 'DeBug DB Error:StrictMode DB Error::FMDatabase
~~~

上述崩溃信息告诉我们，selectaaa user_id_ from contact_这个是有语法错误的；如果你是在调试模式下，会自动崩溃APP并打印出此提示

> 通过这种机制，我希望能把SQL语法错误屏蔽在开发阶段，这个崩溃仅在调试模式下有效，打包下是不会崩溃，不影响APP体验

###错误SQL自动日志记录机制
对于打包模式下，错误的SQL会自动在用户主目录下存储并记录，开发人员可以随时查看此日志以找到错误的SQL日志

> 这个机制还未实现，待完善中

##主线程自动检测机制
PandaFMDB倡导使用同步的调用模式，这种模式很容易导致在UI主线程上操作DB数据库，因此PandaFMDB同时提供了主线程自动检测机制，一旦识别到你是在主线程上操作数据库，APP会立刻崩溃

> 通过这种机制，我希望能保证DB操作永远在非主线程上，如果开发人员一不小心在主线程上操作了DB，那在开发阶段就会立刻闪退
> 

###自由事务模式
数据库操作中，事务也是令人非常头疼的一个问题;在同步API操作中，更是一大问题，因为不同的数据库操作可能会相互调用

比如以下场景：

 1. 同步群组，获取所有群成员
 2. 对群成员批量进行保存
 3. 我们有一个独立的对群成员的保存操作，它可能是一个事务性的操作，因为服务层可能会直接调用它进行用户保存
 4. 如果我们在群成员批量保存中调用这个独立的群成员保存，这样它们显然不在一个事务中了，而且会出现事务嵌套模式；
 5. 如果我们不调用群成员保存这个数据库操作，我们可能需要把这个行为在另一个方法中重复一次

重复代码是开发的最大问题，我们需要避免这种问题

基于此，PandaFMDB实现了自由事务模式，会自动识别事务的最上层，以保证在相互调用时，会有事务

说明:

~~~
 /**
 *  把用户保存到数据库中
 *
 *  @return 返回是否保存成功
 */
-(BOOL)saveToDB{
     
     
     NSString* sqls = @"insert or replace into contact_ (user_id_,domain_id_,username_,name_,nickname_,pinyin_,initial_,avatar_,phone_,email_,gender_,birthday_,more_info_) values (:user_id_,:domain_id_,:username_,:name_,:nickname_,:pinyin_,:initial_,:avatar_,:phone_,:email_,:gender_,:birthday_,:more_info_)";
          
          NSDictionary* params = @{@"user_id_":self.userId,
                                   @"domain_id_":self.domainId,
                                   @"username_":StringNullable(self.username),
                                   @"name_":self.name,
                                   @"nickname_":StringNullable(self.nickname),
                                   @"pinyin_":StringNullable(self.pinyin),
                                   @"initial_":StringNullable(self.initial),
                                   @"avatar_":StringNullable(self.avatar),
                                   @"phone_":StringNullable(self.phone),
                                   @"email_":StringNullable(self.email),
                                   @"gender_":@(self.gender),
                                   @"birthday_":StringNullable(self.birthday),
                                   @"more_info_":StringNullable(self.moreInfo)
                                   };
     
     BOOL success = [[WOPRepository sharedInstance].repository syncExecuteUpdate:sqls withDictionaryArgs:params];
     
     return success;
     
     
}
~~~

上述方法是将用户保存到DB的一个数据库行为,如果你在服务层中调用此方法，则

~~~
 BOOL success = [[WOPRepository sharedInstance].repository syncExecuteUpdate:sqls withDictionaryArgs:params];
~~~
这句代码会自动产生一个事务，保存数据有效更新

如果是批量保存:

~~~
/**
 *  批量更新contacts
 *
 *  @param contacts contacts数组
 *
 *  @return 返回结果
 */
+(BOOL)batchSaveContact:(NSArray*)contacts{
     [[WOPRepository sharedInstance].repository syncInTransaction:^(BOOL *rollback) {
          for (WOPContact* contact in contacts) {
               [contact saveToDB];
          }
     }];
     return YES;
}
~~~

可以看到上述代码，我们使用了

~~~
syncInTransaction
~~~
这个方法

一旦使用这个方法，事务则会在这个方法的最上层产生，这个时候

~~~
[contact saveToDB];
~~~
这个行为将不再具有事务，而是在它的上一层会产生一个事务

~~~
syncInTransaction
~~~
这个是支持多层级事务自动识别，这意味着

~~~
     [[WOPRepository sharedInstance].repository syncInTransaction:^(BOOL *rollback) {
          for (WOPContact* contact in contacts) {
               [contact saveToDB];
          }
          
          [[WOPRepository sharedInstance].repository syncInTransaction:^(BOOL *rollback) {
               for (WOPContact* contact in contacts) {
                    [contact saveToDB];
               }
          }];
     }];
~~~

如上代码所示：在syncInTransaction外面还有一层syncInTransaction调用，这个时候，只有最外面的syncInTransaction会产生事务，里面的syncInTransaction以及[contact saveToDB]均不会产生事务

> 事务自由这个特性会极大的方便数据库之间的相互调用，避免因为事务问题而编写大量重复代码


~~~
/**
 *  批量更新contacts
 *
 *  @param contacts contacts数组
 *
 *  @return 返回结果
 */
+(BOOL)batchSaveContact:(NSArray*)contacts{
     
     [[WOPRepository sharedInstance].repository syncInTransaction:^(BOOL *rollback) {
          for (WOPContact* contact in contacts) {
               [contact saveToDB];
          }
          
     }];
     return YES;
}
~~~

如上述代码所示，batchSaveContact这个方法会非常简洁，它直接调用[contact saveToDB];，这样使得代码能最大化简洁