//
//  TreefintechVideoManager.m
//  treefintechBlue
//
//  Created by Ericydong on 2019/11/6.
//  Copyright © 2019 dashu. All rights reserved.
//

#import "TreefintechVideoManager.h"
//#import <BaiduBCEBOS/BaiduBCEBOS.h>
//#import <BaiduBCEBasic/BaiduBCEBasic.h>
#import <AVKit/AVKit.h>

//#import "TreefintechNetManager.h"
#import "NSDate+Timestamp.h"
#import "AvdioManager.h"
#import <objc/runtime.h>
#import "UIWindow+Expand.h"
#import <ReactiveObjC.h>
//#import "VideoToImage.h"
//#import "NSObject+Swizzle.h"




@interface TreefintechVideoManagerError : NSError
@end

@implementation TreefintechVideoManagerError
- (NSString *)description {
#if DEBUG
    return [NSString stringWithFormat:@"%@", self.userInfo[NSDebugDescriptionErrorKey]];
#else
    return [super description];
#endif
}


@end




@interface RPSystemBroadcastPickerView (FindButton)
@end

@implementation RPSystemBroadcastPickerView (FindButton)


NSArray<NSString *> *getAllProperties(Class class) {
    unsigned int number;
    Ivar *ivars = class_copyIvarList([class class], &number);
    
    NSMutableArray<NSString *> *properties = @[].mutableCopy;
    for (unsigned int i = 0; i < number; i++) {
        const char *propertyName = ivar_getName(ivars[i]);
        [properties addObject:[NSString stringWithUTF8String:propertyName]];
        
//        NSLog(@"属性名称----%@",[NSString stringWithUTF8String:propertyName]);
    }
    return (NSArray<NSString *> *)properties;
}
NSArray<NSString *> *getAllMethods(Class class) {
    unsigned int count;
    Method *methods = class_copyMethodList([class class], &count);
    NSMutableArray<NSString *> *_methods = @[].mutableCopy;
    for (int i = 0; i < count; i++)
    {
        Method method = methods[i];
        SEL selector = method_getName(method);
        NSString *name = NSStringFromSelector(selector);
        [_methods addObject:name];

    }
    return (NSArray<NSString *> *)_methods;
}




static UIViewController *rpBroadcastPickerStandaloneViewController;
void (*ori_presentViewController_animated_completion)(id, SEL, UIViewController *, BOOL, void(^)(void));
void ds_presentViewController_animated_completion(UIViewController *self, SEL sel, UIViewController *presentedViewController, BOOL flag, void(^__nullable completion)(void)) {
    NSString *classNameOfCoutroller = NSStringFromClass([presentedViewController class]);
    //将这些控制器的modalPresentationStyle设置为全屏
    NSArray<NSString *> *fullScreen = @[/*@"DSCameraViewController", @"TreefintechCameraHolderViewController",*/ @"RPBroadcastPickerStandaloneViewController"];
    
    if ([fullScreen indexOfObject:classNameOfCoutroller] != NSNotFound) {
        presentedViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    if ([classNameOfCoutroller isEqualToString:@"RPBroadcastPickerStandaloneViewController"]) {
        
//        NSLog(@"methods == %@", getAllMethods(presentedViewController.view.class));
        
        
//        NSLog(@"properies == %@", getAllProperties(presentedViewController.view.class));
        
        
        
        rpBroadcastPickerStandaloneViewController = presentedViewController;
        
    }

    if (ori_presentViewController_animated_completion) {
        ori_presentViewController_animated_completion(self, sel, presentedViewController, flag, completion);
    }
}


+ (void)load {
    
    Class uiviewcontroller = [UIViewController class];
    Method ori_method = class_getInstanceMethod(uiviewcontroller, @selector(presentViewController:animated:completion:));
    ori_presentViewController_animated_completion = (void(*)(id, SEL, id, BOOL, void(^)(void)))method_setImplementation(ori_method, (IMP)ds_presentViewController_animated_completion);
    
}



- (UIButton *)findButton {
    UIView *view = (UIView *)self;
    return [self findButton:view];
}


- (UIButton *)findButton:(UIView *)view {
    if ([view isKindOfClass:[UIButton class]]) {
        return (UIButton *)view;
    }
    if (!view.subviews.count) {
        return nil;
    }
    UIButton *btn = nil;
    for (UIView *subview in view.subviews) {
        btn =  [self findButton:subview];
        if (btn) {
            break;
        }
    }
    return btn;
}
@end






@interface TreefintechVideoManager ()<AVPlayerViewControllerDelegate>
//@property (strong, nonatomic) BOSClient *client;
@property (copy, nonatomic) NSDictionary *cacheMd5;

@property (copy, nonatomic) void(^resultBlock)(NSError *);
@property (copy, nonatomic) void(^recordResult)(NSInteger status);

@property (strong, nonatomic) NSDictionary<NSString*, NSString *> *config;

@end


//#pragma  需要进行替换
//NSString * const accessKeyForBaidu = @"f5486461e8364bc49d0a05f92abc3219";
//NSString * const accessSecretForbaidu = @"a8d7b01a1621479bae997b9843b1bc8c";



//#import <ReactiveObjC.h>
//#import "TreefintechAppGroupManager.h"
//#import <MediaPlayer/MediaPlayer.h>

#import "VideoToImage.h"


static NSString * const accessIDKey = @"accessKeyId";
static NSString * const accessKeyKey = @"accessKeySecret";
static NSString * const accessTokenKey = @"securityToken";
static NSString * const accessExpireKey = @"expiredTime";
static NSString * const accessEndPointKey = @"endPoint";
static NSString * const accessBucketnameKey = @"bucket";



@interface TreefintechVideoManager ()
@property (strong, nonatomic) RPSystemBroadcastPickerView *broadcastPickview NS_AVAILABLE_IOS(12.0);


//@property (strong, nonatomic) UISlider *volumeView;

@end

@implementation TreefintechVideoManager

- (RPSystemBroadcastPickerView *)broadcastPickview {
    if (!_broadcastPickview) {
        RPSystemBroadcastPickerView *pickView = [[RPSystemBroadcastPickerView alloc] initWithFrame:CGRectZero];
        pickView.showsMicrophoneButton = false;
        if (@available(iOS 12.2, *)) {
            pickView.preferredExtension = @"treefintech.RecordScreenDemo.upload";
        }
        _broadcastPickview = pickView;

    }
    return _broadcastPickview;
    
}
+ (RPSystemBroadcastPickerView *)showToSuperView:(UIView *)superView result:(void(^)(NSInteger))result NS_AVAILABLE_IOS(12.0) {
    NSAssert(superView, @"superView不能为空!");
//    static RPSystemBroadcastPickerView *_broadcastPickview = nil;
    //保存回调
    
    TreefintechVideoManager *manager = [self sharedVideoManager];
    manager.recordResult = result;
    RPSystemBroadcastPickerView *pickView = manager.broadcastPickview;
    
    
//    NSLog(@"properties == %@", getAllProperties([pickView class]));
//
//     NSLog(@"methods == %@", getAllMethods([pickView class]));
    
    
    
    if (![pickView.superview isEqual:superView]) {
        NSLog(@"添加");
         [superView addSubview:pickView];
    } else {
        NSLog(@"不添加");
    }
   UIButton *btn = [pickView findButton];
    
    if (btn) {
        [btn sendActionsForControlEvents:UIControlEventAllEvents];
    }
    return pickView;
}
+ (void)finishRecording:(NSInteger)finishStatus NS_AVAILABLE_IOS(12.0) {
    NSLog(@"rpBroadcastPickerStandaloneViewController == %@", rpBroadcastPickerStandaloneViewController);
    dispatch_async(dispatch_get_main_queue(), ^{
        [rpBroadcastPickerStandaloneViewController dismissViewControllerAnimated:true completion:^{
            NSLog(@"视图dismiss掉");
        }];
    });
    
    
    TreefintechVideoManager *manager = [TreefintechVideoManager sharedVideoManager];
    [manager.broadcastPickview removeFromSuperview];
    manager.broadcastPickview = nil;
    
    
//    NSURL *pathURL = [self VideoURLPathAtDefaultPath];
//    if (pathURL && pathURL.path) {
//        [self calculateFileMd5WithFilePath:pathURL.path completion:^(NSString * _Nonnull fileMD5) {
//
//
//        }];
//    }
    if (manager.recordResult) {
        //0是正常，1是超时
        manager.recordResult(finishStatus);
    }
}

//- (UISlider *)volumeView {
//    if (!_volumeView) {
//        MPVolumeView *volumeView = [[MPVolumeView alloc] init];
//        for (UIView *view in [volumeView subviews]){
//            if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
//                _volumeView = (UISlider *)view;
//                break;
//            }
//        }
//    }
//    return _volumeView;
//}

+ (TreefintechVideoManager *)sharedVideoManager {
    static dispatch_once_t onceToken;
    static TreefintechVideoManager *manager;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
//        manager.volumeView.value = 0.1;
    });
    return manager;
}



//+ (void)uploadVideoByDefaultFilePathWithProgress:(void(^)(float))progress result:(void(^)(NSError *error))result {
//    NSURL *oriurl = [self VideoURLPathAtDefaultPath];
//    if (!oriurl || !oriurl.path) {
//        result([TreefintechVideoManagerError errorWithDomain:@"没有可用资源" code:9995 userInfo:@{NSDebugDescriptionErrorKey : @"没有可用资源"}]);
//        return;
//    }
////    [self uploadVideoByDivideIntoPatrsWithFileUrl:oriurl progress:progress result:result];
//    [self uploadVideoWithFileUrl:oriurl progress:progress result:result];
//}









+ (NSURL *)VideoURLPathAtDefaultPath {
    NSArray <NSURL *> *urls =  [[ReplayFileUtil fetchAllReplays] sortedArrayUsingComparator:^NSComparisonResult(NSURL *_Nonnull obj1, NSURL  *_Nonnull obj2) {
           return [obj1.path compare:obj2.path options:(NSCaseInsensitiveSearch)] == NSOrderedAscending;
       }];
       
       return urls.firstObject;
}

+ (void)scanVideoWithURL:(NSURL * _Nullable)videoURL result:(void(^_Nullable)(BOOL videoSourceAvailable))result {
    UIViewController *currentViewController = [[UIWindow getWindow] visibleViewController];
    NSAssert(currentViewController, @"当前控制器为空");
    NSURL *oriurl = videoURL;
    if (!oriurl || !oriurl.path) {
        oriurl = [self VideoURLPathAtDefaultPath];
    }
    if (!oriurl) {
        if (result) {
            result(false);
        } else {
            UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"提示" message:@"没有可用的资源文件" preferredStyle:(UIAlertControllerStyleAlert)];
            [controller addAction:({
                UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                    
                }];
                action;
                
            })];
            
            [currentViewController presentViewController:controller animated:true completion:^{
                
            }];
            
        }
        return;
    }
    
    /*
     懒
     */
    

     
    
    
    
    

    static UIWindow *window;
    static AVPlayerViewController *playerViewController;
    static NSMutableDictionary<NSURL *, AVPlayer *> *cacheVideoPlayer ;
    
    if (!window) {
        window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        window.backgroundColor = [UIColor clearColor];
        window.windowLevel = UIWindowLevelAlert;
        
        UIViewController *rootViewController = [[UIViewController alloc] init];
        rootViewController.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.45f];
        window.rootViewController = rootViewController;
        
        
        playerViewController = [[AVPlayerViewController alloc] init];
        playerViewController.allowsPictureInPicturePlayback = false;
        AVPlayer *player = [AVPlayer playerWithURL:oriurl];
        playerViewController.player = player;
        cacheVideoPlayer = @{oriurl : player}.mutableCopy;
        playerViewController.delegate = [self sharedVideoManager];
        
        
        
        CGFloat SCREEN_WIDTH = [UIScreen mainScreen].bounds.size.width;
        CGFloat SCREEN_HEIGHT = [UIScreen mainScreen].bounds.size.height;
        CGFloat left = 30.0;
        CGFloat width = SCREEN_WIDTH - left * 2;
        CGFloat height = width * SCREEN_HEIGHT * 1.0 / SCREEN_WIDTH;
        CGFloat top = (SCREEN_HEIGHT - height) / 2.0;
        
//#if DEBUG
//
//        AVURLAsset  *asset = [AVURLAsset assetWithURL:oriurl];
//        NSArray<AVAssetTrack *> *tracks = asset.tracks;
//        CGSize videoSize = CGSizeZero;
//        for (AVAssetTrack *track in tracks) {
//            if ([track.mediaType isEqualToString:AVMediaTypeVideo]) {
//                videoSize = track.naturalSize;
//            }
//        }
//
//#endif
        
        

//        [[playerViewController.player rac_valuesForKeyPath:@"status" observer:[self sharedVideoManager]] subscribeNext:^(id  _Nullable x) {
//            AVPlayerStatus playerStatus = (AVPlayerStatus)[x integerValue];
//            if (playerStatus == AVPlayerStatusReadyToPlay) {
////                [maskView removeFromSuperview];
//                //            [playerViewController.player play];
//            }
//        }];
        
        
        
    
       
        
        CGFloat widthForBtn = 25.0f;
        UIView *contentView = rootViewController.view;
        playerViewController.view.frame = (CGRect){left, top, width, height};
        playerViewController.view.layer.cornerRadius = 10.0f;
        playerViewController.view.layer.masksToBounds = true;
        [contentView addSubview:playerViewController.view];
        [rootViewController addChildViewController:playerViewController];
        
        UIButton *btn = [[UIButton alloc] initWithFrame:(CGRect){width + left - 3, top - widthForBtn + 3, widthForBtn, widthForBtn}];
        [btn setBackgroundImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
        [contentView addSubview:btn];
        [[btn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
            window.hidden = true;
            [playerViewController.player pause];
        }];
        
        
        
        window.hidden = false;
    } else {
        AVPlayer *player = cacheVideoPlayer[oriurl];
        if (!player) {
            player = [AVPlayer playerWithURL:oriurl];
            cacheVideoPlayer[oriurl] = player;
        }
//        [player seekToTime:(kCMTimeZero)];
        playerViewController.player = player;
        window.hidden = false;
    }

    
    

    
    CGFloat SCREEN_HEIGHT = [UIScreen mainScreen].bounds.size.height;
    
    playerViewController.view.transform = CGAffineTransformTranslate(playerViewController.view.transform, 0, SCREEN_HEIGHT);
    [UIView animateWithDuration:0.45f animations:^{
        playerViewController.view.transform = CGAffineTransformIdentity;
    }];
    
    



    if (result) {
        result(true);
    }
    
//    AVAsset *asset = [AVAsset assetWithURL:oriurl];
//    BOOL isPlayable = [asset isPlayable];
//    DSLog(@"视频资源%@播放", isPlayable ? @"可以" : @"不可以");
//    if (result) {
//        result(isPlayable ? true : false);
//        if (!isPlayable) {
//            return;
//        }
//    }

    

}

//+ (void)scanLocalVideoWithResult:(void(^)(BOOL isExist))result {
//    [self scanLocalVideoWithVideoURL:nil result:result];
//}
- (void)playerViewController:(AVPlayerViewController *)playerViewController failedToStartPictureInPictureWithError:(NSError *)error {
    
    NSLog(@"本地视频播放异常:%@", error);
}
- (void)playerViewController:(AVPlayerViewController *)playerViewController willEndFullScreenPresentationWithAnimationCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator API_AVAILABLE(ios(12.0)) {
    
    
    
}

//获取视频长度
+ (NSInteger)videoDuration {
    
    NSURL *fileURL = [self VideoURLPathAtDefaultPath];
    if (!fileURL || !fileURL.path) {
        return 0;
    }
    
    AVURLAsset *avUrl = [AVURLAsset assetWithURL:fileURL];
    CMTime time = [avUrl duration];
    NSInteger seconds = ceil(time.value/time.timescale);
    return seconds;
}












/// 压缩视频
/// @param oriurl 原始视频路径
/// @param toFileUrl 新视频保存路径
/// @param result 结果回调
+ (void)compressVideo:(NSURL *)oriurl toFileUrl:(NSURL *)toFileUrl result:(void(^)(BOOL success))result {
    AVAsset *asset = [AVAsset assetWithURL:oriurl];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPreset960x540];
    NSFileManager *fileManager = [NSFileManager defaultManager];
#if DEBUG
    unsigned long long fileSizeByM = [fileManager attributesOfItemAtPath:oriurl.path error:nil].fileSize * 1.0 / 1024 / 1024;
    NSLog(@"before fileSizeByM == %llu", fileSizeByM);
#endif
    
    NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,  NSUserDomainMask, true).firstObject;
    document = [document stringByAppendingPathComponent:[NSDate timestamp]];
    if (![fileManager fileExistsAtPath:document]) {
        [fileManager createDirectoryAtPath:document withIntermediateDirectories:true attributes:@{} error:nil];
    }
//
//    NSString *timestamp = [[NSDate timestamp] stringByAppendingPathExtension:@"mp4"];
//    NSString *filePath = [document stringByAppendingPathComponent:timestamp];
    

    NSString *filePath = toFileUrl.path;
    exportSession.outputURL= [NSURL fileURLWithPath:filePath];
    exportSession.shouldOptimizeForNetworkUse = YES;
    exportSession.outputFileType = AVFileTypeMPEG4;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        if (result) {
            result(exportSession.status == AVAssetExportSessionStatusCompleted);
        }
        switch([exportSession status]) {
            case AVAssetExportSessionStatusFailed:
                NSLog(@"Export canceled");
                break;
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"Export canceled");
                break;
            case AVAssetExportSessionStatusCompleted:{
                unsigned long long fileSizeByM = [fileManager attributesOfItemAtPath:filePath error:nil].fileSize * 1.0 / 1024 / 1024;
                NSLog(@"after fileSizeByM == %llu", fileSizeByM);
#if DEBUG
                [VideoToImage imageForFirstFrameWithVideo:[NSURL fileURLWithPath:filePath] result:^(UIImage * _Nonnull image) {
                    NSString *imagePath = [document stringByAppendingPathComponent:[[NSDate timestamp] stringByAppendingPathExtension:@"jpg"]];
                    [UIImagePNGRepresentation(image) writeToFile:imagePath atomically:true];
                }];
#endif
                
                NSLog(@"Successful!");
                break;
            }
            default:break;
                
        }
    }];
}


/**
 设置水印及其对应视频的位置

 @param composition 视频的结构
 @param size 视频的尺寸
 */
+ (void)applyVideoEffectsToComposition:(AVMutableVideoComposition *)composition size:(CGSize)size
{
    // 文字
    CATextLayer *subtitle1Text = [[CATextLayer alloc] init];
    //    [subtitle1Text setFont:@"Helvetica-Bold"];
    
    UIFont *font = [UIFont fontWithName:@"PingFang SC" size:36.0];
    
    
    NSLog(@"[UIFont familyNames] == %@",  [UIFont familyNames]);
    
    
    [subtitle1Text setFontSize:font.pointSize];
    
    [subtitle1Text setFont:(__bridge CFTypeRef _Nullable)(font)];
    NSString *text = @"功夫贷";
    
    CGSize fontSize = [text boundingRectWithSize:(CGSize){size.width, size.height} options:(NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName : font} context:NULL].size;
    //左下角为坐标原点
    [subtitle1Text setFrame:CGRectMake(size.width - fontSize.width, 0, fontSize.width, fontSize.height)];
    [subtitle1Text setString:text];
    //    [subtitle1Text setAlignmentMode:kCAAlignmentCenter];
    [subtitle1Text setForegroundColor:[[UIColor grayColor] CGColor]];
    
    //图片
//    CALayer*picLayer = [CALayer layer];
//    picLayer.contents = (id)[UIImage imageNamed:@"videoWater2"].CGImage;
//    picLayer.frame = CGRectMake(size.width-15-87, 15, 87, 26);
    
    
    
    
    
    // 2 - The usual overlay
    CALayer *overlayLayer = [CALayer layer];
    [overlayLayer addSublayer:subtitle1Text];
    overlayLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [overlayLayer setMasksToBounds:YES];
    
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
    videoLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:overlayLayer];
    
    composition.animationTool = [AVVideoCompositionCoreAnimationTool
                                 videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
}


//+ (void)saveVideoToAlbumWithFileURL:(NSURL *)fileURL result:(void(^)(NSError *error))result {
//    if ((!fileURL || !fileURL.path )&& result) {
//        result([TreefintechVideoManagerError errorWithDomain:@"存储异常" code:9998 userInfo:@{NSDebugDescriptionErrorKey : @"无可用资源或者当前资源部可用"}]);
//        return;
//    }
//    
//    
//    TreefintechVideoManager *manager = [TreefintechVideoManager sharedVideoManager];
//    manager.resultBlock = result;
//    
//    
//    
//    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(fileURL.path)) {
//        UISaveVideoAtPathToSavedPhotosAlbum(fileURL.path, manager, @selector(video:didFinishSavingWithError:contextInfo:), NULL);
//    } else {
//        if (result) {
//            result([TreefintechVideoManagerError errorWithDomain:@"存储异常" code:9999 userInfo:@{NSDebugDescriptionErrorKey : @"无可用资源或者当前资源部可用"}]);
//        }
//        
//    }
//}
//
//- (void)video:(NSString*)videoPath didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo {
//    if (self.resultBlock) {
//        if (error){
//            self.resultBlock(error);
//        } else {
//            self.resultBlock(nil);
//        }
//    }
//}

/// 尝试使用分块上传
/// @param fileUrl 资源路径
/// @param progress 进度回调
/// @param result 结果回调
//+ (void)uploadVideoByDivideIntoPatrsWithFileUrl:(NSURL *)fileUrl progress:(void(^)(float))progress result:(void(^)(NSError *error))result {
//    [self loadTokenWithResult:^(NSDictionary *config) {
//        if (!config && result) {
//            result([NSError errorWithDomain:@"获取配置失败" code:9997 userInfo:@{NSDebugDescriptionErrorKey : @"获取百度临时授权失败!!"}]);
//            return ;
//
//        }
//
//        TreefintechVideoManager *manager = [self sharedVideoManager];
//        NSString *userId = DS_GET_DECRYPT(userIdKey);
//        NSString *lastPath = [fileUrl lastPathComponent];
//        NSString *key = [userId stringByAppendingString:lastPath];
//
//
//        NSString *bucketName = manager.config[accessBucketnameKey];
//        // 初始化分块上传
//        BOSInitiateMultipartUploadRequest* initMPRequest = [[BOSInitiateMultipartUploadRequest alloc] init];
//        initMPRequest.bucket = manager.config[accessBucketnameKey];
//        initMPRequest.key = key;
//        initMPRequest.contentType = @"video/mpeg4";
//
//        __block BOSInitiateMultipartUploadResponse* initMPResponse = nil;
//        BCETask* task = [manager.client initiateMultipartUpload:initMPRequest];
//        task.then(^(BCEOutput* output) {
//            if (output.response) {
//                initMPResponse = (BOSInitiateMultipartUploadResponse*)output.response;
//                NSLog(@"initiate multipart upload success!");
//            }
//
//            if (output.error) {
//                NSLog(@"initiate multipart upload failure");
//            }
//        });
//        [task waitUtilFinished];
//
//
//        NSString* uploadID = initMPResponse.uploadId;
//        //计算分块个数
//        NSDictionary<NSString*, id>* attr = [[NSFileManager defaultManager] attributesOfItemAtPath:fileUrl.path error:nil];
//        uint64_t fileSize = attr.fileSize;
//
//
//        uint64_t fileSizeByM = fileSize / 1024 / 1024;
//        uint64_t unitSize = 5.0;
//        if (fileSizeByM < 5.0) {
//            unitSize = 2.0;
//        }
//
//        uint64_t partSize = 1024 * 1024 * unitSize; //1M一块
//        uint64_t partCount = fileSize / partSize;
//        if (fileSize % partSize != 0) {
//            ++partCount;
//        }
//
//        NSMutableArray<BOSPart*>* parts = [NSMutableArray array];
//        NSFileHandle* handle = [NSFileHandle fileHandleForReadingAtPath:fileUrl.path];
//
//        dispatch_group_t group = dispatch_group_create();
//        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
//
//
//
//
//        for (uint64_t i = 0; i < partCount; ++i) {
//            dispatch_group_enter(group);
//            dispatch_async(queue, ^{
//                // seek
//                 uint64_t skip = partSize * i;
//                 [handle seekToFileOffset:skip];
//                 uint64_t size = (partSize < fileSize - skip) ? partSize : fileSize - skip;
//                 // data
//                 NSData* data = [handle readDataOfLength:size];
//
//                 // request
//                 BOSUploadPartRequest* uploadPartRequest = [[BOSUploadPartRequest alloc] init];
//                 uploadPartRequest.bucket = bucketName;
//                 uploadPartRequest.key = key;
//                 uploadPartRequest.objectData.data = data;
//                 uploadPartRequest.partNumber = i + 1;
//                 uploadPartRequest.uploadId = uploadID;
//
//                 __block BOSUploadPartResponse* uploadPartResponse = nil;
//                 BCETask *task = [manager.client uploadPart:uploadPartRequest];
//                 task.then(^(BCEOutput* output) {
//                     if (output.response) {
//                         uploadPartResponse = (BOSUploadPartResponse*)output.response;
//                         BOSPart* part = [[BOSPart alloc] init];
//                         part.partNumber = i + 1;
//                         part.eTag = uploadPartResponse.eTag;
//                         [parts addObject:part];
//                         dispatch_group_leave(group);
//                         dispatch_async(dispatch_get_main_queue(), ^{
//                             static NSInteger hasSentCount = 0;
//
//                             if (progress) {
//                                 NSLog(@"BBBBBBBB %llu", i);
//                                 progress(++hasSentCount * 1.0 / partCount);
//                             }
//                             if (hasSentCount == partCount) {
//                                 hasSentCount = 0;
//                             }
//
//                         });
//
//                     }
//                 });
//                 [task waitUtilFinished];
//
//            });
//        }
//
//
//        dispatch_group_notify(group, queue, ^{
//            //对块排序
//            [parts sortUsingComparator:^NSComparisonResult(BOSPart * _Nonnull obj1, BOSPart *_Nonnull obj2) {
//                return obj1.partNumber > obj2.partNumber;
//            }];
//            for (BOSPart *part in parts) {
//                NSLog(@"index == %@", @(part.partNumber));
//            }
//
//
//            BOSCompleteMultipartUploadRequest* compMultipartRequest = [[BOSCompleteMultipartUploadRequest alloc] init];
//            compMultipartRequest.bucket = bucketName;
//            compMultipartRequest.key = key;
//            compMultipartRequest.uploadId = uploadID;
//            compMultipartRequest.parts = parts;
//
//            __block BOSCompleteMultipartUploadResponse* complResponse = nil;
//            BCETask *task = [manager.client completeMultipartUpload:compMultipartRequest];
//            task.then(^(BCEOutput* output) {
//                if (output.response) {
//                    complResponse = (BOSCompleteMultipartUploadResponse*)output.response;
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        result(nil);
//                    });
//
//                    NSLog(@"complte multiparts success!");
//                }
//
//                if (output.error) {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        result(output.error);
//                    });
//
//                    NSLog(@"complte multiparts failure %@", output.error);
//                }
//            });
//            [task waitUtilFinished];
//
//
//        });
//
//
//    }];
//}
/**
 视频添加水印并保存到相册

 @param path 视频本地路径
 */
//+ (void)addWaterPicWithVideoOutput:(NSString *)output result:(void(^)(BOOL))result {
//
//
//    NSURL *oriURL = [self VideoURLPathAtDefaultPath];
//    if (!oriURL || !oriURL.path) {
//        return;
//    }
//    NSString *path = oriURL.path;
//
//
//
//
//    //1 创建AVAsset实例
//    AVURLAsset*videoAsset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:path]];
//
//    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
//
//
//    //3 视频通道
//    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
//                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
//    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
//                        ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject]
//                         atTime:kCMTimeZero error:nil];
//
//
//    //2 音频通道
////    AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
////                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
////    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
////                        ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] firstObject]
////                         atTime:kCMTimeZero error:nil];
//
//    //3.1 AVMutableVideoCompositionInstruction 视频轨道中的一个视频，可以缩放、旋转等
//    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
//    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);
//
//    // 3.2 AVMutableVideoCompositionLayerInstruction 一个视频轨道，包含了这个轨道上的所有视频素材
//    AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
//
//    [videolayerInstruction setOpacity:0.0 atTime:videoAsset.duration];
//
//    // 3.3 - Add instructions
//    mainInstruction.layerInstructions = [NSArray arrayWithObjects:videolayerInstruction,nil];
//
//    //AVMutableVideoComposition：管理所有视频轨道，水印添加就在这上面
//    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
//
//    AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
//    CGSize naturalSize = videoAssetTrack.naturalSize;
//
//    float renderWidth, renderHeight;
//    renderWidth = naturalSize.width;
//    renderHeight = naturalSize.height;
//    mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
//    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
//    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
//    [self applyVideoEffectsToComposition:mainCompositionInst size:naturalSize];
//
//    //    // 4 - 输出路径
////    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
////    NSString *documentsDirectory = [paths objectAtIndex:0];
////    NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:
////                             [NSString stringWithFormat:@"FinalVideo-%d.mp4",arc4random() % 1000]];
//    NSString *myPathDocs = output;
//    NSURL* videoUrl = [NSURL fileURLWithPath:myPathDocs];
//
//    // 5 - 视频文件输出
//    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
//                                                                      presetName:AVAssetExportPresetHighestQuality];
//    exporter.outputURL = videoUrl;
//    exporter.outputFileType = AVFileTypeMPEG4;
//    exporter.shouldOptimizeForNetworkUse = YES;
//    exporter.videoComposition = mainCompositionInst;
//    [exporter exportAsynchronouslyWithCompletionHandler:^{
//        dispatch_async(dispatch_get_main_queue(), ^{
//
//            if( exporter.status == AVAssetExportSessionStatusCompleted ){
//                if (result) {
//                    result(true);
//                }
//
//
//
//
////                UISaveVideoAtPathToSavedPhotosAlbum(myPathDocs, nil, nil, nil);
//
//            }else if( exporter.status == AVAssetExportSessionStatusFailed )
//            {
//                if (result) {
//                    result(false);
//                }
//                NSLog(@"failed");
//            }
//
//        });
//    }];
//}

@end
