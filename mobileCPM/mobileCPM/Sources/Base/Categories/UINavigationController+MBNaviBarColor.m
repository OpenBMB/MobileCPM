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

#import "UINavigationController+MBNaviBarColor.h"

@implementation UINavigationController (MBNaviBarColor)

/// 设置导航栏颜色
-(void)setNavigationBackgroundColor:(UIColor *)color {
    NSDictionary *dic = @{NSForegroundColorAttributeName : [UIColor blackColor],
                              NSFontAttributeName : [UIFont systemFontOfSize:18]};
    
    if (@available(iOS 15.0, *)) {
        // 滚动状态
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        // 设置为不透明
        appearance.backgroundEffect = nil;
        appearance.backgroundImage = [self mb_imageWithColor: color size:CGSizeMake(12, 12)];
        appearance.shadowColor = color;
        appearance.backgroundColor = color;
        
        appearance.titleTextAttributes = dic;
        
        // 静止状态
        UINavigationBarAppearance *appearance2 = [[UINavigationBarAppearance alloc] init];
        // 设置为不透明
        appearance2.backgroundEffect = nil;
        appearance2.backgroundImage = [self mb_imageWithColor: color size:CGSizeMake(12, 12)];
        appearance2.shadowColor = color;
        appearance2.backgroundColor = color;
        
        appearance2.titleTextAttributes = dic;
        
        self.navigationBar.scrollEdgeAppearance = appearance;
        self.navigationBar.standardAppearance = appearance2;
    } else {
        self.navigationBar.titleTextAttributes = dic;
        [self.navigationBar setShadowImage:[[UIImage alloc] init]];
        [self.navigationBar setBackgroundImage:[self mb_imageWithColor: color size:CGSizeMake(12, 12)] forBarMetrics:UIBarMetricsDefault];
    }
}

- (UIImage *)mb_imageWithColor:(UIColor *)color size:(CGSize)size {
    if (color == nil) return nil;
    
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return theImage;
}

@end
