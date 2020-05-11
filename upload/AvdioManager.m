//
//  AvdioManager.m
//  upload
//
//  Created by Ericydong on 2019/10/31.
//  Copyright © 2019 Ericydong. All rights reserved.
//

#import "AvdioManager.h"
#import "NSDate+Timestamp.h"
#import <objc/runtime.h>
#import <objc/message.h>
//#import "ConstString.h"
//#import "TreefintechAppGroupManager.h"


@implementation CFNotificationCenterHelper

static NSMutableSet *swizzledClasses() {
    static dispatch_once_t onceToken;
    static NSMutableSet *swizzledClasses = nil;
    dispatch_once(&onceToken, ^{
        swizzledClasses = [[NSMutableSet alloc] init];
    });
    return swizzledClasses;
}

static const char associatedObject_notificationArraykey;
void addNotificationToSet(id observer, NSString *identifier, CFNotificationCallback notificationCallback) {
    NSMutableSet<NSString *> *notifocationKeys = objc_getAssociatedObject(observer, &associatedObject_notificationArraykey);
    if (!notifocationKeys) {
        notifocationKeys = [NSMutableSet set];
    } else {
        for (NSString *ele in notifocationKeys) {
            if ([ele isEqualToString:identifier]) {
                [notifocationKeys removeObject:identifier];
                removeNotificationFromSet(observer, identifier);
                break;
            }
        }
    }
    CFNotificationCenterRef const center = CFNotificationCenterGetDarwinNotifyCenter();
    CFStringRef str = (__bridge CFStringRef)identifier;
    CFNotificationCenterAddObserver(center,
                                    (__bridge const void *)(observer),
                                    notificationCallback,
                                    str,
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
    [notifocationKeys addObject:identifier];
    
    objc_setAssociatedObject(observer, &associatedObject_notificationArraykey, notifocationKeys, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
}
void removeNotificationFromSet(id observer, NSString * identifier) {
    NSMutableSet<NSString *> *notifocationKeys = objc_getAssociatedObject(observer, &associatedObject_notificationArraykey);
    
    if (!notifocationKeys || !notifocationKeys.count) {
        return;
    }
    NSMutableSet *set = notifocationKeys;
    NSMutableSet *tempSet = [set mutableCopy];
    
    for (NSString  *_identifier in tempSet) {
        if ([_identifier isEqualToString:identifier]) {
            [set removeObject:_identifier];
            objc_setAssociatedObject(observer, &associatedObject_notificationArraykey, set,  OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            CFNotificationCenterRef const center = CFNotificationCenterGetDarwinNotifyCenter();
            CFStringRef str = (__bridge CFStringRef)identifier;
            CFNotificationCenterRemoveObserver(center,
                                               (__bridge const void *)(observer),
                                               str,
                                               NULL);
            
            break;
        }
    }
    
    
}

void removeAllNotifications(id observer) {
    NSMutableSet *ori = objc_getAssociatedObject(observer, &associatedObject_notificationArraykey);
    if (!ori || !ori.count) {
        return;
    }
    NSLog(@"ori == %@", ori);
    for (NSString * ele in ori) {
#if DEBUG
        NSString *className = NSStringFromClass([observer class]);
        NSLog(@"移除[%@]注册的通知[%@]", className, ele);
#endif
        CFNotificationCenterRef const center = CFNotificationCenterGetDarwinNotifyCenter();
        CFStringRef str = (__bridge CFStringRef)ele;
        CFNotificationCenterRemoveObserver(center,
                                           (__bridge const void *)(observer),
                                           str,
                                           NULL);
    }
    objc_setAssociatedObject(observer, &associatedObject_notificationArraykey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


static void swizzleDeallocIfNeeded(Class classToSwizzle) {
    @synchronized (swizzledClasses()) {
        NSString *className = NSStringFromClass(classToSwizzle);
        if ([swizzledClasses() containsObject:className]) return;

        SEL deallocSelector = sel_registerName("dealloc");

        __block void (*originalDealloc)(__unsafe_unretained id, SEL) = NULL;

        id newDealloc = ^(__unsafe_unretained id self) {
            
            removeAllNotifications(self);
#if DEBUG
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"执行了新的dealloc");
            });
#endif
            


            if (originalDealloc == NULL) {
                struct objc_super superInfo = {
                    .receiver = self,
                    .super_class = class_getSuperclass(classToSwizzle)
                };

                void (*msgSend)(struct objc_super *, SEL) = (__typeof__(msgSend))objc_msgSendSuper;
                msgSend(&superInfo, deallocSelector);
            } else {
                originalDealloc(self, deallocSelector);
            }
        };
        
        IMP newDeallocIMP = imp_implementationWithBlock(newDealloc);
        
        if (!class_addMethod(classToSwizzle, deallocSelector, newDeallocIMP, "v@:")) {
            // The class already contains a method implementation.
            Method deallocMethod = class_getInstanceMethod(classToSwizzle, deallocSelector);
            
            // We need to store original implementation before setting new implementation
            // in case method is called at the time of setting.
            originalDealloc = (__typeof__(originalDealloc))method_getImplementation(deallocMethod);
            
            // We need to store original implementation again, in case it just changed.
            originalDealloc = (__typeof__(originalDealloc))method_setImplementation(deallocMethod, newDeallocIMP);
        }

        [swizzledClasses() addObject:className];
    }
}

+ (void)sendNotificationForMessageWithIdentifier:(nullable NSString *)identifier userInfo:(NSDictionary *)info {
//    void(^sendNotification)(void) = ^(){
        CFNotificationCenterRef const center = CFNotificationCenterGetDarwinNotifyCenter();
        CFDictionaryRef userInfo = (__bridge CFDictionaryRef)info;
        BOOL const deliverImmediately = YES;
        CFStringRef identifierRef = (__bridge CFStringRef)identifier;
        CFNotificationCenterPostNotification(center, identifierRef, NULL, userInfo, deliverImmediately);
//    };
    
    
    //使用主队列发送通知
//    dispatch_queue_t mainQueue = dispatch_get_main_queue();
//    if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(mainQueue)){
//        sendNotification();
//    } else {
//        dispatch_async(mainQueue, sendNotification);
//    }
    
}


+ (void)registerForNotificationsWithobserver:(id)observer identifier:( nullable const NSString *)identifier callback:(CFNotificationCallback)MyHoleNotificationCallback {
    removeNotificationFromSet(observer, (NSString *)identifier);
    swizzleDeallocIfNeeded([observer class]);
    addNotificationToSet(observer, (NSString *)identifier, MyHoleNotificationCallback);
    
}


+ (void)registerForNotificationsWithobserver:(id)observer identifiers:(NSArray <NSString *> *)identifiers callback:(CFNotificationCallback)MyHoleNotificationCallback {
    if(!identifiers || !identifiers.count) {
        return;
        
    }
    for (NSString *identifier in identifiers) {
        [self registerForNotificationsWithobserver:observer identifier:identifier callback:MyHoleNotificationCallback];
    }
}


@end





@interface ReplayFileUtil ()
@property (copy, nonatomic) NSString *replayDirectoryPath;



@end




NSString *const broadcastFinishRecordingNotification = @"broadcastFinishRecording";

NSString *const broadcastStartRecordingNotification = @"broadcastStartRecording";


NSString * const broadcastTimeoutRecordingNotification = @"broadcastTimeoutRecording";

NSString * const broadcastStopRecordingNotification = @"broadcastStopRecording";

NSString * const appGroupIdentifierKey = @"group.com.treefintech.RecordScreenDemo";


NSString * const isGongfudaiRecordingScreenKey = @"isGongfudaiRecordingScreen";


@implementation ReplayFileUtil

//判断字符串是否有效
BOOL __isAvailable(NSString *str) {
    
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


void timer(NSInteger count , void(^callback)(void)) {
    __block NSInteger timeOut = count;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_source_t _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    // 每秒执行一次
    dispatch_source_set_timer(_timer, dispatch_walltime(NULL, 0), 1.0 * NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(_timer, ^{
        // 倒计时结束，关闭
        if (timeOut <= 0) {
            dispatch_source_cancel(_timer);
            dispatch_cancel(_timer);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                callback();
            });
        } else {
            
            @synchronized ([ReplayFileUtil sharedInstanceManager]) {
                timeOut--;
            }
            
        }
    });
    dispatch_resume(_timer);
}

static ReplayFileUtil *manager = nil;
static dispatch_once_t onceToken;
+ (instancetype)sharedInstanceManager {
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}



+ (NSString *)replayDirectoryPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    /*

     */
    NSString *documentDirectoryPath = [fileManager containerURLForSecurityApplicationGroupIdentifier:appGroupIdentifierKey].path;
//    NSString * replayDirectoryPath = [documentDirectoryPath stringByAppendingString:@"/Replays"];
    NSString * replayDirectoryPath = [documentDirectoryPath stringByAppendingPathComponent:@"Replays"];
    
    if (![fileManager isExecutableFileAtPath:replayDirectoryPath]) {
        NSError *error = nil;
        BOOL success = [fileManager createDirectoryAtPath:replayDirectoryPath withIntermediateDirectories:true attributes:@{} error:&error];
        if (!success || error) {
            NSAssert(false, @"创建路径失败");
            return nil;
        } else {
            NSLog(@"主路径创建成功！");
        }
    }
    return replayDirectoryPath;
    
}


+ (NSString *)filePathWithName:(NSString *)fileName {
    NSString *replayDirectoryPath = [self replayDirectoryPath];
    NSString *fileNameWithExtension = [fileName stringByAppendingPathExtension:@"mp4"];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", replayDirectoryPath, fileNameWithExtension];
    return filePath;
}
+ (NSArray <NSURL *> *)fetchAllReplays {
    NSString *replayDirectoryPath = [ReplayFileUtil replayDirectoryPath];
    NSError *error = nil;
    NSArray <NSURL *> *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:replayDirectoryPath] includingPropertiesForKeys:nil options:(0) error:&error];
    return directoryContents;
}


- (void)prepareToRecording {
    [ReplayFileUtil setGongfudaiRecordingScreenFlag:true];
    
    
    self.writeQueue = dispatch_queue_create("com.recordScreen.gongfudai", DISPATCH_QUEUE_SERIAL);
    
    NSString *fileName = [NSDate customeTimestampForVideoPath];

    NSURL *fileURL = [NSURL fileURLWithPath:[ReplayFileUtil filePathWithName:fileName]];
    NSError *error = nil;
    self.assetWriter = [[AVAssetWriter alloc] initWithURL:fileURL fileType:AVFileTypeMPEG4 error:&error];
    NSLog(@"fileUrl == %@", fileURL);
    NSLog(@"error == %@", error);
    if (error || !self.assetWriter) {
        //            recordingHandler(error);
        NSAssert(false, @"创建异常");
    } else {
        CGSize size = [UIScreen mainScreen].bounds.size;
        //写入视频大小
        NSInteger numPixels = size.width  * size.height /* [UIScreen mainScreen].scale * size.height * [UIScreen mainScreen].scale*/;
        //每像素比特
        
        NSInteger videoFramerate = 25;
//        CGFloat videoFramerate = [TreefintechAppGroupManager floatValueForIdentifier:TreefintechRecordConfigVideoFramerateKey];
//        if (_videoFramerate) {
//            videoFramerate = (NSInteger)_videoFramerate;
//        }
        
        
        CGFloat bitsPerPixel = 7.5; //每个像素点的比率
        
//        CGFloat bitsPerPixel = [TreefintechAppGroupManager floatValueForIdentifier:TreefintechRecordConfigBitsPerPixelKey];
////        if (_bitsPerPixel) {
////            bitsPerPixel = _bitsPerPixel;
////        }
        
        
        CGFloat width = 480.0;
        CGFloat height = 720.0;
//        CGFloat width = [TreefintechAppGroupManager floatValueForIdentifier:TreefintechRecordWidthOfVideolKey];
//        CGFloat height = [TreefintechAppGroupManager floatValueForIdentifier:TreefintechRecordHeightOfVideolKey];
//        if (_width && _height) {
//            width = _width;
//            height = _height;
//        }
        
        
        
//        CGFloat recordTimeMax = 60000; //最长视频时长(毫秒)
//
//        CGFloat _recordTimeMax = [TreefintechAppGroupManager floatValueForIdentifier:TreefintechRecordTimeMaxOfVideolKey];
//        if (_recordTimeMax) {
//            recordTimeMax = _recordTimeMax;
//        }
        

        CGFloat exceptedScale = width * 1.0 / height;
        CGFloat realScale = size.width * 1.0 / size.height;
        if (realScale > exceptedScale) {
            //实际宽缩小至width
            CGFloat scaleWanted = width * 1.0 / size.width;
            size.width = width;
            size.height = size.height * scaleWanted;
        } else {
            CGFloat scaleWanted = height * 1.0 / size.height;
            size.height = height;
            size.width = size.width * scaleWanted;
        }
        
        //以超时时间和伴读音频的最大值为超时时间
//        CGFloat timeoutOfRecording = recordTimeMax * 1.0 / 1000;
        //            CGFloat durationOfAudio =  [TreefintechAppGroupManager floatValueForIdentifier:TreefintechRecordAudioDurationKey];
        //            CGFloat durationOfTimeout = durationOfAudio > timeoutOfRecording ? durationOfAudio : timeoutOfRecording;
        

        
        
        
        
        NSInteger bitsPerSecond = numPixels * bitsPerPixel;
        // 码率和帧率设置
        NSDictionary *compressionProperties = @{
            AVVideoAverageBitRateKey : @(bitsPerSecond), //码率
            AVVideoExpectedSourceFrameRateKey : @(videoFramerate), //帧率
//            AVVideoAverageNonDroppableFrameRateKey:@(videoFramerate),
            AVVideoMaxKeyFrameIntervalKey : @(15),
            AVVideoProfileLevelKey : AVVideoProfileLevelH264HighAutoLevel,
            AVVideoPixelAspectRatioKey: @{
                    AVVideoPixelAspectRatioHorizontalSpacingKey: @(1),
                    AVVideoPixelAspectRatioVerticalSpacingKey: @(1)
            },
        };
        CGFloat scale = [UIScreen mainScreen].scale;
        scale = 1.0;//使用1.0
        
        //以高不超过720为准
        //        size = (CGSize){size.width * scaleWanted, heightOfVideo * scaleWanted};
        
        if (@available(iOS 12.0, *)) {
            NSDictionary *videoOutputSettings = @{
                AVVideoCodecKey : AVVideoCodecTypeH264,
                AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
                AVVideoWidthKey : @(size.width * scale),
                AVVideoHeightKey : @(size.height * scale),
                AVVideoCompressionPropertiesKey : compressionProperties
            };
            self.videoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoOutputSettings];
        } else {
            NSAssert(false, @"不支持的格式");
            // Fallback on earlier versions
        }
        //        self.videoInput.transform = CGAffineTransformMakeRotation(M_PI / 2.0);
        self.videoInput.expectsMediaDataInRealTime = true;
        
        
        

        
        

        
        
        
        
        
        
        NSInteger encoderBitRatePerChannel = 64000;
//        NSInteger _encoderBitRatePerChannel = (NSInteger)[TreefintechAppGroupManager floatValueForIdentifier:TreefintechRecordEncoderBitRatePerChannelOfAudioKey];
//        if (_encoderBitRatePerChannel) {
//            encoderBitRatePerChannel = _encoderBitRatePerChannel;
//        }

        NSInteger sampleRate = 44100;
//        NSInteger _sampleRate = (NSInteger)[TreefintechAppGroupManager floatValueForIdentifier:TreefintechRecordSampleRateOfAudioKey];
//        if (_sampleRate) {
//            sampleRate = _sampleRate;
//        }

        NSInteger numberOfChannels = 1;
//        NSInteger _numberOfChannels = [TreefintechAppGroupManager floatValueForIdentifier:TreefintechRecordNumberOfChannelsOfAudioKey];
//        if (_numberOfChannels) {
//            numberOfChannels = _numberOfChannels;
//        }


        
        
        static  NSDictionary *audioCompressionSettings;
        audioCompressionSettings = @{
            AVEncoderBitRatePerChannelKey : @(encoderBitRatePerChannel), //一个整数，用于标识每个通道的音频比特率
            AVFormatIDKey : @(kAudioFormatMPEG4AAC), //格式标识符
            AVNumberOfChannelsKey : @(numberOfChannels), // AVNumberOfChannelsKey
            AVSampleRateKey : @(sampleRate), //AVSampleRateKey

        };

        self.audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioCompressionSettings];
        self.audioInput.expectsMediaDataInRealTime = true;
        
        
//
//        self.audioInputMic = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioCompressionSettings];
//        self.audioInputMic.expectsMediaDataInRealTime = true;
        
        
        
        
        
        
//
//
//
        if ([self.assetWriter canAddInput:self.videoInput]) {
            [self.assetWriter addInput:self.videoInput];
        } else {
            NSLog(@"videoInput添加异常");
        }
        
        
        if ([self.assetWriter canAddInput:self.audioInput]) {
            [self.assetWriter addInput:self.audioInput];
        } else {
            NSLog(@"audioInput添加异常");
        }
        
        
//        if ([self.assetWriter canAddInput:self.audioInputMic]) {
//            [self.assetWriter addInput:self.audioInputMic];
//        } else {
//            NSLog(@"audioInput添加异常");
//        }

        
        
        
        
        
        
        

        
        
        
        
        
        
        
    }
}

- (void)beginRecordingWithTimeout:(void(^)(void))timeout {
    //录制开始通知
    [CFNotificationCenterHelper sendNotificationForMessageWithIdentifier:broadcastStartRecordingNotification userInfo:@{}];
    CGFloat recordTimeMax = 60000; //最长视频时长(毫秒)
    
//    CGFloat recordTimeMax = [TreefintechAppGroupManager floatValueForIdentifier:TreefintechRecordTimeMaxOfVideolKey];
//    if (_recordTimeMax) {
//        recordTimeMax = _recordTimeMax;
//    }
    //超时回调
    CGFloat timeoutOfRecording = recordTimeMax * 1.0 / 1000;
    //超时回调
    timer((NSInteger)timeoutOfRecording, ^{
        //录制超时通知
        timeout();
    });
}




- (void)stopRecordingWithTimeout:(BOOL)isTimeout {
    
    //保存录屏结束凭证
    [ReplayFileUtil setGongfudaiRecordingScreenFlag:false];
    //    NSUserDefaults *userDefault = [[NSUserDefaults alloc] initWithSuiteName:appGroupIdentifier];
    //    [userDefault setBool:false forKey:isGongfudaiRecordingScreenKey];
    
    
    
    
    ReplayFileUtil *util = [ReplayFileUtil sharedInstanceManager];
    
    
//    dispatch_async(self.writeQueue, ^{
        if (util.assetWriter.status == AVAssetWriterStatusWriting) {
            
            [util.videoInput markAsFinished];
            [util.audioInput markAsFinished];
            
            NSString *name = isTimeout ? broadcastTimeoutRecordingNotification : broadcastFinishRecordingNotification;
            [CFNotificationCenterHelper sendNotificationForMessageWithIdentifier:name userInfo:@{}];
            
            
            BOOL success = [util.assetWriter finishWriting];
            if (!success) {
                NSLog(@"util.assetWriter.error == %@", util.assetWriter.error);
            } else {
                
                util.videoInput = nil;
                util.audioInput = nil;
                NSLog(@"结束成功！");
                
            }
        }
        
//    });
    
    
    
    
}


+ (void)setGongfudaiRecordingScreenFlag:(BOOL)isRecording {
    
    //保存自己录屏的凭证
    NSUserDefaults *userDefault = [[NSUserDefaults alloc] initWithSuiteName:appGroupIdentifierKey];
    [userDefault setBool:isRecording forKey:isGongfudaiRecordingScreenKey];
    
}
+ (BOOL)gongfudaiRecordingScreenFlag {
    NSUserDefaults *userDefault = [[NSUserDefaults alloc] initWithSuiteName:appGroupIdentifierKey];
    return [userDefault boolForKey:isGongfudaiRecordingScreenKey];
    
}

//- (void)startRecordingWithTimeout:(void(^)(void))timeout {
//    [ReplayFileUtil setGongfudaiRecordingScreenFlag:true];
//    NSString *fileName = [NSDate customeTimestampForVideoPath];
//
//    NSURL *fileURL = [NSURL fileURLWithPath:[ReplayFileUtil filePathWithName:fileName]];
//    NSError *error = nil;
//    self.assetWriter = [[AVAssetWriter alloc] initWithURL:fileURL fileType:AVFileTypeMPEG4 error:&error];
//    NSLog(@"fileUrl == %@", fileURL);
//    NSLog(@"error == %@", error);
//    if (error || !self.assetWriter) {
//        //            recordingHandler(error);
//        NSAssert(false, @"创建异常");
//    } else {
//        CGSize size = [UIScreen mainScreen].bounds.size;
//        //写入视频大小
//        NSInteger numPixels = size.width  * size.height /* [UIScreen mainScreen].scale * size.height * [UIScreen mainScreen].scale*/;
//        //每像素比特
//
//        NSInteger videoFramerate = 25;
//        CGFloat _videoFramerate = [TreefintechAppGroupManager floatValueForIdentifier:TreefintechRecordConfigVideoFramerateKey];
//        if (_videoFramerate) {
//            videoFramerate = (NSInteger)_videoFramerate;
//        }
//        CGFloat bitsPerPixel = 7.5; //每个像素点的比率
//
//        CGFloat _bitsPerPixel = [TreefintechAppGroupManager floatValueForIdentifier:TreefintechRecordConfigBitsPerPixelKey];
//        if (_bitsPerPixel) {
//            bitsPerPixel = _bitsPerPixel;
//        }
//
//
//        CGFloat width = 480.0;
//        CGFloat height = 720.0;
//        CGFloat _width = [TreefintechAppGroupManager floatValueForIdentifier:TreefintechRecordWidthOfVideolKey];
//        CGFloat _height = [TreefintechAppGroupManager floatValueForIdentifier:TreefintechRecordHeightOfVideolKey];
//        if (_width && _height) {
//            width = _width;
//            height = _height;
//        }
//
//
//
//        CGFloat recordTimeMax = 60000; //最长视频时长(毫秒)
//
//        CGFloat _recordTimeMax = [TreefintechAppGroupManager floatValueForIdentifier:TreefintechRecordTimeMaxOfVideolKey];
//        if (_recordTimeMax) {
//            recordTimeMax = _recordTimeMax;
//        }
//
//
//        CGFloat exceptedScale = width * 1.0 / height;
//        CGFloat realScale = size.width * 1.0 / size.height;
//        if (realScale > exceptedScale) {
//            //实际宽缩小至width
//            CGFloat scaleWanted = width * 1.0 / size.width;
//            size.width = width;
//            size.height = size.height * scaleWanted;
//        } else {
//            CGFloat scaleWanted = height * 1.0 / size.height;
//            size.height = height;
//            size.width = size.width * scaleWanted;
//        }
//
//        //以超时时间和伴读音频的最大值为超时时间
//        CGFloat timeoutOfRecording = recordTimeMax * 1.0 / 1000;
//        //            CGFloat durationOfAudio =  [TreefintechAppGroupManager floatValueForIdentifier:TreefintechRecordAudioDurationKey];
//        //            CGFloat durationOfTimeout = durationOfAudio > timeoutOfRecording ? durationOfAudio : timeoutOfRecording;
//
//
//
//
//
//
//        NSInteger bitsPerSecond = numPixels * bitsPerPixel;
//        // 码率和帧率设置
//        NSDictionary *compressionProperties = @{
//            AVVideoAverageBitRateKey : @(bitsPerSecond), //码率
//            AVVideoExpectedSourceFrameRateKey : @(videoFramerate), //帧率
//            AVVideoMaxKeyFrameIntervalKey : @(15),
//            AVVideoProfileLevelKey : AVVideoProfileLevelH264HighAutoLevel,
//            AVVideoPixelAspectRatioKey: @{
//                    AVVideoPixelAspectRatioHorizontalSpacingKey: @(1),
//                    AVVideoPixelAspectRatioVerticalSpacingKey: @(1)
//            },
//        };
//        /*
//
//         warning:
//         AVVideoExpectedSourceFrameRateKey
//         该参数只是一个参考值，实际帧率可能会比这个值低
//         */
//
//        CGFloat scale = [UIScreen mainScreen].scale;
//        scale = 1.0;//使用1.0
//
//        //以高不超过720为准
//        //        size = (CGSize){size.width * scaleWanted, heightOfVideo * scaleWanted};
//
//        if (@available(iOS 12.0, *)) {
//            NSDictionary *videoOutputSettings = @{
//                AVVideoCodecKey : AVVideoCodecTypeH264,
//                AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
//                AVVideoWidthKey : @(size.width * scale),
//                AVVideoHeightKey : @(size.height * scale),
//                AVVideoCompressionPropertiesKey : compressionProperties
//            };
//            self.videoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoOutputSettings];
//        } else {
//            NSAssert(false, @"不支持的格式");
//            // Fallback on earlier versions
//        }
//        //        self.videoInput.transform = CGAffineTransformMakeRotation(M_PI / 2.0);
//        self.videoInput.expectsMediaDataInRealTime = true;
//
//        if ([self.assetWriter canAddInput:self.videoInput]) {
//            [self.assetWriter addInput:self.videoInput];
//        } else {
//            NSLog(@"videoInput添加异常");
//        }
//        //        NSDictionary *audioCompressionSettings = @{ AVEncoderBitRatePerChannelKey : @(28000),
//        //        AVFormatIDKey : @(kAudioFormatMPEG4AAC),
//        //        AVNumberOfChannelsKey : @(1),
//        //        AVSampleRateKey : @(22050) };
//        //
//        //        self.audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioCompressionSettings];
//        //
//        //
//        //        if ([self.assetWriter canAddInput:self.audioInput]) {
//        //            [self.assetWriter addInput:self.audioInput];
//        //        } else {
//        //           NSLog(@"audioInput添加异常");
//        //        }
//        //    }
//
//
//
//
//
//
//
//
//
//
//
//
//        //发送开始通知(为啥延时0.1s,原因未知，但是不延时就会异常不信你试试)
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [CFNotificationCenterHelper sendNotificationForMessageWithIdentifier:broadcastStartRecordingNotification userInfo:@{}];
//        });
//
//        //超时回调
//        timer((NSInteger)timeoutOfRecording, ^{
//            dispatch_async(dispatch_get_main_queue(), ^{
//                timeout();
//            });
//        });
//    }
//}




//- (void)startRecording {
//    NSString *timestamp = [NSString stringWithFormat:@"%ld", (long)([NSDate timeIntervalSinceReferenceDate] * 1000)];
//    [self startRecordingWithFileName:timestamp recordingHandler:^(NSError * _Nonnull error) {
//        
//        
//    }];
//    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [CFNotificationCenterHelper sendNotificationForMessageWithIdentifier:broadcastStartRecordingNotification userInfo:@{}];
//    });
//    
//    
////    [[ReplayFileUtil sharedInstanceManager] startRecordingWithFileName:timestamp recordingHandler:^(NSError * _Nonnull error) {
////
////    }];
//    
//}

//

//- (void)startRecordingWithFileName:(NSString *)fileName recordingHandler:(void(^)(NSError *))recordingHandler {
//
//
//
//
//
//
//
//        [ReplayFileUtil setGongfudaiRecordingScreenFlag:true];
//
//
//
//
////        NSString *fileName = [NSDate customeTimestampForVideoPath];
//            //清理掉之前的视频，只保留一个
//            NSFileManager *fileManager = [NSFileManager defaultManager];
//            NSString *replayDirectoryPath = [ReplayFileUtil replayDirectoryPath];
//            NSDirectoryEnumerator <NSString *> *enumerator = [fileManager enumeratorAtPath:replayDirectoryPath];
//            NSString *fileNameExist ;
//            while (fileNameExist = [enumerator nextObject]) {
//                fileNameExist = [replayDirectoryPath stringByAppendingPathComponent:fileNameExist];
//                NSError *error = nil;
//                BOOL remove =  [fileManager removeItemAtPath:fileNameExist error:&error];
//                if (remove && !error) {
//                    NSLog(@"fileName == %@ 删除成功", fileNameExist);
//                } else {
//                    NSAssert(false, @"删除异常");
//                }
//            }
//
//
//
//
//
//
//
//
//
//            NSURL *fileURL = [NSURL fileURLWithPath:[ReplayFileUtil filePathWithName:fileName]];
//            NSError *error = nil;
//            self.assetWriter = [[AVAssetWriter alloc] initWithURL:fileURL fileType:AVFileTypeMPEG4 error:&error];
//            NSLog(@"fileUrl == %@", fileURL);
//            NSLog(@"error == %@", error);
//            if (error || !self.assetWriter) {
//    //            recordingHandler(error);
//                NSAssert(false, @"创建异常");
//            } else {
//                CGSize size = [UIScreen mainScreen].bounds.size;
//                //写入视频大小
//                NSInteger numPixels = size.width  * size.height /* [UIScreen mainScreen].scale * size.height * [UIScreen mainScreen].scale*/;
//                //每像素比特
////                CGFloat bitsPerPixel = 7.5; //每个像素点的比率
////                CGFloat width = 480.0;
////                CGFloat height = 720.0;
////
////
////                CGFloat recordTimeMax = 60000; //最长视频时长(毫秒)
////                NSInteger videoFramerate = 25;
//
//
//                NSInteger videoFramerate = 25;
//                CGFloat _videoFramerate = [TreefintechAppGroupManager floatValueForIdentifier:TreefintechRecordConfigVideoFramerateKey];
//                if (_videoFramerate) {
//                    videoFramerate = (NSInteger)_videoFramerate;
//                }
//                CGFloat bitsPerPixel = 7.5; //每个像素点的比率
//
//                CGFloat _bitsPerPixel = [TreefintechAppGroupManager floatValueForIdentifier:TreefintechRecordConfigBitsPerPixelKey];
//                if (_bitsPerPixel) {
//                    bitsPerPixel = _bitsPerPixel;
//                }
//
//
//                CGFloat width = 480.0;
//                CGFloat height = 720.0;
//                CGFloat _width = [TreefintechAppGroupManager floatValueForIdentifier:TreefintechRecordWidthOfVideolKey];
//                CGFloat _height = [TreefintechAppGroupManager floatValueForIdentifier:TreefintechRecordHeightOfVideolKey];
//                if (_width && _height) {
//                    width = _width;
//                    height = _height;
//                }
//
//
//
//                CGFloat recordTimeMax = 60000; //最长视频时长(毫秒)
//
//                CGFloat _recordTimeMax = [TreefintechAppGroupManager floatValueForIdentifier:TreefintechRecordTimeMaxOfVideolKey];
//                if (_recordTimeMax) {
//                    recordTimeMax = _recordTimeMax;
//                }
//
//
//
//
//
//
//
//
//
//
//
//                CGFloat exceptedScale = width * 1.0 / height;
//                CGFloat realScale = size.width * 1.0 / size.height;
//                if (realScale > exceptedScale) {
//                    //实际宽缩小至width
//                    CGFloat scaleWanted = width * 1.0 / size.width;
//                    size.width = width;
//                    size.height = size.height * scaleWanted;
//                } else {
//                    CGFloat scaleWanted = height * 1.0 / size.height;
//                    size.height = height;
//                    size.width = size.width * scaleWanted;
//                }
//
//
//
//                //以超时时间和伴读音频的最大值为超时时间
////                CGFloat timeoutOfRecording = recordTimeMax * 1.0 / 1000;
//    //            CGFloat durationOfAudio =  [TreefintechAppGroupManager floatValueForIdentifier:TreefintechRecordAudioDurationKey];
//    //            CGFloat durationOfTimeout = durationOfAudio > timeoutOfRecording ? durationOfAudio : timeoutOfRecording;
////                //超时回调
////                timer((NSInteger)timeoutOfRecording, ^{
////                    dispatch_async(dispatch_get_main_queue(), ^{
////                        timeout();
////                    });
////                });
////
////                //发送开始通知
////                dispatch_async(dispatch_get_main_queue(), ^{
////                    [CFNotificationCenterHelper sendNotificationForMessageWithIdentifier:broadcastStartRecordingNotification userInfo:@{}];
////                });
//
//
//
//
//
//
//                NSInteger bitsPerSecond = numPixels * bitsPerPixel;
//                // 码率和帧率设置
//                NSDictionary *compressionProperties = @{
//                    AVVideoAverageBitRateKey : @(bitsPerSecond), //码率
//                    AVVideoExpectedSourceFrameRateKey : @(videoFramerate), //帧率
//                    AVVideoMaxKeyFrameIntervalKey : @(15),
//                    AVVideoProfileLevelKey : AVVideoProfileLevelH264HighAutoLevel,
//                    AVVideoPixelAspectRatioKey: @{
//                        AVVideoPixelAspectRatioHorizontalSpacingKey: @(1),
//                        AVVideoPixelAspectRatioVerticalSpacingKey: @(1)
//                    },
//                };
//                CGFloat scale = [UIScreen mainScreen].scale;
//                scale = 1.0;//使用1.0
//
//                //以高不超过720为准
//        //        size = (CGSize){size.width * scaleWanted, heightOfVideo * scaleWanted};
//
//                if (@available(iOS 12.0, *)) {
//                    NSDictionary *videoOutputSettings = @{
//                        AVVideoCodecKey : AVVideoCodecTypeH264,
//                        AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
//                        AVVideoWidthKey : @(size.width * scale),
//                        AVVideoHeightKey : @(size.height * scale),
//                        AVVideoCompressionPropertiesKey : compressionProperties
//                    };
//                    self.videoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoOutputSettings];
//                } else {
//                    NSAssert(false, @"不支持的格式");
//                    // Fallback on earlier versions
//                }
//                //        self.videoInput.transform = CGAffineTransformMakeRotation(M_PI / 2.0);
//                self.videoInput.expectsMediaDataInRealTime = true;
//
//                if ([self.assetWriter canAddInput:self.videoInput]) {
//                    [self.assetWriter addInput:self.videoInput];
//                } else {
//                    NSLog(@"videoInput添加异常");
//                }
//                //        NSDictionary *audioCompressionSettings = @{ AVEncoderBitRatePerChannelKey : @(28000),
//                //        AVFormatIDKey : @(kAudioFormatMPEG4AAC),
//                //        AVNumberOfChannelsKey : @(1),
//                //        AVSampleRateKey : @(22050) };
//                //
//                //        self.audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioCompressionSettings];
//                //
//                //
//                //        if ([self.assetWriter canAddInput:self.audioInput]) {
//                //            [self.assetWriter addInput:self.audioInput];
//                //        } else {
//                //           NSLog(@"audioInput添加异常");
//                //        }
//                //    }
//            }
//
//
//
//
//
//
//
//
//
//
////
////    //清理掉之前的视频，只保留一个
////    NSFileManager *fileManager = [NSFileManager defaultManager];
////    NSString *replayDirectoryPath = [self replayDirectoryPath];
////    NSDirectoryEnumerator <NSString *> *enumerator = [fileManager enumeratorAtPath:replayDirectoryPath];
////    NSString *fileNameExist ;
////    while (fileNameExist = [enumerator nextObject]) {
////        fileNameExist = [replayDirectoryPath stringByAppendingPathComponent:fileNameExist];
////        NSError *error = nil;
////        BOOL remove =  [fileManager removeItemAtPath:fileNameExist error:&error];
////        if (remove && !error) {
////            NSLog(@"fileName == %@ 删除成功", fileNameExist);
////        } else {
////            NSAssert(false, @"删除异常");
////        }
////    }
////
////    NSURL *fileURL = [NSURL fileURLWithPath:[self filePathWithName:fileName]];
////    NSError *error = nil;
////    self.assetWriter = [[AVAssetWriter alloc] initWithURL:fileURL fileType:AVFileTypeMPEG4 error:&error];
////    NSLog(@"fileUrl == %@", fileURL);
////    NSLog(@"error == %@", error);
////    if (error || !self.assetWriter) {
////        recordingHandler(error);
////        NSAssert(false, @"创建异常");
////    } else {
////
////
////        CGSize size = [UIScreen mainScreen].bounds.size;
////
////        //写入视频大小
////        NSInteger numPixels = size.width  * size.height /* [UIScreen mainScreen].scale * size.height * [UIScreen mainScreen].scale*/;
////        //每像素比特
////        CGFloat bitsPerPixel = 7.5;
////        NSInteger bitsPerSecond = numPixels * bitsPerPixel;
////        // 码率和帧率设置
////        NSDictionary *compressionProperties = @{
////            AVVideoAverageBitRateKey : @(bitsPerSecond),//码率(平均每秒的比特率)
////            AVVideoExpectedSourceFrameRateKey : @(25),//帧率（如果使用了AVVideoProfileLevelKey则该值应该被设置，否则可能会丢弃帧以满足比特流的要求）
////            AVVideoMaxKeyFrameIntervalKey : @(15),//关键帧最大间隔
////            AVVideoProfileLevelKey : AVVideoProfileLevelH264HighAutoLevel,
////            AVVideoPixelAspectRatioKey: @{
////                AVVideoPixelAspectRatioHorizontalSpacingKey: @(1),
////                AVVideoPixelAspectRatioVerticalSpacingKey: @(1)
////            },
////        };
////
////        size = (CGSize){480, 720};
////        CGFloat scale = [UIScreen mainScreen].scale;
////        scale = 1.0;
////
////
//////        scale = 1.0;
//////        size = (CGSize){size.width / size.height * 720, 720};
////
////
////        NSDictionary *videoOutputSettings = @{
////            AVVideoCodecKey : AVVideoCodecTypeH264,
////            AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
////            AVVideoWidthKey : @(size.width * scale),
////            AVVideoHeightKey : @(size.height * scale),
////            AVVideoCompressionPropertiesKey : compressionProperties
////        };
////        self.videoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoOutputSettings];
////        //        self.videoInput.transform = CGAffineTransformMakeRotation(M_PI / 2.0);
////        self.videoInput.expectsMediaDataInRealTime = true;
////
////        if ([self.assetWriter canAddInput:self.videoInput]) {
////            [self.assetWriter addInput:self.videoInput];
////        } else {
////            NSLog(@"videoInput添加异常");
////        }
////        //        NSDictionary *audioCompressionSettings = @{ AVEncoderBitRatePerChannelKey : @(28000),
////        //        AVFormatIDKey : @(kAudioFormatMPEG4AAC),
////        //        AVNumberOfChannelsKey : @(1),
////        //        AVSampleRateKey : @(22050) };
////        //
////        //        self.audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioCompressionSettings];
////        //
////        //
////        //        if ([self.assetWriter canAddInput:self.audioInput]) {
////        //            [self.assetWriter addInput:self.audioInput];
////        //        } else {
////        //           NSLog(@"audioInput添加异常");
////        //        }
////        //    }
////    }
//}


//- (void)registerForNotificationsWithobserver:(id)observer identifier:( nullable const NSString *)identifier callback:(CFNotificationCallback)MyHoleNotificationCallback {
////    [self unregisterForNotificationsWithIdentifier:identifier];
//    [self unregisterForNotificationsWithObserver:observer Identifier:identifier];
//    CFNotificationCenterRef const center = CFNotificationCenterGetDarwinNotifyCenter();
//    CFStringRef str = (__bridge CFStringRef)identifier;
//    CFNotificationCenterAddObserver(center,
//                                    (__bridge const void *)(self),
//                                    MyHoleNotificationCallback,
//                                    str,
//                                    NULL,
//                                    CFNotificationSuspensionBehaviorDeliverImmediately);
//}
//- (void)unregisterForNotificationsWithObserver:(id)observer Identifier:(nullable const NSString *)identifier {
//    CFNotificationCenterRef const center = CFNotificationCenterGetDarwinNotifyCenter();
//    CFStringRef str = (__bridge CFStringRef)identifier;
//    CFNotificationCenterRemoveObserver(center,
//                                       (__bridge const void *)(observer),
//                                       str,
//                                       NULL);
//}

//- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer {
//    // 为媒体数据设置一个CMSampleBuffer的Core Video图像缓存对象
//    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//    // 锁定pixel buffer的基地址
//    CVPixelBufferLockBaseAddress(imageBuffer, 0);
//
//    // 得到pixel buffer的基地址
//    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
//
//    // 得到pixel buffer的行字节数
//    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
//    // 得到pixel buffer的宽和高
//    size_t width = CVPixelBufferGetWidth(imageBuffer);
//    size_t height = CVPixelBufferGetHeight(imageBuffer);
//
//    // 创建一个依赖于设备的RGB颜色空间
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//
//    // 用抽样缓存的数据创建一个位图格式的图形上下文（graphics context）对象
//    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
//                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
//    // 根据这个位图context中的像素数据创建一个Quartz image对象
//    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
//    // 解锁pixel buffer
//    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
//
//    // 释放context和颜色空间
//    CGContextRelease(context);
//    CGColorSpaceRelease(colorSpace);
//
//    // 用Quartz image创建一个UIImage对象image
//    UIImage *image = [UIImage imageWithCGImage:quartzImage];
//
//    // 释放Quartz image对象
//    CGImageRelease(quartzImage);
//
//    return (image);
//}

@end
