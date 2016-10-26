//
//  NSObject+YPDBHelper.m
//  数据库处理
//
//  Created by 王烨谱 on 16/10/18.
//  Copyright © 2016年 王烨谱. All rights reserved.
//

#import "NSObject+YPDBHelper.h"
#import "YPFMDBManager.h"
#import <objc/runtime.h>
#import "YYModel.h"

//#define kOwnerName      @"ownerId"

@implementation NSObject (YPDBHelper)

#pragma mark -------------------获取类属性---------------------

//运行时获取model的熟悉转换成字典
-(NSMutableDictionary *)attributeProrertyDic{
    unsigned int count = 0;
    Ivar *ivars = class_copyIvarList([self class], &count);
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    for (int i = 0; i<count; i++) {
        // 取出i位置对应的成员变量
        Ivar ivar = ivars[i];
        // 查看成员变量
        const char *name = ivar_getName(ivar);
        // 归档
        NSString *key = [NSString stringWithUTF8String:name];
        id value = [self valueForKey:key];
        if ([value isKindOfClass:[NSNull class]] || value == nil) {
            value = @"";
        }
        [dic setObject:value forKey:key];
    }
    free(ivars);
    return dic;
}

//获取model所有的key数组
-(NSArray *)attributePropertyList{
    NSDictionary *dic = [self attributeProrertyDic];
    NSArray *array = [dic allKeys];
    return array;
}

/*
 * 根据键名称  获取键值 返回创建的字典数组
 */
-(NSMutableDictionary *)getAttributeDicWithArray:(NSArray *)keyArray{
    NSMutableDictionary *ivarDic = [self attributeProrertyDic];
    NSMutableDictionary *keyDic = [NSMutableDictionary new];
    for (NSString *key in keyArray) {
        if ([ivarDic valueForKey:key] != nil) {
            [keyDic setObject:[ivarDic valueForKey:key] forKey:key];
        }else{
            assert(@"DBError:没有找到对应的主键！");
            return [NSMutableDictionary new];
        }
    }
    return keyDic;
}


#pragma mark ----------------------FMDB-----------------------
/**
 创建表

 @param primaryKeys 主键
 */
+(void)createWithKey:(NSArray *)primaryKeys{
    
    NSString *tableName = [NSString stringWithUTF8String:object_getClassName([self class])];
    NSMutableString *mutSql = [NSMutableString stringWithFormat:@"CREATE TABLE IF NOT EXISTS '%@' (",tableName];
    for (NSString *key in primaryKeys) {
        NSString *proType = @"BLOB";
        [mutSql appendFormat:@"'%@' %@, ", [self IsChinese:key], proType];
    }
    // 设置联合主键
    NSString *primaryKey = [primaryKeys componentsJoinedByString:@","];
    [mutSql appendFormat:@"PRIMARY KEY(%@))", [self IsChinese:primaryKey]];
    [[YPFMDBManager shareFMDBManager] managerWithSQL:mutSql type:createDBType block:^(BOOL res, FMResultSet *set) {
        
    }];
    // 添加字段
    [self alertTable:tableName];
}

/*
 * 插入或更新 (联合主键)
 * keys 对应条件的 主键名列表 (具有唯一性)
 * keys数组中的第一位作为表的拥有者属性 （用于多用户类型）
 */
-(void)insertOrUpdateWithKeys:(NSArray *)keys{
    if (keys.count == 0 || keys == nil) {
        assert(@"DBError:主键不能为空");
        return;
    }
    NSString *querySQL = [self querySQLWithKeys:keys];
    [[YPFMDBManager shareFMDBManager] managerWithSQL:querySQL type:queryDBType block:^(BOOL res, FMResultSet *set) {
        
    }];
    [[YPFMDBManager shareFMDBManager] executeQuery:^(FMDatabase *db, BOOL *rollback) {
        if ([db open]) {
            FMResultSet *rs = [db executeQuery:querySQL];
            NSArray *result = [[self class] handleFMResultSet:rs];
            if (result.count > 0) {
                NSString *updateSQL = [self updateSQLWithWithKeys:keys];
                [db executeUpdate:updateSQL];
            } else {
                NSString *insertSQL = [self insertSQLWithKeys:keys];
                [db executeUpdate:insertSQL];
            }
        }
    }];
}


/*
 * 删除
 * value 对应条件的值 ,key 对应条件的 名
 * ownerId (所有者, 登陆用户的id)有则删掉ownerid对应符合条件的行, 无则删除所以符合条件的行
 */
+(void)deleteWithDic:(NSMutableDictionary *)keyDic{
    if (keyDic.count == 0 || keyDic == nil) {
        assert(@"DBError:主键不能为空");
        return;
    }
    NSString *sql = [self deleteSQLWithDic:keyDic];
    [[YPFMDBManager shareFMDBManager] managerWithSQL:sql type:deletDBType block:^(BOOL res, FMResultSet *set) {
        
    }];
}


/**
 清空表
 */
+(void)dropTable{
    NSString *sql = [self dropSQL];
    [[YPFMDBManager shareFMDBManager] managerWithSQL:sql type:dropDBType block:^(BOOL res, FMResultSet *set) {
        
    }];
}


/**
 查找表数据
 @param params 查找的键值对
 @param block  返回model数组
 */
+(void)queryWithParams:(NSDictionary *)params
 responseModelBlock:(QueryListFinishBlock)block{
    NSString *sql = [self querySQLWithParams:params];
    [[YPFMDBManager shareFMDBManager] managerWithSQL:sql type:queryDBType block:^(BOOL res, FMResultSet *set) {
        NSMutableArray *propertyList = [self handleFMResultSet:set];
        NSMutableArray *allModels = [NSMutableArray array];
        for (NSDictionary *dic in propertyList) {
            id model = [[self class] yy_modelWithDictionary:dic];
            [allModels addObject:model];
        }
        if (block) {
            block(allModels);
        }
    }];
}


/**
 查询

 @param sql   查询语句
 @param block 查询回调
 */
+(void)queryWithSql:(NSString *)sql
 responseModelBlock:(QueryListFinishBlock)block{
    [[YPFMDBManager shareFMDBManager] managerWithSQL:sql type:queryDBType block:^(BOOL res, FMResultSet *set) {
        NSMutableArray *propertyList = [self handleFMResultSet:set];
        NSMutableArray *allModels = [NSMutableArray array];
        for (NSDictionary *dic in propertyList) {
            id model = [[self class] yy_modelWithDictionary:dic];
            [allModels addObject:model];
        }
        if (block) {
            block(allModels);
        }
    }];
}

#pragma mark -------------------生成SQL语句----------------------
/**
 清空表SQL
 @return 清空表的sql
 */
-(NSString *)dropSQL{
    NSString *tableName = [NSString stringWithUTF8String:object_getClassName([self class])];
    NSString * sql = [NSString stringWithFormat:@"drop table %@",tableName];
    return sql;
}

/**
 * 获取查询 SQL语句
 */
-(NSString *)querySQLWithKeys:(NSArray *)keys{
    NSString *tableName = [NSString stringWithUTF8String:object_getClassName([self class])];
    NSMutableString *bodySql = [NSMutableString string];
    NSMutableString *sql = [NSMutableString string];
    NSMutableDictionary *keyDic = [self getAttributeDicWithArray:keys];
    NSString *ownerKey = keys[0];
    NSString *ownerValue = [keyDic valueForKey:ownerKey];
    if (ownerValue.length == 0 || ownerValue == nil) {
        assert(@"DBError:主键值不能为空");
        return nil;
    }
    sql = [NSMutableString stringWithFormat:@"SELECT * FROM %@ where ", tableName];
    for (int i = 0; i < keys.count; i++) {
        id key = keys[i];
        id value = [keyDic valueForKey:key];
        if (i == 0) {
            [bodySql appendFormat:@"%@ = '%@'", key, value];
        }else{
            [bodySql appendFormat:@" AND %@ = '%@'", key, value];
        }
    }
    [sql appendString:bodySql];
    return sql;
}

/**
 * 获取删除表 SQL语句
 */
-(NSString *)deleteSQLWithDic:(NSMutableDictionary *)keyDic{
    NSString *tableName = [NSString stringWithUTF8String:object_getClassName([self class])];
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE",tableName];
    if (keyDic == nil || keyDic.count == 0) {
        assert(@"DBError:删除表失败");
    }else{
        NSArray *keys = [keyDic allKeys];
        for (int i = 0; i< keys.count; i ++) {
            NSString *key = keys[i];
            NSString *value = [keyDic valueForKey:key];
            if (i == 0) {
                sql = [sql stringByAppendingString:[NSString stringWithFormat:@" %@ = '%@'",key,value]];
            }else{
                sql = [sql stringByAppendingString:[NSString stringWithFormat:@" AND %@ = '%@'",key,value]];
            }
        }
    }
    return sql;
}


/**
 * 获取插入数据 SQL语句
 */
-(NSString *)insertSQLWithKeys:(NSArray *)keys{
    NSDictionary *attributeDic = [self attributeProrertyDic];
    NSArray *allKeys = [attributeDic allKeys];
    NSString *tableName = [NSString stringWithUTF8String:object_getClassName([self class])];
    
    NSMutableString *sqlStr = [NSMutableString stringWithFormat:@"INSERT INTO '%@'", tableName];
    NSMutableString *sqlKeyStr = [NSMutableString stringWithFormat:@"("];
    NSMutableString *sqlValueStr = [NSMutableString stringWithFormat:@") VALUES ("];
    
    NSMutableDictionary *newDic = [NSMutableDictionary dictionary];
    for (int i = 0; i < allKeys.count; i++) {
        NSString *key = allKeys[i];
        id value = attributeDic[key];
        key = [key substringFromIndex:1];
        if ([value isKindOfClass:[NSString class]] && ((NSString*)value).length > 0) {
            [newDic setObject:value forKey:key];
        }
        if ([value isKindOfClass:[NSNumber class]] && value != nil) {
            [newDic setObject:value forKey:key];
        }
        if ([value isKindOfClass:[NSArray class]]) {
            // 数组处理
            
            // 模型处理
        }
    }
    allKeys = [newDic allKeys];
    for (int i = 0; i < allKeys.count; i++) {
        NSString *key = allKeys[i];
        NSString *value = newDic[key];
        if (i == allKeys.count - 1) {
            [sqlKeyStr appendFormat:@"'%@' ", key];
            [sqlValueStr appendFormat:@"'%@' ", value];
            break;
        }
        [sqlKeyStr appendFormat:@"'%@', ", key];
        [sqlValueStr appendFormat:@"'%@', ", value];
    }
    [sqlValueStr appendString:@")"];
    [sqlStr appendString:sqlKeyStr];
    [sqlStr appendString:sqlValueStr];
    return sqlStr;
}

/**
 * 获取update更新的 SQL语句
 */
-(NSString *)updateSQLWithWithKeys:(NSArray *)keys{
    NSMutableDictionary *keyDic = [self getAttributeDicWithArray:keys];
    NSDictionary *attributeDic = [self attributeProrertyDic];
    NSArray *allKeys = [attributeDic allKeys];
    NSString *tableName = [NSString stringWithUTF8String:object_getClassName([self class])];
    NSString *headSql = [NSString stringWithFormat:@"UPDATE %@ SET ", tableName];
    NSMutableString *valueSql = [NSMutableString stringWithFormat:@""];
    for (int i = 0; i < allKeys.count; i++) {
        NSString *key = allKeys[i];
        id value = attributeDic[key];
        key = [key substringFromIndex:1];
        if (i == allKeys.count -1) {
            [valueSql appendFormat:@"%@='%@'", key, value];
            break;
        }
        [valueSql appendFormat:@"%@='%@',", key, value];
    }
    NSMutableString *footerSql = [NSMutableString string];
        footerSql = [NSMutableString stringWithFormat:@" where "];
    for (int i = 0; i < keys.count; i++) {
        id key = keys[i];
        id value = [keyDic valueForKey:key];
        if (i == 0) {
            [footerSql appendFormat:@"%@ = '%@'", key, value];
        }else{
            [footerSql appendFormat:@" AND %@ = '%@'", key, value];
        }
    }
    NSString *sql = [NSString stringWithFormat:@"%@%@%@", headSql, valueSql, footerSql];
    return sql;
}


/**
 查找表SQL
 @return 查找表的sql
 */
-(NSString *)querySQLWithParams:(NSDictionary *)params{
    NSString *tableName = [NSString stringWithUTF8String:object_getClassName([self class])];
    NSMutableString * sqlHead = [NSMutableString stringWithFormat:@"SELECT * FROM %@",tableName];
    if (params == nil) {
        sqlHead = [NSMutableString stringWithFormat:@"SELECT * FROM %@",tableName];
        return sqlHead;
    }
    NSArray *allKeys = [params allKeys];
    NSMutableString *sqlBody = [NSMutableString string];
    for (int i = 0; i < allKeys.count; i++) {
        NSString *key = allKeys[i];
        id value = params[key];
        if (i == 0) {
            [sqlBody appendFormat:@"WHERE %@ = '%@'", key, value];
            continue;
        }
        [sqlBody appendFormat:@" AND %@ = '%@'", key, value];
    }
    NSString * sql = [NSString stringWithFormat:@"%@ %@",sqlHead, sqlBody];
    return sql;
}



/**
 添加表字段
 @param tableName 表名
 */
+(void)alertTable:(NSString *)tableName{
    id model = [[self alloc] init];
    NSArray *attributes = [model attributePropertyList];
    NSString *alertSql;
    for (NSString *key in attributes) {
        NSString *newKey = [key substringFromIndex:1];
        alertSql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD %@ BLOB", tableName, newKey];
        [[YPFMDBManager shareFMDBManager] managerWithSQL:alertSql type:updateDBType block:^(BOOL res, FMResultSet *set) {
            
        }];
    }
}


#pragma mark ------------------itools(工具)------------------
/**
 * handle  FMResultSet
 */
+(NSMutableArray *)handleFMResultSet:(FMResultSet *)rs{
    NSMutableArray *propertyList = [NSMutableArray array];
    while ([rs next]) {
        id model = [[self alloc] init];
        
        NSArray *allKeys = [model attributePropertyList];
        
        NSMutableDictionary *propertyDic = [NSMutableDictionary dictionary];
        for (int i = 0; i < allKeys.count; i++) {
            
            NSString *key = allKeys[i];
            if ([key hasPrefix:@"_"]) {
                key = [key substringFromIndex:1];
            }
            
            id value = [rs stringForColumn:key];
            if (value == nil) {
                value = @"";
            }
            
            [propertyDic setObject:value forKey:key];
        }
        
        [propertyList addObject:propertyDic];
        //            [allModels addObject:model];
    }
    return propertyList;
}


/**
 判断是否有中文字符

 @param str 检查项

 @return 返回不含中文的字段
 */
+(NSString *)IsChinese:(NSString *)str{
    BOOL hadChinese = NO;
    for(int i = 0; i< [str length];i++){
        int a = [str characterAtIndex:i];
        if( a > 0x4e00 && a < 0x9fff){
            hadChinese = YES;
        }
    }
    if (hadChinese) {
        return [self transform:str];
    }else{
        return str;
    }
}


/**
 中文转拼音

 @param chinese 中文

 @return 中文转换的拼音
 */
+ (NSString *)transform:(NSString *)chinese
{
    if (chinese.length == 0 || chinese == nil) {
        return @"#";
    }
    NSMutableString *pinyin = [chinese mutableCopy];
    CFStringTransform((__bridge CFMutableStringRef)pinyin, NULL, kCFStringTransformMandarinLatin, NO);
    CFStringTransform((__bridge CFMutableStringRef)pinyin, NULL, kCFStringTransformStripCombiningMarks, NO);
    if ([pinyin containsString:@" "]) {
        NSString *str = [pinyin stringByReplacingOccurrencesOfString:@" " withString:@""];
        pinyin = [NSMutableString stringWithFormat:@"%@",str];
    }
    return [pinyin uppercaseString];
}

@end


@implementation NSObject (JSON)

-(id)setValueForClassWithDictionary:(NSDictionary *)dic
{
    [self anilistMyClass:[self class]];
    id model = [[[self class] alloc]init];
    if (model)
    {
        unsigned int count = 0;
        //获取类的属性列表
        Ivar *ivars = class_copyIvarList([self class], &count);
        //给属性赋值
        for (int i = 0; i<count; i++)
        {
            Ivar ivar = ivars[i];
            //获取变量名称
            const char *name = ivar_getName(ivar);
            NSString *key = [NSString stringWithUTF8String:name];
            //生成setter方法
            NSString *usefullStr = [key substringFromIndex:1];          //跳过下划线
            key = usefullStr.capitalizedString;                         //大写首字母
            key = [NSString stringWithFormat:@"set%@:", key];           //拼接set方法字符串
            SEL setSel = NSSelectorFromString(key);
            //调用setter方法
            if ([model respondsToSelector:setSel])
            {
                id value = @"";
                if ([dic objectForKey:usefullStr]!=nil) {
                    value = [dic objectForKey:usefullStr];
                }
                [model performSelectorOnMainThread:setSel withObject:value waitUntilDone:[NSThread isMainThread]];
            }
        }
        free(ivars);
    }
    return model;
}

- (void)anilistMyClass:(Class)className{
    u_int count;
    objc_property_t * properties  = class_copyPropertyList(className, &count);
    for (int i=0; i<count; i++) {
        objc_property_t property = properties[i];
        NSString *propertyName = [[NSString alloc] initWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        NSLog(@"%@",propertyName);
    }
    free(properties);
}

@end
