//
//  motionManager.h
//  securityCamera
//
//  Created by mac on 2019/5/25.
//  Copyright © 2019 tdy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol motionManagerDeviceOrientationDelegate<NSObject>

- (void)motionManagerDeviceOrientation:(UIDeviceOrientation)deviceOrientation;

@end
@interface motionManager : NSObject
@property (nonatomic ,assign) UIDeviceOrientation deviceOrientation;
@property (nonatomic ,assign) AVCaptureVideoOrientation videoOrientation;
@property (nonatomic ,weak) id<motionManagerDeviceOrientationDelegate>delegate;

+ (instancetype)sharedManager;

/**
 开始方向监测
 */
- (void)startDeviceMotionUpdates;

/**
 结束方向监测
 */
- (void)stopDeviceMotionUpdates;

/**
 设置设备取向
 @return 返回视频捕捉方向
 */
- (AVCaptureVideoOrientation)currentVideoOrientation;

@end

NS_ASSUME_NONNULL_END
