//
//  NSDate+Timestamp.m
//  treefintechBlue
//
//  Created by Ericydong on 2019/11/7.
//  Copyright © 2019 dashu. All rights reserved.
//

#import "NSDate+Timestamp.h"




@implementation NSDate (Timestamp)
+ (NSString *)timestamp {
    long long timeinterval = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
    return [NSString stringWithFormat:@"%lld", timeinterval];
}






+ (NSString *)customeTimestampForVideoPath {
    
    //获取三位随机数
//    NSString *(^getRandomNumber)(void) = ^(){
//        int ramdom =  arc4random() % 1000;
//        return [NSString stringWithFormat:@"%d", ramdom];
//    };
    
    
    //设置时间格式
    
    
    /*
     
     G:      公元时代，例如AD公元
     yy:     年的后2位
     yyyy:   完整年
     MM:     月，显示为1-12,带前置0
     MMM:    月，显示为英文月份简写,如 Jan
     MMMM:   月，显示为英文月份全称，如 Janualy
     dd:     日，2位数表示，如02
     d:      日，1-2位显示，如2，无前置0
     EEE:    简写星期几，如Sun
     EEEE:   全写星期几，如Sunday
     aa:     上下午，AM/PM
     H:      时，24小时制，0-23
     HH:     时，24小时制，带前置0
     h:      时，12小时制，无前置0
     hh:     时，12小时制，带前置0
     m:      分，1-2位
     mm:     分，2位，带前置0
     s:      秒，1-2位
     ss:     秒，2位，带前置0
     S:      毫秒
     Z：      GMT（时区）
     
     */
    
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *timestring = [dateFormatter stringFromDate:date];
    
    /*
     检测异常，再某些手机上出现了异常的格式化数据
     */
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES%@", @"^\\d+( AM| PM){1}$"];
    NSAssert(![predicate evaluateWithObject:timestring], @"格式化时间出现异常!");

    
    //0000表示iPhone
    NSString *result = [@"0000" stringByAppendingString:timestring];
    
    return result;
    
    
    
    
    
    
//    long long timeinterval = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
//    return [NSString stringWithFormat:@"%lld", timeinterval];
}




@end
