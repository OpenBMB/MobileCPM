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

#import "MBMainTabBarViewModel.h"
#import "MBTabBarItemModel.h"

#import "MBBaseModel.h"

@interface MBMainTabBarViewModel ()

@property (nonatomic, strong, readwrite) NSMutableArray *tabBarData;

@end

@implementation MBMainTabBarViewModel

- (instancetype)init {
    self = [super init];
    
    if (self) {
        [self initTabBarData];
    }
    return self;
}

- (void)initTabBarData {
    self.tabBarData = [NSMutableArray array];
    
    NSArray *array = @[
        @{
            @"className": @"MBHomeViewController",
            @"title": @"首页",
            @"image": @"tabbar_home_normal",
            @"selectedImage": @"tabbar_home_selected"},
        @{
            @"className": @"MBSettingViewController",
            @"title": @"设置",
            @"image": @"tabbar_me_normal",
            @"selectedImage": @"tabbar_me_selected"},
    ];
    
    for (NSDictionary *obj in array) {
        MBTabBarItemModel *model = [MBTabBarItemModel modelWithDictionary:obj];
        if (!model) continue;
        [self.tabBarData addObject:model];
    }
}

@end
