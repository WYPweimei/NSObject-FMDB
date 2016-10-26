//
//  NSObject+YPDBHelper.h
//  数据库处理
//
//  Created by 王烨谱 on 16/10/18.
//  Copyright © 2016年 王烨谱. All rights reserved.
//
/*
****************
 SQL语句对大小写不敏感  所以在写这些语句的时候一定要注意大小写 还有空格
CREATE TABLE Order
(
 Id_P int NOT NULL,//（NOT NULL）不为空
 LastName varchar(255) NOT NULL,
 FirstName varchar(255),
 Address varchar(255),
 City varchar(255)
 UNIQUE (Id_P) //（指明这个表的唯一标示，如果重复了）
 PRIMARY KEY (Id_P) //（主键必须包含唯一的值。主键列不能包含 NULL 值。基本上和UNIQUE一样）
 FOREIGN KEY (Id_P) REFERENCES Persons(Id_P)//（关联两个表的语句 Order表中的FOREIGN KEY 与Persong表中的PRIMARY KEY关联起来  必须是PRIMARY KEY）、
 CHECK (Id_P>0)//（加上这个条件代表  这个表只有满足这个条件的数据才能插入）
 )
****************
 */
#import <Foundation/Foundation.h>

typedef void(^QueryListFinishBlock) (NSArray *list);//查询表返回的model数组

@interface NSObject (YPDBHelper)
/*
 * 创建表
 * primaryKeys 主键列表
 * hasOwner 是否设置所有者
 */
+(void)createWithKey:(NSArray *)primaryKeys;
/*
 * 插入或更新 (联合主键)   如果数据变更了则更新
 * keys 对应条件的 主键名列表 (具有唯一性)
 * keys数组中的第一位作为表的拥有者属性 （用于多用户类型）
 */
-(void)insertOrUpdateWithKeys:(NSArray *)keys;
/*
 * 删除表数据
 * 键值对
 */
+(void)deleteWithDic:(NSMutableDictionary *)keyDic;
/**
 清空表
 */
+(void)dropTable;
/** 查询
 * 返回结果为model类型 列表  params为空则查询整个表
 */
+(void)queryWithParams:(NSDictionary *)params
    responseModelBlock:(QueryListFinishBlock)block;

/**
 查询
 *************
 1、SELECT DISTINCT 列名称 FROM 表名称  //从列中仅选取唯一不同的值
 2、SELECT Company, OrderNumber FROM Orders ORDER BY Company, OrderNumber//查询并排序 字母按照A-Z  数组按照1-9
 3、SELECT TOP 2 * FROM Persons //检索表前两条
 4、SELECT TOP 50 PERCENT * FROM Persons//检索表50%的数据
 5、SELECT * FROM Persons WHERE City LIKE 'N%' //检索以N开头；N%-->%N以N结尾；N%->%N%包含N；N%->[ALN]%以A或L或N开头； -> [!ALN]% 非   （_代表一个字符 %代表一个或多个字符）
 6、SELECT * FROM Persons WHERE LastName IN ('Adams','Carter') //检索值代表的列
 7、SELECT LastName AS Family, FirstName AS Name FROM Persons//修改列的名字
 8、SELECT Persons.LastName, Persons.FirstName, Orders.OrderNo FROM Persons INNER JOIN Orders ON Persons.Id_P = Orders.Id_P ORDER BY Persons.LastName//关联两个表 匹配数据 （JOIN: 如果表中有至少一个匹配，则返回行 LEFT JOIN: 即使右表中没有匹配，也从左表返回所有的行 RIGHT JOIN: 即使左表中没有匹配，也从右表返回所有的行 FULL JOIN: 只要其中一个表中存在匹配，就返回行）
 9、SELECT E_Name FROM Employees_China UNION SELECT E_Name FROM Employees_USA//列出两个表的所有值重复值不列出（UNION -> UNION ALL 列出所有的值 包含重复的值）
 11、SELECT LastName,Firstname INTO Persons_backup FROM Persons WHERE City='Beijing'//查找一个表中的数据插入另一个表中
 12、
 *************
 @param sql   SQL语句
 @param block 查询回调
 */
+(void)queryWithSql:(NSString *)sql
    responseModelBlock:(QueryListFinishBlock)block;

@end


@interface NSObject (JSON)

-(id)setValueForClassWithDictionary:(NSDictionary *)dic;

@end

