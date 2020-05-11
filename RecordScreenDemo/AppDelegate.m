//
//  AppDelegate.m
//  RecordScreenDemo
//
//  Created by Ericydong on 2019/12/15.
//  Copyright © 2019 com.dashu.ios.gongfudai.uploadInhouse. All rights reserved.
//

#import "AppDelegate.h"
#import "TreefintechAudioPlayer.h"
#import "TreefintechVideoManager.h"
#import "AvdioManager.h"
#import <UserNotifications/UserNotifications.h>

@interface AppDelegate ()<UNUserNotificationCenterDelegate>

@end

@implementation AppDelegate


void MyHoleNotificationCallback(CFNotificationCenterRef center,
                                void * observer,
                                CFStringRef name,
                                void const * object,
                                CFDictionaryRef userInfo) {
    NSString *identifier = (__bridge NSString *)name;
    NSObject *sender = (__bridge NSObject *)observer;
    //    NSDictionary *info = (__bridge NSDictionary *)userInfo;
    //    NSDictionary *info = CFBridgingRelease(userInfo);
    AppDelegate *appdelegate = (AppDelegate *)sender;
    if ([identifier isEqualToString:broadcastFinishRecordingNotification]) {
        [TreefintechVideoManager finishRecording:0];
        [appdelegate endRecording:identifier timeout:false];
    } else if ([identifier isEqualToString:broadcastStartRecordingNotification]) {
        [appdelegate startRecording];
    } else if ([identifier isEqualToString:broadcastTimeoutRecordingNotification]) {
        [TreefintechVideoManager finishRecording:50015];
        [appdelegate endRecording:identifier timeout:true];
    }
    
}




- (void)startRecording {
    //开始播放音乐
    [TreefintechAudioPlayer startPlay];
    //打开支付宝
//    NSString *openPath = DS_GET_DECRYPT(TreefintechRecordAlipayPathKey);
//    if (!isAvailable(openPath)) {
        NSString *openPath = openPath = @"alipays://";
//    }
    
    NSURL *url = [NSURL URLWithString:openPath];
    UIApplication *applocation = [UIApplication sharedApplication];
    if (@available(iOS 10.0, *)) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
            
        }];
    } else {
        [applocation openURL:url];
    }
    
}
- (void)endRecording:(NSString *)identifier timeout:(BOOL)isTimeout {
    [TreefintechAudioPlayer stop];
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
        return;
    }
    
    if (@available(iOS 10.0, *)) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        // 标题
        NSString *title = @"录制视频已保存到功夫贷";
        if (isTimeout) {
            title = [@"录制时间超出," stringByAppendingString:title];
        }
        content.title = title;
        content.subtitle = @"";
        // 内容
        content.body = @"请点击预览";
        // 声音
       // 默认声音
     //    content.sound = [UNNotificationSound defaultSound];
     // 添加自定义声音
        content.sound = [UNNotificationSound defaultSound];
//       content.sound = [UNNotificationSound soundNamed:@"Alert_ActivityGoalAttained_Salient_Haptic.caf"];
        // 角标 （我这里测试的角标无效，暂时没找到原因）
        content.badge = @0;
        // 多少秒后发送,可以将固定的日期转化为时间
        NSTimeInterval time = [[NSDate dateWithTimeIntervalSinceNow:1.0] timeIntervalSinceNow];
//        NSTimeInterval time = 10;
        // repeats，是否重复，如果重复的话时间必须大于60s，要不会报错
        UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:time repeats:NO];
        // 添加通知的标识符，可以用于移除，更新等操作
        
        
  
        
        
        
        
        
        NSString *identifier = [NSString stringWithFormat:@"%lld", (long long)([[NSDate date] timeIntervalSince1970] * 1000)];
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
        
        [center addNotificationRequest:request withCompletionHandler:^(NSError *_Nullable error) {
            NSLog(@"成功添加推送");
        }];
    }
}






/// 检测应用录屏
//- (void)screenshots:(NSNotification *)notification NS_AVAILABLE_IOS(11.0) {
//
//    BOOL flag = [ReplayFileUtil gongfudaiRecordingScreenFlag];
//    if (flag) {
//        DSLog(@"功夫贷自己在录");
//        return;
//    }
//
//    UIScreen *screen = (UIScreen *)notification.object;
//    if (screen.isCaptured) {
//        NSLog(@"正在录屏");
//        static UIWindow * window;
//        if (!window) {
//            window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
//            window.windowLevel = UIWindowLevelAlert;
//            TreefintechRecordWarningController *warningController = [[TreefintechRecordWarningController alloc] init];
//            warningController.result = ^(TreefintechRecordWarningOperationType type) {
//                if (type == TreefintechRecordWarningOperationTypeContinue) {
//                    window = nil;
//                } else {
//                    window = nil;
//                    [self logout];
//                }
//            };
//            window.rootViewController = warningController;
//        }
//        window.hidden = false;
//    } else {
//        NSLog(@"关闭录屏");
//    }
//
//}




- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    self.window.backgroundColor = [UIColor whiteColor];

//    NSString *userIds = @"1000000134,1000000149";
//    NSString *encrypt = userIds.tripleDESEncrypt;
//    DSLog(@"encrypt == %@", encrypt);
//    NSString *decrypt = encrypt.tripleDESDecrypt;
//    DSLog(@"decrypt == %@", decrypt);
    

        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = self;
        //用户获取用户的授权状态
        [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
            //当用户改变推送设置时触发
            if (settings.authorizationStatus == UNAuthorizationStatusNotDetermined) {
                //user hasnnot make a choise
                NSLog(@"notification NotDetermined!!");
                [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert) completionHandler:^(BOOL granted, NSError * _Nullable error) {
                    if (!error) {
                        //get the authorization of the user
                    }
                }];

                
                
                
            } else if (settings.authorizationStatus == UNAuthorizationStatusDenied) {;
                //user reject the request of notification
                NSLog(@"notification Denied");
            }else if (settings.authorizationStatus == UNAuthorizationStatusAuthorized) {
                //user accept the request of notification
                NSLog(@"notification Authorized");
            }
        }];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
//        UNNotificationAction *overview = [UNNotificationAction actionWithIdentifier:NotificationActionOneIdent title:@"查看详情" options:UNNotificationActionOptionForeground|UNNotificationActionOptionAuthenticationRequired];
//        UNNotificationAction *ignore = [UNNotificationAction actionWithIdentifier:NotificationActionTwoIdent title:@"忽略消息" options:UNNotificationActionOptionNone];
//        UNNotificationCategory *category = [UNNotificationCategory categoryWithIdentifier:NotificationCategoryIdent actions:@[overview, ignore] intentIdentifiers:@[] options:UNNotificationCategoryOptionCustomDismissAction];
//        [[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:[NSSet setWithObject:category]];
        


    
    
    
    
    //在iOS13.0之前打开麦克风才会收集到声音
    
    //初始化session确保可以在后台播放音乐,且不受静音键控制
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error = nil;
//    [session setCategory:AVAudioSessionCategoryPlayback error:&error];
    [session setCategory:AVAudioSessionCategoryMultiRoute error:&error];
    
    NSAssert(!error, @"设置session异常");
    [session setActive:YES error:&error];
    NSAssert(!error, @"设置session异常");
    
    
    
    
    
    
    
    
    

    
    //注册录屏推送
    [CFNotificationCenterHelper registerForNotificationsWithobserver:self identifiers:@[broadcastStartRecordingNotification, broadcastFinishRecordingNotification, broadcastTimeoutRecordingNotification] callback:MyHoleNotificationCallback];

    
    
    



   
    return YES;
}






@end
