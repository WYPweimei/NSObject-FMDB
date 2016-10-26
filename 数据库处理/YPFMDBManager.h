//
//  YPFMDBManager.h
//  数据库处理
//
//  Created by 王烨谱 on 16/10/19.
//  Copyright © 2016年 王烨谱. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDB.h"

typedef enum : NSUInteger {
    createDBType = 0,//创建
    deletDBType,//删除
    insertDBType,//插入
    updateDBType,//更新
    queryDBType,//查找
    dropDBType,//清空表
} dbManagerType;

@interface YPFMDBManager : NSObject

-(void)managerWithSQL:(NSString *)SQL type:(dbManagerType)type block:(void(^)(BOOL res,FMResultSet *set))managerBlock;

+(YPFMDBManager *)shareFMDBManager;

-(void)executeQuery:(void (^)(FMDatabase *db, BOOL *rollback))block;

@end
