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

@interface UIImage (MBExtension)

#pragma mark - 创建图片
// 指定填充色、大小的图片
+ (UIImage *)mb_imageWithColor:(UIColor *)color size:(CGSize)size;
// 指定填充色、大小、圆角的图片
+ (UIImage *)mb_imageWithColor:(UIColor *)color size:(CGSize)size cornerRadius:(CGFloat)cornerRadius;
// 指定填充色、大小、圆角、外边框图片
+ (UIImage *)mb_imageWithColor:(UIColor *)color size:(CGSize)size cornerRadius:(CGFloat)cornerRadius borderWidth:(CGFloat)borderWidth borderColor:(UIColor *)borderColor;
// 指定填充色、大小、透明度、圆角、外边框图片
+ (UIImage *)mb_imageWithColor:(UIColor *)color size:(CGSize)size opaque:(BOOL)opaque cornerRadius:(CGFloat)cornerRadius borderWidth:(CGFloat)borderWidth borderColor:(UIColor *)borderColor;

#pragma mark - 图片处理
// 转换成NSData
- (NSData *)mb_covertToData;
// 裁切图片
- (UIImage *)mb_cropImageToSize:(CGSize)size;
// 压缩图片 - 按大小压缩
- (NSData *)mb_compressToLimitLength:(NSInteger)limitLength;

//https://blog.csdn.net/qq_30513483/article/details/86741093
-(NSData *)mb_compressOptimizeWithMaxLength:(NSUInteger)maxLength;

/// 按比例缩放,size是你要把图显示到 多大区域, 例如:CGSizeMake(300, 400)
-(UIImage *)mb_imageCompressForSize:(UIImage *)sourceImage targetSize:(CGSize)size;

/// 指定宽度按比例缩放
-(UIImage *)mb_imageCompressForWidth:(UIImage *)sourceImage targetWidth:(CGFloat)defineWidth;

@end

NS_ASSUME_NONNULL_END
