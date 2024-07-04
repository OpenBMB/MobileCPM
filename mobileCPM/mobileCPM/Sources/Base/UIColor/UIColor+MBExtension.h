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

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (MBExtension)

/// 获取UIColor对象
/// - Parameter string: 以#开头的字符串（不区分大小写），如：#AbFFff，若需要alpha，则传#abcdef255，不传默认为1
+ (UIColor *)mb_colorWithString:(NSString *)string;

+ (UIColor *)mb_colorWithString:(NSString *)string alpha:(CGFloat)alpha;


/// 按HEX取渐变色
/// @param start 开始颜色
/// @param end 结束颜色
/// @param height 高度
+ (UIColor *)mb_colorFromColor:(UIColor *)start toColor:(UIColor *)end height:(CGFloat)height;


/// 按RGB取渐变色
/// @param start 开始颜色
/// @param end 结束颜色
/// @param ratio  差值比例
+ (UIColor *)mb_colorFromColor:(UIColor *)start toColor:(UIColor *)end ratio:(CGFloat)ratio;

// 随机色
+ (UIColor *)randomColor;

@end

NS_ASSUME_NONNULL_END
