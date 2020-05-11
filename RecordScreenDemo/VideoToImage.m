//
//  VideoToImage.m
//  RecordScreenDemo
//
//  Created by Ericydong on 2019/11/4.
//  Copyright © 2019 Ericydong. All rights reserved.
//

#import "VideoToImage.h"
#import "NSDate+Timestamp.h"

#import <AVFoundation/AVFoundation.h>


//@interface NSDate (Timestamp)
//+ (NSString *)timestamp;
//@end
//
//@implementation NSDate (Timestamp)
//
//+ (NSString *)timestamp {
//    long long timeinterval = (long long)([NSDate timeIntervalSinceReferenceDate] * 1000);
//
//    return [NSString stringWithFormat:@"%lld", timeinterval];
//}
//
//@end


@implementation VideoToImage
+ (void)slideVideo:(NSURL *)url count:(NSInteger)countOfPerSecond  {
    AVAsset *asset = [AVAsset assetWithURL:url] ;
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    //获取时间
    NSInteger count = (long)(asset.duration.value / asset.duration.timescale) * countOfPerSecond;
    CMTimeValue intervalueSecond = asset.duration.value / count;

    CMTime time = kCMTimeZero;
    NSMutableArray *times = [NSMutableArray array];
    for(int i = 0; i < count; i++) {
        [times addObject:[NSValue valueWithCMTime:time]];
        time = CMTimeAdd(time, CMTimeMake(intervalueSecond, asset.duration.timescale));
    }
    
    NSString *mainpath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).firstObject;
    
    [imageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        UIImage *_image = [UIImage imageWithCGImage:image];
        NSString *fileName = [[NSDate customeTimestampForVideoPath] stringByAppendingPathExtension:@"jpg"];
        NSString *fullPath = [mainpath stringByAppendingPathComponent:fileName] ;
        NSData *data = UIImagePNGRepresentation(_image);
        BOOL success = [data writeToFile:fullPath atomically:true];
        if (success) {
            NSLog(@"%@存储成功!", fullPath);
        } else {
            NSLog(@"%@存储失败!", fullPath);
        }
        NSLog(@"image == %@", _image);
    }];
}

+ (void)imageForFirstFrameWithVideo:(NSURL *)videoPath result:(void(^)(UIImage *))callback {
    AVAsset *asset = [AVAsset assetWithURL:videoPath] ;
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    //获取第一秒的截图
    CMTime time = CMTimeAdd(kCMTimeZero, CMTimeMake(1 * asset.duration.timescale, asset.duration.timescale));
    NSMutableArray *times = [NSMutableArray array];
    
    [times addObject:[NSValue valueWithCMTime:time]];
    [imageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        UIImage *_image = [UIImage imageWithCGImage:image];
        if (callback) {
            callback(_image);
        }
    }];
}



@end
