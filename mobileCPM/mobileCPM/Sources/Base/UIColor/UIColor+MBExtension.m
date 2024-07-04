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

#import "UIColor+MBExtension.h"

@implementation UIColor (SAIExtension)

static NSInteger convertToInt(char c) {
    if (c >= '0' && c <= '9') {
        return c - '0';
    } else if (c >= 'a' && c <= 'f') {
        return c - 'a' + 10;
    } else if (c >= 'A' && c <= 'F') {
        return c - 'A' + 10;
    }
    return printf("字符非法!");
}

+ (UIColor *)mb_colorWithString:(NSString *)string {
    if (![[string substringToIndex:0] isEqualToString:@"#"] && string.length < 7) {
        return nil;
    }
    
    const char *str = [[string substringWithRange:NSMakeRange(1, 6)] UTF8String];
    
    CGFloat red = (convertToInt(str[0]) * 16 + convertToInt(str[1])) / 255.0f;
    CGFloat green = (convertToInt(str[2]) * 16 + convertToInt(str[3])) / 255.0f;
    CGFloat blue = (convertToInt(str[4]) * 16 + convertToInt(str[5])) / 255.0f;
    
    NSString *alphaString = [string substringFromIndex:7];
    CGFloat alpha = [alphaString isEqualToString:@""] ? 1 : alphaString.floatValue/255;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

+ (UIColor *)mb_colorWithString:(NSString *)string alpha:(CGFloat)alpha {
    if (![[string substringToIndex:0] isEqualToString:@"#"] && string.length < 7) {
        return nil;
    }
    const char *str = [[string substringWithRange:NSMakeRange(1, 6)] UTF8String];
    
    CGFloat red = (convertToInt(str[0]) * 16 + convertToInt(str[1])) / 255.0f;
    CGFloat green = (convertToInt(str[2]) * 16 + convertToInt(str[3])) / 255.0f;
    CGFloat blue = (convertToInt(str[4]) * 16 + convertToInt(str[5])) / 255.0f;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

+ (UIColor *)mb_colorFromColor:(UIColor *)start toColor:(UIColor *)end height:(CGFloat)height {
    CGSize size = CGSizeMake(1, height);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    
    NSArray *colors = [NSArray arrayWithObjects:(id)start.CGColor, (id)end.CGColor, nil];
    CGGradientRef gradient = CGGradientCreateWithColors(colorspace, (__bridge CFArrayRef)colors, NULL);
    CGContextDrawLinearGradient(context, gradient, CGPointMake(0, 0), CGPointMake(0, size.height), 0);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorspace);
    UIGraphicsEndImageContext();
    
    return [UIColor colorWithPatternImage:image];
}

+ (UIColor *)mb_colorFromColor:(UIColor *)start toColor:(UIColor *)end ratio:(CGFloat)ratio {
    if (ratio <= 0) {
        return start;
    }
    if (ratio >= 1) {
        return end;
    }
    CGFloat rs, gs, bs, as, re, ge, be, ae;
    
    if ([start getRed:&rs green:&gs blue:&bs alpha:&as] && [end getRed:&re green:&ge blue:&be alpha:&ae]) {
        return [UIColor colorWithRed:rs + ratio * (re - rs) green:gs + ratio * (ge - gs) blue:bs + ratio * (be - bs) alpha:as + ratio * (ae - as)];
    }
    
    return nil;
}

+ (UIColor *)randomColor {
    CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
    UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
    
    return color;
}

@end
