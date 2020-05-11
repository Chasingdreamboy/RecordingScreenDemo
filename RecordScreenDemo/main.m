//
//  main.m
//  RecordScreenDemo
//
//  Created by Ericydong on 2019/12/15.
//  Copyright © 2019 com.dashu.ios.gongfudai.uploadInhouse. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
