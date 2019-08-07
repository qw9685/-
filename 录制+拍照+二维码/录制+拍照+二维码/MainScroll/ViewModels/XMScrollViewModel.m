
//
//  XMScrollViewModel.m
//
//
//  Created by foxdingding on 2018/11/23.
//

#import "XMScrollViewModel.h"
#import <CoreMotion/CoreMotion.h>
#import "motionManager.h"
#import <ReactiveObjC/ReactiveObjC.h>

//视频拍摄路径
#define K_videoPath [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingString:@"/1.mp4"]
//图片拍摄路径
#define K_photoPath [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingString:@"/1.JPG"]

#define appDelegate ((AppDelegate *)[[UIApplication sharedApplication] delegate])

@interface XMScrollViewModel ()<motionManagerDeviceOrientationDelegate>

@property(nonatomic,strong) UIView *view;
@property(nonatomic,strong) NSDictionary* locationDic;

@end

@implementation XMScrollViewModel

-(instancetype)init{
    if (self = [super init]) {
        [self initViewModel];
    }
    return self;
}

-(void)initViewModel{
    
    self.scrollModel = [[XMScrollModel alloc] init];
    self.scrollModel.cameraNames = @[@"普通",@"视频",@"二维码"];
    
    [self setCurrentPage:0];
    [self startMotionManager];//开始检测设备旋转方向
}

- (void)initCameraWithView:(UIView*)view frame:(CGRect)frame{
    _view = view;
    self.recordManager = [[recordManager alloc] init];
    [self.recordManager initCameraManagerWithView:view frame:frame VideoPath:K_videoPath photoPath:K_photoPath];
}

- (void)qrCodeJumpWithResult:(NSString*)result{
    
    [self sessionLayerStop];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self sessionLayerRunning];
        
        
    });
}

//开始录制
-(void)recordAction{
    
    self.scrollModel.takeTime = [self getNowTimeTimestamp3];//时间戳
    
    if (self.scrollModel.cameraType == cameraType_record) {
        if (self.recordManager.assetManager.isCapturing) {
            //停止
            [self.recordManager.assetManager stopCaptureHandler:^(BOOL success) {
                if (self.recordActionBlock) {
                    self.recordActionBlock(NO,success);
                }
            }];
        }else{
            //录像
            [self.recordManager.assetManager startCapture];
            if (self.recordActionBlock) {
                self.recordActionBlock(YES,YES);
            }
        }
    }else{
        
        //拍照
        [self.recordManager.assetManager takePhoto:^(UIImage *image) {
            if (self.recordActionBlock) {
                self.recordActionBlock(NO,image != nil);
            }
            [self sessionLayerStop];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self sessionLayerRunning];
            });
        }];

    }
}

- (void)recordDone{
}

- (NSString *)getNowTimeTimestamp3{
    
    NSTimeInterval time = (long)([[NSDate date] timeIntervalSince1970]*1000);
    // *1000 是精确到毫秒(13位),不乘就是精确到秒(10位)
    NSString *timeString = [NSString stringWithFormat:@"%.0f", time];
    return timeString;
}
- (NSString*)changeRecordTimeWithTime:(CGFloat)time{
    
    return [self getMMSSFromSS:[NSString stringWithFormat:@"%0.0f",time]];
}

- (NSString *)getMMSSFromSS:(NSString *)totalTime{
    
    NSInteger seconds = [totalTime integerValue];
    //format of hour
    NSString *str_hour = [NSString stringWithFormat:@"%02ld",seconds/3600];
    //format of minute
    NSString *str_minute = [NSString stringWithFormat:@"%02ld",(seconds%3600)/60];
    //format of second
    NSString *str_second = [NSString stringWithFormat:@"%02ld",seconds%60];
    //format of time
    NSString *format_time = [NSString stringWithFormat:@"%@:%@:%@",str_hour,str_minute,str_second]; return format_time;
}


//检测横竖屏
- (void)startMotionManager{
    [motionManager sharedManager].delegate = self;
    [[motionManager sharedManager] startDeviceMotionUpdates];
}


#pragma mark -------------- motionManagerDeviceOrientationDelegate --------------
- (void)motionManagerDeviceOrientation:(UIDeviceOrientation)deviceOrientation{
    
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            self.recordManager.assetManager.videoOrientation = 0;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            self.recordManager.assetManager.videoOrientation = 0;
            break;
        case UIDeviceOrientationLandscapeLeft:
            self.recordManager.assetManager.videoOrientation = 1;
            break;
        case UIDeviceOrientationLandscapeRight:
            self.recordManager.assetManager.videoOrientation = 2;
            break;
        default:
            break;
    }

    if (self.orientationBlock) {
        self.orientationBlock(deviceOrientation);
    }
}

- (void)sessionLayerRunning{
    [self.recordManager.assetManager sessionLayerRunning];
}

- (void)sessionLayerStop{
    [self.recordManager.assetManager sessionLayerStop];
}

#pragma mark -------------- set&get --------------
-(void)setCurrentPage:(NSInteger)currentPage{
    _currentPage = currentPage;
    self.scrollModel.cameraType = currentPage;
    
    self.recordManager.assetManager.isQrCodeType = self.scrollModel.cameraType == cameraType_qrCode;
    
    [self sessionLayerStop];
    
    if (self.scrollModel.cameraType == cameraType_record) {
        self.scrollModel.resourcePath = K_videoPath;
    }else{
        self.scrollModel.resourcePath = K_photoPath;
    }
    
    [self sessionLayerRunning];
}

@end



