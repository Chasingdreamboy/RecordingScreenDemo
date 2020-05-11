//
//  NSDate+Timestamp.h
//  treefintechBlue
//
//  Created by Ericydong on 2019/11/7.
//  Copyright © 2019 dashu. All rights reserved.
//




#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDate (Timestamp)

+ (NSString *)timestamp;
+ (NSString *)customeTimestampForVideoPath;
@end

NS_ASSUME_NONNULL_END
