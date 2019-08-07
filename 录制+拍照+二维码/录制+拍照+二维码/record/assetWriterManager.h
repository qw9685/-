//
//  assetWriterModel.h
//  视频录制相关
//
//  Created by 崔畅－MacMini1 on 2018/3/1.
//  Copyright © 2018年 tdy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol assetWriterDelegate <NSObject>

//录制进度
- (void)recordProgress:(CGFloat)progress;

@end

typedef NS_ENUM(NSInteger, RecordFlashState) {
    RecordFlashState_Close = 0,
    RecordFlashState_Open,
    RecordFlashState_Auto,
};

typedef NS_ENUM(NSInteger, RecordCameraPosition) {
    RecordCameraPosition_Unspecifie= 0,
    RecordCameraPosition_Back,
    RecordCameraPosition_Front,
};


typedef NS_ENUM(NSInteger, RecordVideoOrientation) {
    RecordVideoOrientation_Portrait = 0,
    RecordVideoOrientation_Left,
    RecordVideoOrientation_Right,
};

typedef NS_ENUM(NSInteger, RecordResolution)
{
    RecordResolution_640x480 = 0,
    RecordResolution_1280x720,
    RecordResolution_1920x1080,
};

@interface assetWriterManager : NSObject

@property (nonatomic, weak) id<assetWriterDelegate>delegate;

@property(nonatomic,copy) void(^recordRrrorBlock)(NSString* error);//错误回调
@property(nonatomic,copy) void(^QRCodeSuccessBlock)(NSString* result);//w二维码扫描

@property(nonatomic,strong) NSString *recordPath;
@property(nonatomic,strong) NSString *photoPath;

@property (atomic, strong) NSString *videoPath;//视频输出路径
@property (atomic, assign) NSInteger videoHeight;//视频分辨的宽
@property (atomic, assign) NSInteger videoWeight;//视频分辨的高
@property (atomic, assign) NSInteger frameRate;//视频帧率
@property (atomic, assign) NSInteger videoRate;//视频码率
@property (atomic, assign) int channels;//音频通道
@property (atomic, assign) Float64 samplerate;//音频采样率
@property (atomic, assign) Float64 audioBitRate;//音频比特率

@property (atomic, assign, readonly) BOOL isCapturing;//正在录制
@property (atomic, assign, readonly) CGFloat currentRecordTime;//当前录制时间

@property (nonatomic, assign) RecordVideoOrientation videoOrientation;//设置录制方向
@property (nonatomic, assign,readonly) RecordFlashState FlashState;//闪光灯状态
@property (nonatomic, assign,readonly) RecordCameraPosition cameraPosition;//摄像头方向
@property (nonatomic, assign,readonly) RecordResolution resolutionType;//分辨率

@property(nonatomic,assign) BOOL isQrCodeType;//是否是二维码扫描模式

+ (instancetype)initCamera;//初始化
- (void)setPreviewView:(UIView *)previewView frame:(CGRect)frame;// 设置/切换预览图层
- (void)sessionLayerRunning;//开始连接
- (void)sessionLayerStop;//暂停连接

- (void)startCapture;//开始录制
- (void)stopCaptureHandler:(void (^)(BOOL success))handler;//停止录制

- (void)takePhoto:(void(^)(UIImage *image))callback;//拍照

- (void)setFlashState:(RecordFlashState)flashState handler:(void (^)(BOOL success))handler;//闪光灯
- (void)setCameraResolution:(RecordResolution)type handle:(void(^)(BOOL success))handle;//分辨率设置
- (void)setCameraPosition:(RecordCameraPosition)position handler:(void (^)(BOOL success))handler;//切换摄像头
- (void)setFocusCursorWithPoint:(CGPoint)point;//聚焦点
- (void)setVideoScaleAndCropFactor:(float)scale;//设置焦距
- (void)setcameraBackgroundDidChangeISO:(CGFloat)iso;// 调节ISO，光感度 0.0-1.0

- (void)addAnimation;//添加二维码动画
@end
