//
//  TreefintechVideoManager.h
//  treefintechBlue
//
//  Created by Ericydong on 2019/11/6.
//  Copyright © 2019 dashu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReplayKit/ReplayKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TreefintechVideoManager : NSObject

+ (RPSystemBroadcastPickerView *)showToSuperView:(UIView *)superView result:(void(^)(NSInteger))result NS_AVAILABLE_IOS(12.0);
+ (void)finishRecording:(NSInteger)finishStatus;

//+ (void)uploadVideoWithFileUrl:(NSURL *)fileUrl progress:(void(^_Nullable)(float))progress result:(void(^)(NSError *error))result;
//+ (void)uploadVideoByDefaultFilePathWithProgress:(void(^)(float))progress result:(void(^)(NSError *error))result;

//浏览本地视频
+ (void)scanVideoWithURL:( NSURL * _Nullable)videoURL result:(void(^_Nullable)(BOOL videoSourceAvailable))result;

//默认路径是否存在视频文件(可以根据返回的url是否为空来判断)
+ (NSURL *)VideoURLPathAtDefaultPath;

//获取视频长度
+ (NSInteger)videoDuration;




/// 生成文件md5
/// @param filePath 文件路径
/// @param completion 结果回调
//+ (void)calculateFileMd5WithFilePath:(NSString *)filePath completion:(void (^)(NSString *fileMD5))completion;


/// 尝试使用固定分辨率压缩视频
/// @param oriurl 原始视频路径
/// @param toFileUrl 输出视频路径
/// @param result 结果回调
+ (void)compressVideo:(NSURL *)oriurl toFileUrl:(NSURL *)toFileUrl result:(void(^)(BOOL success))result;

/// 保存视频到相册
/// @param fileURL 资源路径
/// @param result 结果回调
//+ (void)saveVideoToAlbumWithFileURL:(NSURL *)fileURL result:(void(^)(NSError *error))result;

/// 添加视频水印
/// @param output 输出视频路径
/// @param result 结果回调
//+ (void)addWaterPicWithVideoOutput:(NSString *)output result:(void(^)(BOOL))result;
@end

NS_ASSUME_NONNULL_END
