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

#import "MBBaseModel.h"
#import <IGListDiffKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 首页瀑布流-数据-model
@interface MBHomeCardModel : MBBaseModel<IGListDiffable>

@property (nonatomic, copy, nullable) NSString *name;

@property (nonatomic, copy, nullable) NSString *avatar;

@property (nonatomic, copy, nullable) NSString *prompt;

@property (nonatomic, copy, nullable) NSString *prologue;

@property (nonatomic, copy, nullable) NSString *model_name_or_path;

@property (nonatomic, readwrite) CGFloat cellHeight;

/// iglistkit 需要
@property (nonatomic, readonly) NSString *uuid;

@end

NS_ASSUME_NONNULL_END
