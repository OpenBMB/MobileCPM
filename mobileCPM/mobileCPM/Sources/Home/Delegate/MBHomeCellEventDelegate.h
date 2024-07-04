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

#ifndef MBHomeCellEventDelegate_h
#define MBHomeCellEventDelegate_h

#import <Foundation/Foundation.h>
#import "MBHomeCardModel.h"

/// 首页上内嵌的、具体卡片点击事件
@protocol MBHomeCellEventDelegate <NSObject>

@optional

/// 首页点击通用卡片事件代理
/// - Parameters:
///   - object: model
///   - extra: 额外的参数
- (void)didClickCellWithModel:(MBHomeCardModel *_Nullable)object
                        extra:(NSDictionary *_Nullable)extra;

@end


#endif /* MBHomeCellEventDelegate_h */
