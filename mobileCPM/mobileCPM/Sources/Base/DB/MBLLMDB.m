/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "MBLLMDB.h"
#import <FMDB.h>

@interface MBLLMDB()

@property (nonatomic, strong) FMDatabaseQueue *dbQueue;

@end

static MBLLMDB *shared;
static dispatch_once_t onceToken;

@implementation MBLLMDB

+ (MBLLMDB *)sharedInstance {
    dispatch_once(&onceToken, ^{
        shared = [[MBLLMDB alloc] init];
        [shared createDB];
    });
    return shared;
}

- (void)resetInstance {
    shared = nil;
    onceToken = 0;
}

#pragma mark - private methods

- (void)createDB {
    BOOL initdbResult = [self initDatabase];
    
    NSLog(@"DEBUG::: DB initdb result is:%@", @(initdbResult));
}

- (NSString *)dbPath {
    NSString * docsdir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *loginUserId = @"user_id";
    NSString *appendPart = [NSString stringWithFormat:@"%@_llmdb", loginUserId];
    NSString *dataFilePath = [docsdir stringByAppendingPathComponent:appendPart];
    return dataFilePath;
}

- (BOOL)initDatabase {
    NSString *filePath = [self dbPath];
    
    NSString *createTableStr = @"CREATE TABLE IF NOT EXISTS MESSAGES(role VARCHAR(50) NOT NULL, content TEXT NOT NULL, create_at VARCHAR(15) NOT NULL);";
    _dbQueue = [FMDatabaseQueue databaseQueueWithPath:filePath];
    __block BOOL ret1 = NO;
    [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        ret1 = [db executeUpdate:createTableStr];
        if (!ret1) {
            
        }
    }];
    return ret1;
}

- (BOOL)saveModel:(NSDictionary *)dict {
    
    NSString *role = dict[@"role"];
    NSString *content = dict[@"content"];
    NSString *tis = [NSString stringWithFormat:@"%@",@([[NSDate date] timeIntervalSince1970])];
    __block NSArray *arguments = @[role?:@"", content?:@"", tis?:@""];
    __block BOOL ret = NO;
    [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        NSError *error;
        ret = [db executeUpdate:[NSString stringWithFormat:@"INSERT INTO MESSAGES(%@,%@, %@) VALUES (?,?,?);",@"role", @"content", @"create_at"] values:arguments error:&error];
        NSLog(@"DEBUG:::: LLMDB insert resutl is:%@", @(ret));
    }];
    return ret;
}

- (void)removeAllObjects {
    __block BOOL ret = NO;
    [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        NSError *error;
        ret = [db executeUpdate:[NSString stringWithFormat:@"DELETE FROM MESSAGES"] values:nil error:&error];
        NSLog(@"DEBUG:::: LLMDB insert resutl is:%@", @(ret));
    }];
}

- (NSArray<NSDictionary *> *)loadAllMessages {
    
    __block NSMutableArray *modelArray = [[NSMutableArray alloc] init];
    
    [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet *set = [db executeQuery:@"SELECT * FROM MESSAGES"];
        while ([set next]) {
            NSMutableDictionary *dict = @{}.mutableCopy;
            dict[@"role"] = [set stringForColumn:@"role"];
            dict[@"content"] = [set stringForColumn:@"content"];
            dict[@"create_at"] = [set stringForColumn:@"create_at"];
            [modelArray addObject:dict];
        }
    }];
    
    return modelArray.copy;
}

@end
