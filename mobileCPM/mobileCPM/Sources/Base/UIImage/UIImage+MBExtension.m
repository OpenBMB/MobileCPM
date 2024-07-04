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

#import "UIImage+MBExtension.h"

@implementation UIImage (MBExtension)

+ (UIImage *)mb_imageWithColor:(UIColor *)color size:(CGSize)size {
    if (color == nil) return nil;
    
    CGRect rect=CGRectMake(0.0f, 0.0f, size.width, size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return theImage;
}

+ (UIImage *)mb_imageWithColor:(UIColor *)color size:(CGSize)size cornerRadius:(CGFloat)cornerRadius {
    UIImage *originalImage = [self mb_imageWithColor:color size:size];
    CGRect rect = CGRectMake(0, 0, originalImage.size.width, originalImage.size.height);
    UIGraphicsBeginImageContextWithOptions(originalImage.size, NO, 0.0);
    [[UIBezierPath bezierPathWithRoundedRect:rect
                                cornerRadius:cornerRadius] addClip];
    [originalImage drawInRect:rect];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)mb_imageWithColor:(UIColor *)color size:(CGSize)size cornerRadius:(CGFloat)cornerRadius borderWidth:(CGFloat)borderWidth borderColor:(UIColor *)borderColor {
    UIImage *originalImage = [self mb_imageWithColor:color size:size];
    
    CGRect rect = CGRectMake(0, 0, originalImage.size.width, originalImage.size.height);
    UIGraphicsBeginImageContextWithOptions(originalImage.size, NO, 0.0);
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithRoundedRect:rect
                                                          cornerRadius:cornerRadius];
    [circlePath addClip];
    [originalImage drawInRect:rect];
    
    circlePath.lineWidth = borderWidth;
    [borderColor setStroke];
    [circlePath stroke];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)mb_imageWithColor:(UIColor *)color size:(CGSize)size opaque:(BOOL)opaque cornerRadius:(CGFloat)cornerRadius borderWidth:(CGFloat)borderWidth borderColor:(UIColor *)borderColor {
    UIImage *originalImage = [self mb_imageWithColor:color size:size];
    
    CGRect rect = CGRectMake(0, 0, originalImage.size.width, originalImage.size.height);
    UIGraphicsBeginImageContextWithOptions(originalImage.size, opaque, 0.0);
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithRoundedRect:rect
                                                          cornerRadius:cornerRadius];
    [circlePath addClip];
    [originalImage drawInRect:rect];
    
    circlePath.lineWidth = borderWidth;
    [borderColor setStroke];
    [circlePath stroke];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark - 图片处理
- (NSData *)mb_covertToData {
    NSData *data = UIImageJPEGRepresentation(self, 1);
    return data;
}

// 裁切图片
- (UIImage *)mb_cropImageToSize:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

// 按大小压缩
- (NSData *)mb_compressToLimitLength:(NSInteger)limitLength {
    CGFloat compression = 1;  
    NSData *data = UIImageJPEGRepresentation(self, compression);
    if (data.length < limitLength) return data;
    CGFloat max = 1;
    CGFloat min = 0;
    for (int i = 0; i < 6; ++i) {
        compression = (max + min) / 2;
        data = UIImageJPEGRepresentation(self, compression);
        if (data.length < limitLength * 0.9) {
            min = compression;
        } else if (data.length > limitLength) {
            max = compression;
        } else {
            break;
        }
    }
    return data;
}

//https://blog.csdn.net/qq_30513483/article/details/86741093
-(NSData *)mb_compressOptimizeWithMaxLength:(NSUInteger)maxLength {
    // Compress by quality
    CGFloat compression = 1;
    NSData *data = UIImageJPEGRepresentation(self, compression);
    //NSLog(@"Before compressing quality, image size = %ld KB",data.length/1024);
    if (data.length < maxLength) return data;
    
    CGFloat max = 1;
    CGFloat min = 0;
    for (int i = 0; i < 6; ++i) {
        compression = (max + min) / 2;
        data = UIImageJPEGRepresentation(self, compression);
        //NSLog(@"Compression = %.1f", compression);
        //NSLog(@"In compressing quality loop, image size = %ld KB", data.length / 1024);
        if (data.length < maxLength * 0.9) {
            min = compression;
        } else if (data.length > maxLength) {
            max = compression;
        } else {
            break;
        }
    }
    //NSLog(@"After compressing quality, image size = %ld KB", data.length / 1024);
    if (data.length < maxLength) return data;
    UIImage *resultImage = [UIImage imageWithData:data];
    // Compress by size
    NSUInteger lastDataLength = 0;
    while (data.length > maxLength && data.length != lastDataLength) {
        lastDataLength = data.length;
        CGFloat ratio = (CGFloat)maxLength / data.length;
        //NSLog(@"Ratio = %.1f", ratio);
        CGSize size = CGSizeMake((NSUInteger)(resultImage.size.width * sqrtf(ratio)),
                                 (NSUInteger)(resultImage.size.height * sqrtf(ratio))); // Use NSUInteger to prevent white blank
        UIGraphicsBeginImageContext(size);
        [resultImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
        resultImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        data = UIImageJPEGRepresentation(resultImage, compression);
        //NSLog(@"In compressing size loop, image size = %ld KB", data.length / 1024);
    }
    //NSLog(@"After compressing size loop, image size = %ld KB", data.length / 1024);
    return data;
}

/// 指定宽度按比例缩放
-(UIImage *)mb_imageCompressForWidth:(UIImage *)sourceImage targetWidth:(CGFloat)defineWidth {
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = defineWidth;
    CGFloat targetHeight = height / (width / targetWidth);
    CGSize size = CGSizeMake(targetWidth, targetHeight);
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0, 0.0);
    
    if(CGSizeEqualToSize(imageSize, size) == NO) {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if(widthFactor > heightFactor){
            scaleFactor = widthFactor;
        }else{
            scaleFactor = heightFactor;
        }
        scaledWidth = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        if(widthFactor > heightFactor){
            thumbnailPoint.y = (targetHeight - scaledHeight) *0.5;
        }else if(widthFactor < heightFactor){
            thumbnailPoint.x = (targetWidth - scaledWidth) *0.5;
        }
    }
    UIGraphicsBeginImageContext(size);
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    [sourceImage drawInRect:thumbnailRect];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    if(newImage == nil) {
        NSLog(@"scale image fail");
    }
    
    UIGraphicsEndImageContext();
    return newImage;
}

/// 按比例缩放,size是你要把图显示到 多大区域, 例如:CGSizeMake(300, 400)
-(UIImage *)mb_imageCompressForSize:(UIImage *)sourceImage targetSize:(CGSize)size {
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = size.width;
    CGFloat targetHeight = size.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0, 0.0);
    
    if(CGSizeEqualToSize(imageSize, size) == NO) {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if(widthFactor > heightFactor){
            scaleFactor = widthFactor;
        }else{
            scaleFactor = heightFactor;
        }
        scaledWidth = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        if(widthFactor > heightFactor) {
            thumbnailPoint.y = (targetHeight - scaledHeight) *0.5;
        } else if(widthFactor < heightFactor){
            thumbnailPoint.x = (targetWidth - scaledWidth) *0.5;
        }
    }
    
    UIGraphicsBeginImageContext(size);
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    [sourceImage drawInRect:thumbnailRect];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    if(newImage == nil) {
        NSLog(@"scale image fail");
    }
    UIGraphicsEndImageContext();
    return newImage;
}

@end
