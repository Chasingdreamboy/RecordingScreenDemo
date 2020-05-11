//
//  SampleHandler.m
//  upload
//
//  Created by Ericydong on 2019/10/30.
//  Copyright © 2019 Ericydong. All rights reserved.
//


#import "SampleHandler.h"
#import <ReplayKit/ReplayKit.h>
#import "AvdioManager.h"
//#import "ConstString.h"
//#import "Authorization.h"
static NSErrorDomain const TreefintechGongFuDaiDomain = @"视频录制超时,录制已经中断";


@interface SampleHandler()

@end

@implementation SampleHandler


void stopRecordingNotification (CFNotificationCenterRef center,
                                void * observer,
                                CFStringRef name,
                                void const * object,
                                CFDictionaryRef userInfo)  {
    SampleHandler *sampleHander = (__bridge SampleHandler *)observer;
    
    NSString *notificationName = (__bridge NSString *)name;
    
    NSError *error = [NSError errorWithDomain:TreefintechGongFuDaiDomain code:999 userInfo:@{
        NSLocalizedFailureReasonErrorKey : @"离开录屏界面,停止录制视频",
    }];
    
    if ([broadcastTimeoutRecordingNotification isEqualToString:notificationName]) {
        error = [NSError errorWithDomain:TreefintechGongFuDaiDomain code:999 userInfo:@{
            NSLocalizedFailureReasonErrorKey : @"录制时长达到上限，录制结束",
        }];
    }
    
    
//    NSError *error = [NSError errorWithDomain:TreefintechGongFuDaiDomain code:DSOperationStateInterputError userInfo:@{
//        NSLocalizedFailureReasonErrorKey : @"离开录屏界面,停止录制视频",
//    }];
    [[ReplayFileUtil sharedInstanceManager] stopRecordingWithTimeout:true];
    [sampleHander finishBroadcastWithError:error];
}




- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
    // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
    
    [CFNotificationCenterHelper registerForNotificationsWithobserver:self identifier:broadcastStopRecordingNotification callback:stopRecordingNotification];
    [[ReplayFileUtil sharedInstanceManager] prepareToRecording];
    
}


/// 暂停录制
- (void)broadcastPaused {
    // User has requested to pause the broadcast. Samples will stop being delivered.
}

/// 重新开始录制
- (void)broadcastResumed {
    // User has requested to resume the broadcast. Samples delivery will resume.
}



//static CMTime lastTime ;
- (void)broadcastFinished {
    @synchronized (self) {
        NSLog(@"broadcastFinished:Normal");
        [[ReplayFileUtil sharedInstanceManager] stopRecordingWithTimeout:false];
    }
    
    
    // User has requested to finish the broadcast.
}
- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    
    
    
//    CFRetain(sampleBuffer);
//    dispatch_async([ReplayFileUtil sharedInstanceManager].writeQueue, ^{
        
        ReplayFileUtil *util = [ReplayFileUtil sharedInstanceManager];
        switch (sampleBufferType) {
            case RPSampleBufferTypeVideo: {
                //视频文件
                // Handle video sample buffer
                @autoreleasepool {
                    if (util.assetWriter.status == AVAssetWriterStatusFailed) {
                        //                    [self stopRecording];
                        [[ReplayFileUtil sharedInstanceManager] stopRecordingWithTimeout:false];
                        return;
                    }
                    
                    if (util.assetWriter.status == AVAssetWriterStatusCompleted) {
                        NSLog(@"完成录制");
                    }
                    
                    
                    
                    if (CMSampleBufferDataIsReady(sampleBuffer)) {
                        if ( util.assetWriter.status == AVAssetWriterStatusUnknown) {
                            
                            CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                            
                            //丢弃无用的帧
                            //                        int64_t videopts  = CMTimeGetSeconds(pts) * 1000;
                            //                        if (videopts < 0) {
                            //                            return;
                            //                        }
                            BOOL sucess = [util.assetWriter startWriting];
                            [util.assetWriter startSessionAtSourceTime:pts];
                            
                            if (util.assetWriter.status != AVAssetWriterStatusWriting) {
                                return;
                            }
                            
                            
                            NSLog(@"启动%@", sucess ? @"成功" : @"失败");
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [util beginRecordingWithTimeout:^{
                                    NSError *error = [NSError errorWithDomain:TreefintechGongFuDaiDomain code:999 userInfo:@{
                                        NSLocalizedFailureReasonErrorKey : @"录制时长达到上限，录制结束",
                                    }];
                                    [self finishBroadcastWithError:error];
                                    [[ReplayFileUtil sharedInstanceManager] stopRecordingWithTimeout:true];
                                    
                                }];
                            });
                            
                        }
                        
                        if (util.assetWriter.status == AVAssetWriterStatusWriting) {
                            if (util.videoInput.isReadyForMoreMediaData) {
                                BOOL success = [util.videoInput appendSampleBuffer:sampleBuffer];
                                if (!success) {
                                    @synchronized (self) {
                                        [[ReplayFileUtil sharedInstanceManager] stopRecordingWithTimeout:false];
                                        //                                    [self stopRecording];
                                    }
                                } else {
                                    //                                    NSLog(@"视频添加成功！");
                                }
                                
                            }
                            
                        }
                    }
                }
                break;
            }
                
                //应用声音
            case RPSampleBufferTypeAudioApp:
                // Handle audio sample buffer for app audio
                if (util.audioInput) {
                    if (CMSampleBufferDataIsReady(sampleBuffer) && util.audioInput.readyForMoreMediaData && (util.assetWriter.status==AVAssetWriterStatusWriting)) {
                        BOOL success = [util.audioInput appendSampleBuffer:sampleBuffer];
                        if (!success) {
                            @synchronized (self) {
                                [[ReplayFileUtil sharedInstanceManager] stopRecordingWithTimeout:false];
                                //                        [self stopRecording];
                            }
                        } else {
                            //                            NSLog(@"音频添加成功！");
                        }
                    }
                }
                break;
                //麦克风声音
            case RPSampleBufferTypeAudioMic:
                // Handle audio sample buffer for mic audio
//                if (util.audioInputMic) {
//                    if (CMSampleBufferDataIsReady(sampleBuffer) && util.audioInputMic.readyForMoreMediaData && (util.assetWriter.status==AVAssetWriterStatusWriting)) {
//                        BOOL success = [util.audioInputMic appendSampleBuffer:sampleBuffer];
//                        if (!success) {
//                            @synchronized (self) {
//                                [[ReplayFileUtil sharedInstanceManager] stopRecordingWithTimeout:false];
//                                //                        [self stopRecording];
//                            }
//                        }
//                    }
//                }
                
                
                break;
                
            default:
                break;
        }
//        CFRelease(sampleBuffer);
//    });
    
    
    
    
    
        
}




@end
