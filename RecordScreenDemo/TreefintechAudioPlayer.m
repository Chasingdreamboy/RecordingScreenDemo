//
//  TreefintechAudioPlayer.m
//  treefintechBlue
//
//  Created by Ericydong on 2019/11/6.
//  Copyright © 2019 dashu. All rights reserved.
//

#import "TreefintechAudioPlayer.h"
#import <AVFoundation/AVFoundation.h>
//#import "NSString+Expand.h"
//#import "TreefintechAppGroupManager.h"






//@implementation TreefintechMuteSwitch
//
//+ (TreefintechMuteSwitch *)defaultMuteSwitch {
//    return (TreefintechMuteSwitch *)[self sharedInstance];
//}
//+ (void)detectMuteSwitch:(void(^)(BOOL isMuted))callback {
//    TreefintechMuteSwitch *muteSwitch = [self defaultMuteSwitch];
//    muteSwitch.delegate = muteSwitch;
//    muteSwitch.callback = callback;
//    [muteSwitch detectMuteSwitch];
//}
//
//
//- (void)isMuted:(BOOL)muted {
//    void(^callback)(BOOL) = self.callback;
//    if (callback) {
//        callback(muted);
//    }
//}
//
//
//
//@end




@interface TreefintechAudioPlayer ()
@property (strong, nonatomic) AVPlayer *player;
@property (copy, nonatomic) NSString *audioPath;
@property (assign, nonatomic) BOOL open;
@end


@implementation TreefintechAudioPlayer






BOOL isAvailable(NSString *str) {
    
    if (![str isKindOfClass:[NSString class]]) {
        return false;
    }
    if ([str isEqual:[NSNull null]]) {
        return false;
    }
    if ([str isEqualToString:@"<null>"] || [str isEqualToString:@"<NULL>"] || [str isEqualToString:@"(null)"]) {
         return false;
    }
    if (!str || str == NULL) {
        return false;
    }
    if (!str.length) {
        return false;
    }
    return true;
}







+ (TreefintechAudioPlayer *)sharedInstance {
    static dispatch_once_t onceToken;
    static TreefintechAudioPlayer *manager;
    dispatch_once(&onceToken, ^{
        manager = [[TreefintechAudioPlayer alloc] init];
    });
    return manager;
}
+ (NSString *)audioRootPath {
    static NSString *_audioRootPath;
    if (!_audioRootPath) {
        NSString *documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).firstObject;
        NSString *audioRootPath = [documentPath stringByAppendingPathComponent:@"Audio"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager isExecutableFileAtPath:audioRootPath]) {
            NSError *error = nil;
            BOOL success = [fileManager createDirectoryAtPath:audioRootPath withIntermediateDirectories:true attributes:@{} error:&error];
            NSAssert(success || !error, @"创建路径出现错误");
//            DSLog(@"创建路径成功");
        }
        _audioRootPath = audioRootPath;
    }
    return _audioRootPath;
}

+ (BOOL)isPlayGuidenceMusic {
    return [self sharedInstance].open;
}
+ (void)setPlayGuidenceMusic:(BOOL)open audioURL:(NSString * _Nullable)url {
    
    //清理之前保存的url
    [self sharedInstance].audioPath = nil;
    
    
    //不播放录音
    if (!isAvailable(url)) {
        [self sharedInstance].open = false;
        return;
    }
    
    
    [self sharedInstance].open = open;
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"http(s)?:\\/\\/([\\w-]+\\.)+[\\w-]+(\\/[\\w- .\\/?%&=]*)?"];
    
    BOOL match = [predicate evaluateWithObject:url];
    if (!match) {
        [self sharedInstance].audioPath = url;
        //本地音频
        return;
    }
    
    

}

- (AVPlayer *)player {
    if (!_player) {
        _player = [[AVPlayer alloc] init];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    }
    return _player;
}
- (void)playEnd {
    NSLog(@"播放结束!");
    
}
+ (void)play:(NSURL *)url {
//    AVAudioSession *session = [AVAudioSession sharedInstance];
//    [session setActive:YES error:nil];
//    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    //每次开始播放时设置session防止被意外改变
    AVPlayerItem *item = [[AVPlayerItem alloc] initWithURL:url];
    AVPlayer *player = [TreefintechAudioPlayer sharedInstance].player;
    [player replaceCurrentItemWithPlayerItem:item];
    [player play];
}
+ (void)stop {
    AVPlayer *player = [TreefintechAudioPlayer sharedInstance].player;
    [player pause];
}

+ (void)startPlay {
    TreefintechAudioPlayer *manager = [self sharedInstance];
    BOOL needGuidenceMusic = manager.open;
    if (needGuidenceMusic) {
        NSString *path = [self sharedInstance].audioPath;
        NSURL *playerUrl = [NSURL fileURLWithPath:path];
        //        if (manager.audioURL) {
        //            playerUrl = [NSURL URLWithString:manager.audioURL];
        //        }
        [TreefintechAudioPlayer play:playerUrl];
    }
    
    
    
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}


@end
