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

#import "MBHomeViewModel.h"

@interface MBHomeViewModel ()

@property (nonatomic, readwrite) BOOL isEnd;

@end

@implementation MBHomeViewModel

- (void)fetchHomeCardWithLoadMore:(BOOL)loadmore
                          success:(void(^)(NSMutableArray<MBHomeSectionModel *> *responseArray))success
                          failure:(void(^)(NSString *errorCode, NSString *errorMsg))failureBlock {
    
    if (loadmore) {
        return;
    }

    self.isEnd = NO;

    // 从磁盘加载 json
    NSString *path = [[NSBundle mainBundle] pathForResource:@"local_data" ofType:@"json"];
    NSError *error;
    NSString *jsonString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"Error loading file: %@", error.localizedDescription);
        return;
    }

    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    if (!jsonData) {
        NSLog(@"Error converting JSON string to data: string may not be a valid JSON.");
        return;
    }

    NSMutableDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                      options:NSJSONReadingMutableContainers
                                                                        error:&error];
    
    if (error) {
        NSLog(@"Error parsing JSON data: %@", error.localizedDescription);
        return;
    }

    MBHomeSectionModel *waterfallSection = [MBHomeSectionModel new];
    waterfallSection.data = @[].mutableCopy;
    waterfallSection.type = @"waterfall";

    NSArray *keys = [jsonDict allKeys];
    
    for (id key in keys) {
        NSDictionary *value = [jsonDict objectForKey:key];
        if ([value isKindOfClass:NSDictionary.class]) {
            MBHomeCardModel *tmp = [MBHomeCardModel modelWithJSON:value];
            if ([tmp.avatar length]) {
                CGFloat width = [[UIApplication sharedApplication] keyWindow].frame.size.width;
                width = (width - 12 - 12 - 6) / 2;
                CGFloat height = ceilf(width * 1.55f);
                tmp.cellHeight = height;
                [waterfallSection.data addObject:tmp];
            }
        }
    }
    
    NSMutableArray<MBHomeSectionModel *> *finalArray = [NSMutableArray new];
    [finalArray addObject:waterfallSection];

    if (success) {
        
        if (!loadmore) {
            // 下拉刷新
            success(finalArray);
        } else {
            // 加载更多
            success(@[finalArray.lastObject].mutableCopy);
        }
        
    }
}

@end
