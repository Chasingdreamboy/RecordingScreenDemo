//
//  TreefintechAudioPlayer.h
//  treefintechBlue
//
//  Created by Ericydong on 2019/11/6.
//  Copyright © 2019 dashu. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import <RBDMuteSwitch.h>

NS_ASSUME_NONNULL_BEGIN


////检测是否开启静音按钮
//@interface TreefintechMuteSwitch : RBDMuteSwitch <RBDMuteSwitchDelegate>
//@property (copy, nonatomic) void(^callback)(BOOL isMuted);
//+ (void)detectMuteSwitch:(void(^)(BOOL isMuted))callback;
//@end


@interface TreefintechAudioPlayer : NSObject

+ (void)play:(NSURL *)url;
+ (void)stop;
+ (BOOL)isPlayGuidenceMusic;
+ (void)setPlayGuidenceMusic:(BOOL)open audioURL:(NSString * _Nullable)url;



+ (void)startPlay;

@end

NS_ASSUME_NONNULL_END
