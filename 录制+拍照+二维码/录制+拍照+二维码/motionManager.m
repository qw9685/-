//
//  motionManager.m
//  securityCamera
//
//  Created by mac on 2019/5/25.
//  Copyright © 2019 tdy. All rights reserved.
//

#import "motionManager.h"
#import <CoreMotion/CoreMotion.h>
#define MOTION_UPDATE_INTERVAL 1/15.0

@interface motionManager()

@property (nonatomic ,strong) CMMotionManager *motionManager;

@end

@implementation motionManager

+ (instancetype)sharedManager{
    static motionManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[motionManager alloc]init];
    });
    return manager;
}
- (instancetype)init{
    self = [super init];
    if (self) {
        [self motionManager];
    }
    return self;
}
- (CMMotionManager *)motionManager{
    if (!_motionManager) {
        _motionManager = [[CMMotionManager alloc]init];
        _motionManager.deviceMotionUpdateInterval = MOTION_UPDATE_INTERVAL;
    }
    return _motionManager;
}
// 开始
- (void)startDeviceMotionUpdates{
    if (_motionManager.deviceMotionAvailable) {
        [_motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
            [self performSelectorOnMainThread:@selector(handleDeviceMotion:) withObject:motion waitUntilDone:YES];
        }];
    }
}
// 结束
- (void)stopDeviceMotionUpdates{
    [_motionManager stopDeviceMotionUpdates];
}
- (void)handleDeviceMotion:(CMDeviceMotion *)deviceMotion{
    double x = deviceMotion.gravity.x;
    double y = deviceMotion.gravity.y;
    if (fabs(y) >= fabs(x))
    {
        if (y >= 0){
            _deviceOrientation = UIDeviceOrientationPortraitUpsideDown;
            _videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
        }
        else{
            _deviceOrientation = UIDeviceOrientationPortrait;
            _videoOrientation = AVCaptureVideoOrientationPortrait;
        }
    }
    else{
        if (x >= 0){
            _deviceOrientation = UIDeviceOrientationLandscapeRight;
            _videoOrientation = AVCaptureVideoOrientationLandscapeRight;
        }
        else{
            _deviceOrientation = UIDeviceOrientationLandscapeLeft;
            _videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
        }
    }
    ;
    if (_delegate && [_delegate respondsToSelector:@selector(motionManagerDeviceOrientation:)]) {
        [_delegate motionManagerDeviceOrientation:_deviceOrientation];
    }
}
// 调整设备取向
- (AVCaptureVideoOrientation)currentVideoOrientation{
    AVCaptureVideoOrientation orientation;
    switch ([motionManager sharedManager].deviceOrientation) {
        case UIDeviceOrientationPortrait:
            orientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationLandscapeRight:
            orientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            orientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        default:
            orientation = AVCaptureVideoOrientationLandscapeRight;
            break;
    }
    return orientation;
}
- (void)dealloc{
    NSLog(@"%s",__func__);
}

@end
