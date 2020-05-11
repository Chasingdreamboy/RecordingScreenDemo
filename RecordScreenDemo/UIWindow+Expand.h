//
//  UIWindow+Expand.h
//  gongfudai
//
//  Created by David Lan on 15/8/24.
//  Copyright (c) 2018年 treefintech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface UIWindow(Expand)
+ (UIWindow*)getWindow;
- (UIViewController *)visibleViewController;
@end
