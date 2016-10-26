//
//  YPFMDBManager.m
//  数据库处理
//
//  Created by 王烨谱 on 16/10/19.
//  Copyright © 2016年 王烨谱. All rights reserved.
//

#import "YPFMDBManager.h"
#import <objc/runtime.h>
#import "NSObject+YPDBHelper.h"

@interface YPFMDBManager ()

@property(nonatomic, copy)void(^managerBlock)(BOOL res,FMResultSet *set);
@property(nonatomic,strong)FMDatabaseQueue *dbQueue;
@property(nonatomic,strong)FMDatabase *dbBase;
@end

@implementation YPFMDBManager

#pragma mark --------------setting,getting----------
+(YPFMDBManager *)shareFMDBManager{
    static YPFMDBManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[YPFMDBManager alloc]init];
    });
    return manager;
}

-(id)init{
    self = [super init];
    if (self) {
        self.dbQueue = [FMDatabaseQueue databaseQueueWithPath:self.filePath];
        self.dbBase = [[FMDatabase alloc]initWithPath:self.filePath];
    }
    return self;
}


/**
 SQL语句管理

 @param SQL          SQL语句
 @param type         SQL语句类型
 @param managerBlock 管理语句回调
 */
-(void)managerWithSQL:(NSString *)SQL type:(dbManagerType)type block:(void(^)(BOOL res,FMResultSet *set))managerBlock{
    self.managerBlock = managerBlock;
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        if (![db open]) {
            NSLog(@"FMDB-Alert:数据库没有打开");
            return;
        }
        BOOL result= [db executeUpdate:SQL];
        FMResultSet *manageResult = [db executeQuery:SQL];
        switch (type) {
            case createDBType:
            {
                NSString *alertString = result?@"FMDB-Alert:创建表成功":@"FMDB-Alert:创建表失败";
                NSLog(@"%@",alertString);
                self.managerBlock(result,manageResult);
            }
                break;
            case deletDBType:
            {
                NSString *alertString = result?@"FMDB-Alert:删除数据成功":@"FMDB-Alert:删除数据失败";
                NSLog(@"%@",alertString);
                self.managerBlock(result,manageResult);
            }
                break;
            case insertDBType:
            {
                NSString *alertString = result?@"FMDB-Alert:插入表成功":@"FMDB-Alert:插入表失败";
                NSLog(@"%@",alertString);
                self.managerBlock(result,manageResult);
            }
                break;
            case updateDBType:
            {
//                NSString *alertString = result?@"FMDB-Alert:更新表成功":@"FMDB-Alert:更新表失败";
//                NSLog(@"%@",alertString);
                self.managerBlock(result,manageResult);
            }
                break;
            case queryDBType:
            {
//                NSString *alertString = result?@"FMDB-Alert:查找表成功":@"FMDB-Alert:查找表失败";
//                NSLog(@"%@",alertString);
                self.managerBlock(result,manageResult);
            }
                break;
            case dropDBType:
            {
                NSString *alertString = result?@"FMDB-Alert:清空表成功":@"FMDB-Alert:清空表失败";
                NSLog(@"%@",alertString);
                self.managerBlock(result,manageResult);
            }
                break;
            default:
                break;
        }
        
    }];
}

#pragma mark ---------------------pathManager-------------------
-(NSString *)filePath{
    
    NSString *documentDirectory = [self cachePath];
    NSString *dbPath = [documentDirectory stringByAppendingPathComponent:@"dbc.sqlite"];
    NSLog(@"cachepath: %@", dbPath);
    
    return dbPath;
}

-(NSString *)toPath{
    
    NSString *documentDirectory = [self cachePath];
    NSString *dbPath = [documentDirectory stringByAppendingPathComponent:@"dbc.sqlite"];
    NSLog(@"cachepath: %@", dbPath);
    return dbPath;
}

-(NSString *)cachePath{
    //获取Documents路径
    NSArray*paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString*path=[paths objectAtIndex:0];
    NSString *fileDirectory = [NSString stringWithFormat:@"%@/%@", path, @"list_data"];
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDirectory = NO;
    if (![fm fileExistsAtPath:fileDirectory isDirectory:&isDirectory]) {
        NSError *error = nil;
        BOOL res = [fm createDirectoryAtPath:fileDirectory withIntermediateDirectories:YES attributes:nil error:&error];
        if (res == YES) {
            return fileDirectory;
        }
        NSLog(@"创建目录失败");
    }
    return fileDirectory;
}

// 多线程 执行查询, 插入, 更新接口
-(void)executeQuery:(void (^)(FMDatabase *db, BOOL *rollback))block {
    [self.dbQueue inTransaction:block];
}

                        
@end
