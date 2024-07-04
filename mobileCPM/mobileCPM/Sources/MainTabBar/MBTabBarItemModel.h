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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MBBaseModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface MBTabBarItemModel : MBBaseModel

@property (nonatomic, copy) NSString *className;      // 类名称
@property (nonatomic, copy) NSString *title;          // 名称
@property (nonatomic, copy) NSString *image;          // 正常状态下的图片
@property (nonatomic, copy) NSString *selectedImage;  // 选中状态下的图片
@property (nonatomic, strong) UIFont *font;           // 字体 degault：14
@property (nonatomic, strong) UIFont *selectedFont;   // 选中状态下的字体 default：粗体14
@property (nonatomic, assign) BOOL showBadge;         // 是否显示标记（消息小红点） default:NO

// 预留字段
@property (nonatomic, assign) NSInteger bagdeValue;  // 标记值（未读消息数量）
@property (nonatomic, strong) NSDate *startTime;     // 开始时间
@property (nonatomic, strong) NSDate *endTime;       // 结束时间

@end

NS_ASSUME_NONNULL_END
