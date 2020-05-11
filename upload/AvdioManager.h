//
//  AvdioManager.h
//  upload
//
//  Created by Ericydong on 2019/10/31.
//  Copyright © 2019 Ericydong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>


NS_ASSUME_NONNULL_BEGIN




@interface CFNotificationCenterHelper : NSObject
+ (void)sendNotificationForMessageWithIdentifier:(nullable NSString *)identifier userInfo:(NSDictionary *)info;
+ (void)registerForNotificationsWithobserver:(id)observer identifier:(nullable const NSString *)identifier callback:(CFNotificationCallback)MyHoleNotificationCallback;

+ (void)registerForNotificationsWithobserver:(id)observer identifiers:(NSArray <NSString *> *)identifiers callback:(CFNotificationCallback)MyHoleNotificationCallback;



//+ (void)unregisterForNotificationsWithObserver:(id)observer Identifier:(nullable const NSString *)identifier;

@end


@interface ReplayFileUtil : NSObject

extern  NSString * const broadcastFinishRecordingNotification;
extern  NSString * const broadcastStartRecordingNotification;
extern  NSString * const broadcastTimeoutRecordingNotification;
extern  NSString * const isGongfudaiRecordingScreenKey;
extern  NSString * const broadcastStopRecordingNotification;


@property (strong, nonatomic, nullable) AVAssetWriter *assetWriter;
@property (strong, nonatomic, nullable) AVAssetWriterInput *videoInput;


//应用内声音
@property (strong, nonatomic, nullable) AVAssetWriterInput *audioInput;




//@property (strong, nonatomic) AVAssetWriterInputPixelBufferAdaptor *adaptor;


@property (nonatomic, strong) dispatch_queue_t writeQueue;

+ (instancetype)sharedInstanceManager;
+ (void)setGongfudaiRecordingScreenFlag:(BOOL)isRecording;
+ (BOOL)gongfudaiRecordingScreenFlag;

//- (void)releaseObject;
+ (NSString *)replayDirectoryPath;
+ (NSArray <NSURL *> *)fetchAllReplays;


//- (void)startRecordingWithTimeout:(void(^)(void))timeout;

//- (void)startRecording;


//准备开始录制
- (void)prepareToRecording;
//开始录制
- (void)beginRecordingWithTimeout:(void(^)(void))timeout;
//停止录制
- (void)stopRecordingWithTimeout:(BOOL)isTimeout;




@end

NS_ASSUME_NONNULL_END
