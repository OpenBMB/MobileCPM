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

#import "MBMainTabBarController.h"
#import "MBBaseTabBar.h"
#import "MBTabBarItemModel.h"
#import "MBMainTabBarViewModel.h"
#import "UIColor+MBExtension.h"

#import "mobileCPM-Swift.h"

@interface MBMainTabBarController ()<UITabBarControllerDelegate>

@property (nonatomic, strong) MBMainTabBarViewModel *viewModel;

@end

@implementation MBMainTabBarController

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupSubviews];
    [self addConstraints];
}

#pragma mark - Init Methods
- (void)setupSubviews {
    for (MBTabBarItemModel *obj in self.viewModel.tabBarData) {
        [self addChildViewControllerWithClassName:obj.className
                                            title:obj.title
                                        imageName:obj.image
                                selectedImageName:obj.selectedImage];
    }
    
    UIColor *defaultColor = [UIColor lightGrayColor];
    UIColor *selectColor = [UIColor mb_colorWithString:@"#5872FF"];
    
    NSDictionary *normalAttrs = @{NSForegroundColorAttributeName:defaultColor, NSFontAttributeName:[UIFont systemFontOfSize:11 weight:UIFontWeightRegular]};
    NSDictionary *selectedAttrs = @{NSForegroundColorAttributeName:selectColor, NSFontAttributeName:[UIFont systemFontOfSize:11 weight:UIFontWeightRegular]};
    
    if (@available(iOS 15.0, *)) {
        UITabBarAppearance *appearance = [UITabBarAppearance new];
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttrs;
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttrs;

        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = UIColor.whiteColor;
        self.tabBar.standardAppearance = appearance;
        self.tabBar.scrollEdgeAppearance = appearance;
        
    } else {
        UITabBar.appearance.unselectedItemTintColor = defaultColor;
        UITabBar.appearance.tintColor = selectColor;
    }
}

- (void)addConstraints {
    
}

#pragma mark - Private Methods

-(void)addChildViewControllerWithClassName:(NSString *)className
                                     title:(NSString *)title
                                 imageName:(NSString *)imageName
                         selectedImageName:(NSString *)selectedImageName{
    
    Class class = NSClassFromString(className);
    UIViewController *vc = [[class alloc] init];
    vc.tabBarItem.title = title;
    UIImage *image = [UIImage imageNamed:imageName];
    vc.tabBarItem.image = image;
    UIImage *selectedImage = [UIImage imageNamed:selectedImageName];
    vc.tabBarItem.selectedImage = [selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:vc];
    [self addChildViewController:navigation];
}

#pragma mark - Lazy Load

- (MBMainTabBarViewModel *)viewModel {
    if (_viewModel == nil) {
        _viewModel = [[MBMainTabBarViewModel alloc] init];
    }
    return _viewModel;
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    return YES;
}

@end
