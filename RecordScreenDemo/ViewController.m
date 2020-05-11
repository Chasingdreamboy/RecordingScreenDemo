//
//  ViewController.m
//  RecordScreenDemo
//
//  Created by Ericydong on 2019/12/15.
//  Copyright © 2019 com.dashu.ios.gongfudai.uploadInhouse. All rights reserved.
//

#import "ViewController.h"
#import "TreefintechVideoManager.h"
#import "TreefintechAudioPlayer.h"
#import "NSDate+Timestamp.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)start:(id)sender {
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"mp3"];
    
    [TreefintechAudioPlayer setPlayGuidenceMusic:true audioURL:path];
    [TreefintechVideoManager showToSuperView:self.view result:^(NSInteger statu) {
        
        
        
    }];
    
    
    
    
    
}


//
//- (void)cropWithVideoUrlStr:(NSURL *)videoUrl completion:(void (^)(NSURL *outputURL, Float64 videoDuration, BOOL isSuccess))completionHandle
//{
//    AVURLAsset *asset =[[AVURLAsset alloc] initWithURL:videoUrl options:nil];
//    
//    //获取视频总时长
//    Float64 endTime = CMTimeGetSeconds(asset.duration);
//    
//    if (endTime > 10)
//    {
//        endTime = 10.0f;
//    }
//    
//    Float64 startTime = 0;
//    
//    NSString *outputFilePath = [self createVideoFilePath];
//    
//    NSURL *outputFileUrl = [NSURL fileURLWithPath:outputFilePath];
//    
//    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:asset];
//    
//    if ([compatiblePresets containsObject:AVAssetExportPresetMediumQuality])
//    {
//        
//        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]
//                                               initWithAsset:asset presetName:AVAssetExportPresetPassthrough];
//        
//        NSURL *outputURL = outputFileUrl;
//        
//        exportSession.outputURL = outputURL;
//        exportSession.outputFileType = AVFileTypeMPEG4;
//        exportSession.shouldOptimizeForNetworkUse = YES;
//        
//        CMTime start = CMTimeMakeWithSeconds(startTime, asset.duration.timescale);
//        CMTime duration = CMTimeMakeWithSeconds(endTime - startTime,asset.duration.timescale);
//        CMTimeRange range = CMTimeRangeMake(start, duration);
//        exportSession.timeRange = range;
//        
//        [exportSession exportAsynchronouslyWithCompletionHandler:^{
//            switch ([exportSession status]) {
//                case AVAssetExportSessionStatusFailed:
//                {
//                    NSLog(@"合成失败：%@", [[exportSession error] description]);
//                    completionHandle(outputURL, endTime, NO);
//                }
//                    break;
//                case AVAssetExportSessionStatusCancelled:
//                {
//                    completionHandle(outputURL, endTime, NO);
//                }
//                    break;
//                case AVAssetExportSessionStatusCompleted:
//                {
//                    completionHandle(outputURL, endTime, YES);
//                }
//                    break;
//                default:
//                {
//                    completionHandle(outputURL, endTime, NO);
//                } break;
//            }
//        }];
//    }
//}


- (NSString *)createVideoFilePath {
    NSString *rootPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).firstObject;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *videos = [rootPath stringByAppendingPathComponent:@"Videos"];
    if (![fileManager fileExistsAtPath:videos]) {
        NSError *error = nil;
       BOOL success = [fileManager createDirectoryAtPath:videos withIntermediateDirectories:true attributes:@{} error:&error];
        if (success && !error) {
            NSLog(@"创建成功!");
        } else {
            NSLog(@"创建失败!");
        }

    } else {
        
        NSDirectoryEnumerator <NSString *> *enumerator = [fileManager enumeratorAtPath:videos];
        NSString *fileName = nil;
        while (fileName = [enumerator nextObject]) {
            
            NSError *error = nil;
            BOOL success = [fileManager removeItemAtPath:[videos stringByAppendingPathComponent:fileName] error:&error];
            if (success && !error) {
                NSLog(@"删除成功!");
            } else {
                NSLog(@"删除失败:%@", error);
            }
        }
        
        
        
    }
    
    NSString *timestamp = [[NSDate customeTimestampForVideoPath] stringByAppendingPathExtension:@"mp4"];
    NSString *videoPath = [videos stringByAppendingPathComponent:timestamp];
    return videoPath;
}

- (IBAction)scan:(id)sender {
    NSURL *url =  [TreefintechVideoManager VideoURLPathAtDefaultPath];
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *videoPath = [self createVideoFilePath];

    NSError *error = nil;
    BOOL success = [fileManager copyItemAtURL:url toURL:[NSURL fileURLWithPath:videoPath] error:&error];
    if (success && !error) {
        NSLog(@"文件复制成功");
    } else {
        NSLog(@"文件复制失败");
    }
    
    
    
    BOOL containMusic = false;
    AVAsset *asset = [AVAsset assetWithURL:url];
    NSArray<AVAssetTrack *> *tracks = asset.tracks;
    for (AVAssetTrack *track in tracks) {
        if ([track.mediaType isEqualToString: AVMediaTypeAudio]) {
            containMusic = true;
            break;
        }
    }
    
    if (containMusic) {
        NSLog(@"包含了音频");

    } else {
        NSLog(@"没有包含音频");
    }

    
    
    
    [TreefintechVideoManager scanVideoWithURL:[NSURL fileURLWithPath:videoPath] result:^(BOOL videoSourceAvailable) {
        
    }];
//    [self cropWithVideoUrlStr:url completion:^(NSURL *outputURL, Float64 videoDuration, BOOL isSuccess) {
        
        
        


//    }];
    
    
    
    
    
    
    
}


@end
