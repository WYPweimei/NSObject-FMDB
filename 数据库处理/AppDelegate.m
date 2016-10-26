//
//  AppDelegate.m
//  数据库处理
//
//  Created by 王烨谱 on 16/10/18.
//  Copyright © 2016年 王烨谱. All rights reserved.
//

#import "AppDelegate.h"
#import "Person.h"
#import "NSObject+YPDBHelper.h"
#import "YPFMDBManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
    NSLog(@"%@",path);
    
    [Person createWithKey:@[@"name"]];
    for (int i = 0; i < 10; i ++) {
        Person *p = [[Person alloc]init];
        p.name = [NSString stringWithFormat:@"测试%d",i];
        p.name1 = @"测试";
        p.name2 = @"测试";
        p.name3 = @"测试";
        p.age = i;
        p.number = 9.99;
        if (i == 0) {
            p.name1 = @"测试1111";
        }
        [p insertOrUpdateWithKeys:@[@"name"]];//插入表数据
    }
    NSMutableDictionary *dic = [NSMutableDictionary new];
    [dic setObject:@"测试5" forKey:@"name"];
    [Person deleteWithDic:dic];//删除表数据
    NSMutableDictionary *queryDic = [NSMutableDictionary new];
    [queryDic setObject:@"测试0" forKey:@"name"];
    queryDic = nil;
    [Person queryWithParams:queryDic responseModelBlock:^(NSArray *list) {
        NSLog(@"%@",list);
        Person *ps = list[0];
        NSLog(@"%@",ps.name1);
        NSLog(@"%d",ps.age);
        NSLog(@"%lf",ps.number);
    }];
    [Person dropTable];//清空表
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
