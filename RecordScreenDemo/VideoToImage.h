//
//  VideoToImage.h
//  RecordScreenDemo
//
//  Created by Ericydong on 2019/11/4.
//  Copyright © 2019 Ericydong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface VideoToImage : NSObject
+ (void)slideVideo:(NSURL *)url count:(NSInteger)countOfPerSecond;

/// 获取首帧图片
+ (void)imageForFirstFrameWithVideo:(NSURL *)videoPath result:(void(^ )(UIImage *))callback;
@end

NS_ASSUME_NONNULL_END
